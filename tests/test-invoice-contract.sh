#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SKILL=skills/invoice/SKILL.md
README=skills/invoice/README.md
SCRIPT=skills/invoice/scripts/invoice-ledger.sh
TEMPLATE=skills/invoice/templates/INVOICES.md

for f in "$SKILL" "$README" "$SCRIPT" "$TEMPLATE"; do
  [ -f "$f" ] || { echo "missing contract file: $f"; exit 1; }
done

grep -q '^name: invoice$' "$SKILL"

for command in init record status reconcile send void; do
  grep -q "/as:invoice $command" "$SKILL" || { echo "missing command: $command"; exit 1; }
  grep -q "/as:invoice $command" "$README" || { echo "README missing command: $command"; exit 1; }
done

# Agent-native lifecycle commands keep one confirmation gate and use the ledger helper.
grep -A8 '## `/as:invoice send' "$SKILL" | grep -q 'confirm'
grep -A8 '## `/as:invoice send' "$SKILL" | grep -q 'set-lifecycle.*sent'
grep -A8 '## `/as:invoice void' "$SKILL" | grep -q 'confirm'
grep -A8 '## `/as:invoice void' "$SKILL" | grep -q 'set-lifecycle.*void'

# The activity firewall, in timetracker language
grep -q 'Every amount comes from the agreement or the user' "$SKILL"
grep -q 'ever derived from activity signals' "$SKILL"
grep -q 'TIMELOG.md' "$SKILL"
grep -q 'never feeds amounts here' "$SKILL"

# Immutability and corrections
grep -q 'Amounts are immutable' "$SKILL"
grep -q 'Corrects I#### — reason' "$SKILL"

# Script-computed math and payment neutrality
grep -q 'never from model arithmetic' "$SKILL"
grep -q 'CAP WARNING' "$SKILL"
grep -q 'never asserts payment happened' "$SKILL"

# Ownership
grep -q 'only writer of `INVOICES.md`' "$SKILL"
grep -q 'resolve-context.sh' "$SKILL"
grep -q 'agreement is optional context, not a prerequisite' "$SKILL"
grep -q 'project status.*never.*gate\|never.*gate.*project status' "$SKILL"
! grep -q 'PROPOSALS.md' "$SKILL"

# Template contract
grep -q '<!-- invoices:start -->' "$TEMPLATE"
grep -q '<!-- invoices:end -->' "$TEMPLATE"
grep -q '| Format version | 2 |' "$TEMPLATE"
grep -q '## History' "$TEMPLATE"
grep -q 'never from activity signals' "$TEMPLATE"

# No absolute home paths in the body
! grep -q '~/' "$SKILL"

echo "✓ /as:invoice keeps an append-only, activity-firewalled ledger with script-computed balances"
