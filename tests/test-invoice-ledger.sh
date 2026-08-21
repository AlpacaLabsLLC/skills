#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
SCRIPT="$PWD/skills/invoice/scripts/invoice-ledger.sh"

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
project="$root/alpha"
mkdir -p "$project"

fail() { echo "FAIL: $*"; exit 1; }
expect_die() { if "$@" >/dev/null 2>&1; then fail "expected failure: $*"; fi }

# Writers reject a symlinked project root.
real_project="$root/real-project"
linked_project="$root/linked-project"
mkdir -p "$real_project"
ln -s "$real_project" "$linked_project"
expect_die bash "$SCRIPT" init "$linked_project" "Linked" "USD" "monthly" "1000.00" "none" "user input" "2026-08-06"
[ ! -e "$real_project/INVOICES.md" ] || fail "symlinked project root created a ledger in its target"

# init with a 100k cap; refuses overwrite; validates amounts
bash "$SCRIPT" init "$project" "Alpha" "USD" "monthly" "12500.00" "100000.00" "agreement/AGREEMENT.md#terms" "2026-08-06" >/dev/null
grep -q '| Maximum Total Cost | 100000.00 |' "$project/INVOICES.md" || fail "cap setting"
expect_die bash "$SCRIPT" init "$project" "Alpha" "USD" "monthly" "12500.00" "100000.00" "x" "2026-08-06"
mkdir -p "$root/bad"
expect_die bash "$SCRIPT" init "$root/bad" "Bad" "USD" "monthly" "12,500" "none" "x" "2026-08-06"

# init renders to a validated temporary file and leaves no partial ledger on failure
mkdir -p "$root/init-retry"
expect_die env ARCH_INVOICE_FAIL_AT=init-render-failure bash "$SCRIPT" init "$root/init-retry" "Retry" "USD" "monthly" "1000.00" "none" "user input" "2026-08-06"
[ ! -e "$root/init-retry/INVOICES.md" ] || fail "failed init published a ledger"
[ -z "$(find "$root/init-retry" -maxdepth 1 -name '.invoice-ledger-init.*' -print)" ] || fail "failed init left a temporary ledger"
bash "$SCRIPT" init "$root/init-retry" "Retry" "USD" "monthly" "1000.00" "none" "user input" "2026-08-06" >/dev/null

# every free-text ledger cell rejects table, control, and AWK escape injection
mkdir -p "$root/unsafe-init"
expect_die bash "$SCRIPT" init "$root/unsafe-init" "Unsafe" $'US\tD' "monthly" "1000.00" "none" "user input" "2026-08-06"
expect_die bash "$SCRIPT" append "$project" 'INV\nINJECTED' "2026-08-15" "2026-09-14" "1.00" "0.00" "1.00" - - draft -
expect_die bash "$SCRIPT" append "$project" "INV-ESCAPE" "2026-08-15" "2026-09-14" "1.00" "0.00" "1.00" - - draft 'Corrects I0001 — bad\nrow'

# append validates the arithmetic and formats
expect_die bash "$SCRIPT" append "$project" "INV-1" "2026-08-15" "2026-09-14" "12500.00" "0.00" "13000.00" - - draft -
expect_die bash "$SCRIPT" append "$project" "INV-1" "2026-09-14" "2026-08-15" "12500.00" "0.00" "12500.00" - - draft -
expect_die bash "$SCRIPT" append "$project" "INV-1" "2026-08-15" "2026-09-14" "12500.00" "0.00" "12500.00" - - shipped -

[ "$(bash "$SCRIPT" allocate "$project")" = "I0001" ] || fail "first allocation"
bash "$SCRIPT" append "$project" "INV-1" "2026-08-15" "2026-09-14" "12500.00" "500.00" "13000.00" - - draft - >/dev/null
grep -q '| I0001 | INV-1 |' "$project/INVOICES.md" || fail "row appended"

# decimal values valid to the cent use exact cent arithmetic
mkdir -p "$root/cents"
bash "$SCRIPT" init "$root/cents" "Cents" "USD" "monthly" "0.10" "none" "user input" "2026-08-06" >/dev/null
bash "$SCRIPT" append "$root/cents" "INV-CENTS" "2026-09-15" "2026-09-15" "0.10" "0.20" "0.30" - - draft - >/dev/null
grep -q '| I0001 | INV-CENTS |.*| 0.10 | 0.20 | 0.30 |' "$root/cents/INVOICES.md" || fail "valid cent total was not appended"

# lifecycle updates status and dates, and appends history
bash "$SCRIPT" set-lifecycle "$project" I0001 sent "2026-09-15" >/dev/null
grep -q '| 2026-09-15 | - | sent |' "$project/INVOICES.md" || fail "sent lifecycle"
grep -q -- '- 2026-09-15: I0001 marked sent' "$project/INVOICES.md" || fail "history bullet"
expect_die bash "$SCRIPT" set-lifecycle "$project" I0099 paid "2026-09-15"

# lifecycle row and history changes publish together, or not at all
cp "$project/INVOICES.md" "$root/lifecycle-before.md"
expect_die env ARCH_INVOICE_FAIL_AT=lifecycle-before-history bash "$SCRIPT" set-lifecycle "$project" I0001 void "2026-09-16"
cmp -s "$project/INVOICES.md" "$root/lifecycle-before.md" || fail "failed lifecycle update changed ledger bytes"

# outstanding tracks sent-not-paid; totals accumulate
out=$(bash "$SCRIPT" status "$project")
echo "$out" | grep -q 'total=13000.00' || fail "total"
echo "$out" | grep -q 'outstanding=13000.00' || fail "outstanding"
bash "$SCRIPT" set-lifecycle "$project" I0001 paid "2026-09-30" >/dev/null
out=$(bash "$SCRIPT" status "$project")
echo "$out" | grep -q 'outstanding=0.00' || fail "outstanding after paid"

# a coverage gap between periods is reported
bash "$SCRIPT" append "$project" "INV-2" "2026-09-25" "2026-10-14" "12500.00" "0.00" "12500.00" - - draft - >/dev/null
out=$(bash "$SCRIPT" status "$project")
echo "$out" | grep -q 'coverage gap: 2026-09-14..2026-09-25' || fail "gap detection"

# contiguous period reports no new gap
bash "$SCRIPT" append "$project" "INV-3" "2026-10-15" "2026-11-14" "12500.00" "0.00" "12500.00" - - draft - >/dev/null
out=$(bash "$SCRIPT" status "$project")
[ "$(echo "$out" | grep -c 'coverage gap')" = 1 ] || fail "unexpected extra gap"

# a correction row supersedes the original in totals
bash "$SCRIPT" append "$project" "INV-3r" "2026-10-15" "2026-11-14" "10000.00" "0.00" "10000.00" - - draft "Corrects I0003 — rate flip overbilled" >/dev/null
out=$(bash "$SCRIPT" status "$project")
echo "$out" | grep -q 'total=35500.00' || fail "correction totals (13000+12500+10000)"
grep -q '| I0003 |' "$project/INVOICES.md" || fail "corrected row must remain in ledger"

# void rows drop out of totals
bash "$SCRIPT" append "$project" "INV-4" "2026-11-15" "2026-12-14" "12500.00" "0.00" "12500.00" - - draft - >/dev/null
bash "$SCRIPT" set-lifecycle "$project" I0005 void "2026-11-16" >/dev/null
out=$(bash "$SCRIPT" status "$project")
echo "$out" | grep -q 'total=35500.00' || fail "void excluded"

# cap warning fires at >= 80%
bash "$SCRIPT" append "$project" "INV-5" "2026-12-15" "2027-01-14" "44500.00" "0.00" "44500.00" - - draft - >/dev/null
out=$(bash "$SCRIPT" status "$project")
echo "$out" | grep -q 'CAP WARNING: 80.0% of Maximum Total Cost consumed' || fail "cap warning"

# no-cap ledgers report cap=none and never warn
mkdir -p "$root/uncapped"
bash "$SCRIPT" init "$root/uncapped" "U" "USD" "monthly" "1000.00" "none" "user input" "2026-08-06" >/dev/null
bash "$SCRIPT" append "$root/uncapped" "INV-1" "2026-08-01" "2026-08-31" "1000.00" "0.00" "1000.00" - - draft - >/dev/null
out=$(bash "$SCRIPT" status "$root/uncapped")
echo "$out" | grep -q 'cap=none' || fail "cap none"
! echo "$out" | grep -q 'CAP WARNING' || fail "warning without cap"

# missing or blank caps are malformed; only literal none is uncapped
for cap_case in missing blank; do
  cap_project="$root/cap-$cap_case"
  mkdir -p "$cap_project"
  bash "$SCRIPT" init "$cap_project" "Cap $cap_case" "USD" "monthly" "1000.00" "10000.00" "user input" "2026-08-06" >/dev/null
  if [ "$cap_case" = missing ]; then
    sed -i.bak '/| Maximum Total Cost |/d' "$cap_project/INVOICES.md" && rm "$cap_project/INVOICES.md.bak"
  else
    sed -i.bak 's/| Maximum Total Cost | 10000.00 |/| Maximum Total Cost |  |/' "$cap_project/INVOICES.md" && rm "$cap_project/INVOICES.md.bak"
  fi
  cp "$cap_project/INVOICES.md" "$root/cap-$cap_case-before.md"
  expect_die bash "$SCRIPT" status "$cap_project"
  expect_die bash "$SCRIPT" append "$cap_project" "INV-CAP" "2026-08-01" "2026-08-31" "1000.00" "0.00" "1000.00" - - draft -
  cmp -s "$cap_project/INVOICES.md" "$root/cap-$cap_case-before.md" || fail "$cap_case cap mutation changed malformed ledger"
done

# coverage uses the furthest covered end across nested periods
mkdir -p "$root/nested-periods"
bash "$SCRIPT" init "$root/nested-periods" "Nested" "USD" "monthly" "1000.00" "none" "user input" "2026-08-06" >/dev/null
bash "$SCRIPT" append "$root/nested-periods" "INV-N1" "2026-01-01" "2026-01-31" "1.00" "0.00" "1.00" - - draft - >/dev/null
bash "$SCRIPT" append "$root/nested-periods" "INV-N2" "2026-01-10" "2026-01-15" "1.00" "0.00" "1.00" - - draft - >/dev/null
bash "$SCRIPT" append "$root/nested-periods" "INV-N3" "2026-02-01" "2026-02-28" "1.00" "0.00" "1.00" - - draft - >/dev/null
out=$(bash "$SCRIPT" status "$root/nested-periods")
! echo "$out" | grep -q 'coverage gap' || fail "nested period created a false coverage gap"
echo "$out" | grep -q 'last period end: 2026-02-28' || fail "nested coverage reported the wrong maximum end"

# correction targets must resolve to one earlier, not-yet-corrected row
mkdir -p "$root/correction-targets"
bash "$SCRIPT" init "$root/correction-targets" "Targets" "USD" "monthly" "1000.00" "none" "user input" "2026-08-06" >/dev/null
cp "$root/correction-targets/INVOICES.md" "$root/correction-empty.md"
expect_die bash "$SCRIPT" append "$root/correction-targets" "INV-SELF" "2026-08-01" "2026-08-31" "1.00" "0.00" "1.00" - - draft "Corrects I0001 — self target"
expect_die bash "$SCRIPT" append "$root/correction-targets" "INV-MISSING" "2026-08-01" "2026-08-31" "1.00" "0.00" "1.00" - - draft "Corrects I9999 — absent target"
cmp -s "$root/correction-targets/INVOICES.md" "$root/correction-empty.md" || fail "invalid correction target changed ledger bytes"
bash "$SCRIPT" append "$root/correction-targets" "INV-T1" "2026-08-01" "2026-08-31" "10.00" "0.00" "10.00" - - draft - >/dev/null
bash "$SCRIPT" append "$root/correction-targets" "INV-T1R" "2026-08-01" "2026-08-31" "9.00" "0.00" "9.00" - - draft "Corrects I0001 — first correction" >/dev/null
cp "$root/correction-targets/INVOICES.md" "$root/correction-active.md"
expect_die bash "$SCRIPT" append "$root/correction-targets" "INV-T1R2" "2026-08-01" "2026-08-31" "8.00" "0.00" "8.00" - - draft "Corrects I0001 — duplicate correction"
cmp -s "$root/correction-targets/INVOICES.md" "$root/correction-active.md" || fail "duplicate correction changed ledger bytes"

mkdir -p "$root/duplicate-target"
bash "$SCRIPT" init "$root/duplicate-target" "Duplicate target" "USD" "monthly" "1000.00" "none" "user input" "2026-08-06" >/dev/null
bash "$SCRIPT" append "$root/duplicate-target" "INV-D1" "2026-08-01" "2026-08-31" "10.00" "0.00" "10.00" - - draft - >/dev/null
duplicate_row=$(grep '^| I0001 |' "$root/duplicate-target/INVOICES.md")
awk -v row="$duplicate_row" '/<!-- invoices:end -->/ {print row} {print}' "$root/duplicate-target/INVOICES.md" > "$root/duplicate-target.md"
mv "$root/duplicate-target.md" "$root/duplicate-target/INVOICES.md"
cp "$root/duplicate-target/INVOICES.md" "$root/duplicate-target-before.md"
expect_die bash "$SCRIPT" append "$root/duplicate-target" "INV-D1R" "2026-08-01" "2026-08-31" "9.00" "0.00" "9.00" - - draft "Corrects I0001 — ambiguous target"
cmp -s "$root/duplicate-target/INVOICES.md" "$root/duplicate-target-before.md" || fail "ambiguous correction target changed ledger bytes"

# voiding a correction restores the original row to computed totals
mkdir -p "$root/voided-correction"
bash "$SCRIPT" init "$root/voided-correction" "Correction" "USD" "monthly" "12500.00" "none" "user input" "2026-08-06" >/dev/null
bash "$SCRIPT" append "$root/voided-correction" "INV-C1" "2026-08-01" "2026-08-31" "12500.00" "0.00" "12500.00" - - draft - >/dev/null
bash "$SCRIPT" append "$root/voided-correction" "INV-C1R" "2026-08-01" "2026-08-31" "10000.00" "0.00" "10000.00" - - draft "Corrects I0001 — rate correction" >/dev/null
out=$(bash "$SCRIPT" status "$root/voided-correction")
echo "$out" | grep -q 'total=10000.00' || fail "active correction did not replace original"
bash "$SCRIPT" set-lifecycle "$root/voided-correction" I0002 void "2026-09-01" >/dev/null
out=$(bash "$SCRIPT" status "$root/voided-correction")
echo "$out" | grep -q 'total=12500.00' || fail "voiding correction did not restore original"
cp "$root/voided-correction/INVOICES.md" "$root/voided-correction-before.md"
expect_die bash "$SCRIPT" append "$root/voided-correction" "INV-C1R2" "2026-08-01" "2026-08-31" "11000.00" "0.00" "11000.00" - - draft "Corrects I0001 — second correction"
cmp -s "$root/voided-correction/INVOICES.md" "$root/voided-correction-before.md" || fail "historically corrected target changed ledger bytes"

# a missing insertion marker blocks append and preserves the ledger byte-for-byte
mkdir -p "$root/missing-marker"
bash "$SCRIPT" init "$root/missing-marker" "Missing Marker" "USD" "monthly" "1000.00" "none" "user input" "2026-08-06" >/dev/null
sed -i.bak '/<!-- invoices:end -->/d' "$root/missing-marker/INVOICES.md" && rm "$root/missing-marker/INVOICES.md.bak"
cp "$root/missing-marker/INVOICES.md" "$root/missing-marker-before.md"
expect_die bash "$SCRIPT" append "$root/missing-marker" "INV-M1" "2026-08-01" "2026-08-31" "1000.00" "0.00" "1000.00" - - draft -
cmp -s "$root/missing-marker/INVOICES.md" "$root/missing-marker-before.md" || fail "missing-marker append changed ledger bytes"

# A symlinked owned ledger is rejected and remains a symlink.
mkdir -p "$root/symlinked-ledger"
bash "$SCRIPT" init "$root/symlinked-ledger" "Symlinked Ledger" "USD" "monthly" "1000.00" "none" "user input" "2026-08-06" >/dev/null
mv "$root/symlinked-ledger/INVOICES.md" "$root/external-invoices.md"
ln -s "$root/external-invoices.md" "$root/symlinked-ledger/INVOICES.md"
expect_die bash "$SCRIPT" append "$root/symlinked-ledger" "INV-S1" "2026-08-01" "2026-08-31" "1000.00" "0.00" "1000.00" - - draft -
[ -L "$root/symlinked-ledger/INVOICES.md" ] || fail "writer replaced a symlinked ledger"

# malformed ledger blocks mutation and is preserved byte-for-byte
sed -i.bak 's/| Format version | 2 |/| Format version | 1 |/' "$project/INVOICES.md" && rm "$project/INVOICES.md.bak"
before=$(cat "$project/INVOICES.md")
expect_die bash "$SCRIPT" append "$project" "INV-6" "2027-01-15" "2027-02-14" "1.00" "0.00" "1.00" - - draft -
[ "$before" = "$(cat "$project/INVOICES.md")" ] || fail "malformed ledger was mutated"

echo "✓ invoice ledger computes totals, caps, gaps, and corrections deterministically and preserves malformed state"
