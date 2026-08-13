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

# init with a 100k cap; refuses overwrite; validates amounts
bash "$SCRIPT" init "$project" "Alpha" "USD" "monthly" "12500.00" "100000.00" "agreement/AGREEMENT.md#terms" "2026-08-06" >/dev/null
grep -q '| Maximum Total Cost | 100000.00 |' "$project/INVOICES.md" || fail "cap setting"
expect_die bash "$SCRIPT" init "$project" "Alpha" "USD" "monthly" "12500.00" "100000.00" "x" "2026-08-06"
mkdir -p "$root/bad"
expect_die bash "$SCRIPT" init "$root/bad" "Bad" "USD" "monthly" "12,500" "none" "x" "2026-08-06"

# append validates the arithmetic and formats
expect_die bash "$SCRIPT" append "$project" "INV-1" "2026-08-15" "2026-09-14" "12500.00" "0.00" "13000.00" - - draft -
expect_die bash "$SCRIPT" append "$project" "INV-1" "2026-09-14" "2026-08-15" "12500.00" "0.00" "12500.00" - - draft -
expect_die bash "$SCRIPT" append "$project" "INV-1" "2026-08-15" "2026-09-14" "12500.00" "0.00" "12500.00" - - shipped -

[ "$(bash "$SCRIPT" allocate "$project")" = "I0001" ] || fail "first allocation"
bash "$SCRIPT" append "$project" "INV-1" "2026-08-15" "2026-09-14" "12500.00" "500.00" "13000.00" - - draft - >/dev/null
grep -q '| I0001 | INV-1 |' "$project/INVOICES.md" || fail "row appended"

# lifecycle updates status and dates, and appends history
bash "$SCRIPT" set-lifecycle "$project" I0001 sent "2026-09-15" >/dev/null
grep -q '| 2026-09-15 | - | sent |' "$project/INVOICES.md" || fail "sent lifecycle"
grep -q -- '- 2026-09-15: I0001 marked sent' "$project/INVOICES.md" || fail "history bullet"
expect_die bash "$SCRIPT" set-lifecycle "$project" I0099 paid "2026-09-15"

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

# malformed ledger blocks mutation and is preserved byte-for-byte
sed -i.bak 's/| Format version | 2 |/| Format version | 1 |/' "$project/INVOICES.md" && rm "$project/INVOICES.md.bak"
before=$(cat "$project/INVOICES.md")
expect_die bash "$SCRIPT" append "$project" "INV-6" "2027-01-15" "2027-02-14" "1.00" "0.00" "1.00" - - draft -
[ "$before" = "$(cat "$project/INVOICES.md")" ] || fail "malformed ledger was mutated"

echo "✓ invoice ledger computes totals, caps, gaps, and corrections deterministically and preserves malformed state"
