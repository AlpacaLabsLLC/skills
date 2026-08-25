#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SKILL=skills/proposal/SKILL.md
README=skills/proposal/README.md
SCRIPT=skills/proposal/scripts/proposal-workspace.sh
TC=skills/proposal/references/tc-library.md
TEMPLATE=skills/proposal/templates/proposal.md
LETTER_TEMPLATE=skills/proposal/templates/proposal-letter.html

for f in "$SKILL" "$README" "$SCRIPT" "$TC" "$TEMPLATE" \
  "$LETTER_TEMPLATE"; do
  [ -f "$f" ] || { echo "missing contract file: $f"; exit 1; }
done

[ ! -e skills/proposal/templates/PROPOSALS.md ]
[ ! -e skills/proposal/scripts/proposal-register.sh ]
grep -q '^name: proposal$' "$SKILL"

for command in create list status send accept decline supersede verify; do
  grep -q "/as:proposal $command" "$SKILL" || { echo "missing command: $command"; exit 1; }
done

# Ownership, identity, and deliberately light workflow boundaries.
grep -q 'project-local `proposals/`' "$SKILL"
grep -q 'never writes `STUDIO.md`' "$SKILL"
grep -q 'YYYY-MM-SHORT-TITLE-proposal-rev-NN.md' "$SKILL"
grep -q 'Rev\. 01' "$SKILL"
grep -q 'never overwrite' "$SKILL"
grep -q 'resolve-context.sh' "$SKILL"
grep -q 'status.*context\|context.*status' "$SKILL"
grep -q 'does not enforce.*sequence\|never enforces.*sequence' "$SKILL"
if grep -q 'PROPOSALS.md\|Proposal prefix\|{PREFIX}-{NNNN}' "$SKILL"; then
  echo "obsolete register identity remains in $SKILL"
  exit 1
fi

# Issued terms are frozen; lifecycle metadata remains outside that boundary.
grep -q 'SHA-256' "$SKILL"
grep -q 'issued-terms:start' "$TEMPLATE"
grep -q 'issued-terms:end' "$TEMPLATE"
grep -q 'proposal-lifecycle:start' "$TEMPLATE"
grep -q '| Issued terms SHA-256 | — |' "$TEMPLATE"
grep -q '| Legacy number | {{LEGACY_NUMBER}} |' "$TEMPLATE"
grep -q 'new revision' "$SKILL"

# Acceptance hands off by local path and checksum, without copying or status automation.
grep -q 'agreement promote <project-relative proposal path>' "$SKILL"
grep -q 'path and checksum' "$SKILL"
grep -q 'never changes project status' "$SKILL"

# Client-facing HTML prefers a firm-owned standard and preserves local identity.
grep -q 'standards/proposal-letter.html' "$SKILL"
grep -q 'bundled.*templates/proposal-letter.html\|templates/proposal-letter.html.*fallback' "$SKILL"
grep -q '{{PROJECT_ID}}' "$LETTER_TEMPLATE"
grep -q '{{REVISION}}' "$LETTER_TEMPLATE"
grep -q '{{STATUS}}' "$LETTER_TEMPLATE"
grep -q '{{STUDIO_INITIAL}}' "$LETTER_TEMPLATE"
grep -q '@media print' "$LETTER_TEMPLATE"
grep -q '@media (max-width:' "$LETTER_TEMPLATE"
grep -q 'table\.data-table' "$LETTER_TEMPLATE"
grep -q 'table-layout: fixed' "$LETTER_TEMPLATE"
grep -q 'content: attr(data-label)' "$LETTER_TEMPLATE"
for obsolete_letter_contract in PROPOSAL_NUMBER section-num 'Geist Mono' --mono SFMono monospace; do
  if grep -q -- "$obsolete_letter_contract" "$LETTER_TEMPLATE"; then
    echo "obsolete letter styling remains: $obsolete_letter_contract"
    exit 1
  fi
done
if grep -Eq 'https?://|fonts\.googleapis|fonts\.gstatic' "$LETTER_TEMPLATE"; then
  echo "proposal HTML template must render without external font or asset requests"
  exit 1
fi
grep -q 'border-top: 1px solid var(--ink)' "$LETTER_TEMPLATE"

masthead_css=$(sed -n '/^  \.masthead {/,/^  }/p' "$LETTER_TEMPLATE")
meta_css=$(sed -n '/^  \.meta {/,/^  }/p' "$LETTER_TEMPLATE")
if printf '%s\n%s\n' "$masthead_css" "$meta_css" | grep -q 'border-'; then
  echo "document header rules remain in $LETTER_TEMPLATE"
  exit 1
fi

# Proposal records and letters present the commercial sequence consistently.
template_scope_line=$(grep -n '^### Scope of services$' "$TEMPLATE" | cut -d: -f1)
template_fees_line=$(grep -n '^### Fees$' "$TEMPLATE" | cut -d: -f1)
template_exclusions_line=$(grep -n '^### Not included$' "$TEMPLATE" | cut -d: -f1)
test "$template_scope_line" -lt "$template_fees_line"
test "$template_fees_line" -lt "$template_exclusions_line"

letter_scope_line=$(grep -n '<h2>Scope of services</h2>' "$LETTER_TEMPLATE" | cut -d: -f1)
letter_fees_line=$(grep -n '<h2>Fees</h2>' "$LETTER_TEMPLATE" | cut -d: -f1)
letter_exclusions_line=$(grep -n '<h2>Not included</h2>' "$LETTER_TEMPLATE" | cut -d: -f1)
test "$letter_scope_line" -lt "$letter_fees_line"
test "$letter_fees_line" -lt "$letter_exclusions_line"

# Legal caution, verbatim in skill, library, and rendered template.
CAUTION='These clauses are drafting guidance, not legal advice; have a licensed attorney review before signing.'
grep -qF "$CAUTION" "$SKILL"
grep -qF "$CAUTION" "$TC"
grep -qF "$CAUTION" "$TEMPLATE"

if grep -q '~[/]' "$SKILL"; then
  echo "home-relative path remains in $SKILL"
  exit 1
fi

echo "✓ /as:proposal owns project-local proposals, freezes issued terms, and leaves workflow judgment to the user"
