#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
SCRIPT="$PWD/skills/proposal/scripts/proposal-register.sh"

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
work="$root/studio"
mkdir -p "$work"

fail() { echo "FAIL: $*"; exit 1; }
expect_die() { if "$@" >/dev/null 2>&1; then fail "expected failure: $*"; fi }

# init creates the register with prefix; refuses to overwrite
bash "$SCRIPT" init "$work" "Test Studio" "TS" >/dev/null
grep -q '| Format version | 2 |' "$work/PROPOSALS.md" || fail "init format version"
grep -q '| Proposal prefix | TS |' "$work/PROPOSALS.md" || fail "init prefix"
expect_die bash "$SCRIPT" init "$work" "Test Studio" "TS"
expect_die bash "$SCRIPT" init "$root/other-missing-dir-x" "Test Studio" "TS"

# prefix validation
mkdir -p "$root/badprefix"
expect_die bash "$SCRIPT" init "$root/badprefix" "Test Studio" "ts"
expect_die bash "$SCRIPT" init "$root/badprefix" "Test Studio" "T"
expect_die bash "$SCRIPT" init "$root/badprefix" "Test Studio" "TOOLONGX"

# allocation starts at 0001
[ "$(bash "$SCRIPT" allocate "$work")" = "TS-0001" ] || fail "first allocation"

# create scaffolds the file and registers a draft row
bash "$SCRIPT" create "$work" "projects/alpha/proposals" "alpha" "Acme Corp" "Design Services" "design-services" "2026-08-06" >/dev/null
[ -f "$work/projects/alpha/proposals/TS-0001-design-services.md" ] || fail "proposal file missing"
grep -q '| TS-0001 | alpha | Acme Corp | Design Services | 2026-08-06 | draft | projects/alpha/proposals/TS-0001-design-services.md |' "$work/PROPOSALS.md" || fail "register row"
grep -q '# TS-0001 — Design Services' "$work/projects/alpha/proposals/TS-0001-design-services.md" || fail "rendered number"

# next allocation advances
[ "$(bash "$SCRIPT" allocate "$work")" = "TS-0002" ] || fail "second allocation"

# unsafe relative dirs refused
expect_die bash "$SCRIPT" create "$work" "/abs/proposals" "alpha" "Acme" "X" "x" "2026-08-06"
expect_die bash "$SCRIPT" create "$work" "projects/../proposals" "alpha" "Acme" "X" "x" "2026-08-06"

# lifecycle transitions
bash "$SCRIPT" set-status "$work" TS-0001 sent >/dev/null
grep -q '| sent |' "$work/PROPOSALS.md" || fail "sent status"
bash "$SCRIPT" set-status "$work" TS-0001 accepted >/dev/null
grep -q '| accepted |' "$work/PROPOSALS.md" || fail "accepted status"
expect_die bash "$SCRIPT" set-status "$work" TS-0001 paid
expect_die bash "$SCRIPT" set-status "$work" TS-9999 sent

# supersede requires a distinct successor
expect_die bash "$SCRIPT" set-status "$work" TS-0001 superseded
expect_die bash "$SCRIPT" set-status "$work" TS-0001 superseded TS-0001
bash "$SCRIPT" create "$work" "projects/alpha/proposals" "alpha" "Acme Corp" "Design Services v2" "design-services-v2" "2026-08-06" >/dev/null
bash "$SCRIPT" set-status "$work" TS-0001 superseded TS-0002 >/dev/null
grep -q '| superseded by TS-0002 |' "$work/PROPOSALS.md" || fail "superseded status"

# verify passes clean, flags a deleted file, and never repairs
bash "$SCRIPT" verify "$work" >/dev/null
rm "$work/projects/alpha/proposals/TS-0002-design-services-v2.md"
if bash "$SCRIPT" verify "$work" >/dev/null 2>&1; then fail "verify missed a missing file"; fi
grep -q '| TS-0002 |' "$work/PROPOSALS.md" || fail "verify must not remove rows"

# malformed register blocks mutation and is preserved byte-for-byte
mkdir -p "$root/broken"
bash "$SCRIPT" init "$root/broken" "Broken" "BR" >/dev/null
sed -i.bak 's/| Format version | 2 |/| Format version | 1 |/' "$root/broken/PROPOSALS.md" && rm "$root/broken/PROPOSALS.md.bak"
before=$(cat "$root/broken/PROPOSALS.md")
expect_die bash "$SCRIPT" create "$root/broken" "proposals" "p" "C" "T" "t" "2026-08-06"
[ "$before" = "$(cat "$root/broken/PROPOSALS.md")" ] || fail "malformed register was mutated"

echo "✓ proposal register allocates permanent numbers, guards transitions, and preserves malformed state"
