#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
TEMPLATE_DIR="$SCRIPT_DIR/../templates"

die() {
  printf 'invoice-ledger: %s\n' "$*" >&2
  exit 1
}

validate_root() {
  case "${1:-}" in
    ''|/|.|..|"$HOME") die "unsafe project root: ${1:-<empty>}" ;;
  esac
  case "$1" in
    *$'\n'*|*$'\r'*|*$'\t'*) die "project root contains control characters" ;;
  esac
  [ -d "$1" ] && [ ! -L "$1" ] || die "project root is missing or symlinked: $1"
}

validate_text() {
  [ -n "${2:-}" ] || die "$1 is required"
  case "$2" in
    *'|'*|*'\'*) die "$1 contains a reserved character" ;;
  esac
  if printf '%s' "$2" | LC_ALL=C grep -q '[[:cntrl:]]'; then
    die "$1 contains a control character"
  fi
}

validate_date() {
  printf '%s' "$2" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || die "$1 must be YYYY-MM-DD: $2"
}

validate_amount() {
  printf '%s' "$2" | grep -Eq '^[0-9]+(\.[0-9]{2})?$' || die "$1 must be a plain decimal like 6500.00: $2"
}

escape_sed() {
  printf '%s' "$1" | sed 's/[\\&|]/\\&/g'
}

trim_field() {
  awk -F'|' -v key="$2" '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^\|/ && trim($2)==key {print trim($3); exit}
  ' "$1"
}

field_count() {
  awk -F'|' -v key="$2" '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^\|/ && trim($2)==key {count++}
    END {print count + 0}
  ' "$1"
}

validate_ledger_file() {
  file=$1
  [ -f "$file" ] && [ ! -L "$file" ] || die "ledger file is missing or symlinked: $file"

  [ "$(field_count "$file" "Format version")" = 1 ] || die "ledger must contain exactly one Format version setting"
  version=$(trim_field "$file" "Format version")
  [ "$version" = 2 ] || die "ledger format version is ${version:-absent}; version 2 is required (migrate explicitly before writing)"

  [ "$(field_count "$file" "Maximum Total Cost")" = 1 ] || die "ledger must contain exactly one Maximum Total Cost setting"
  maximum_total_cost=$(trim_field "$file" "Maximum Total Cost")
  [ -n "$maximum_total_cost" ] || die "Maximum Total Cost is blank; use literal 'none' for an uncapped ledger"
  case "$maximum_total_cost" in
    none) ;;
    *) validate_amount "maximum total cost" "$maximum_total_cost" ;;
  esac

  awk '
    /^[[:space:]]*<!-- invoices:start -->[[:space:]]*$/ {starts++; start_line=NR}
    /^[[:space:]]*<!-- invoices:end -->[[:space:]]*$/ {ends++; end_line=NR}
    END {exit (starts == 1 && ends == 1 && start_line < end_line) ? 0 : 1}
  ' "$file" || die "ledger must contain one ordered invoices marker pair"

  if grep -Eq '\{\{[A-Z_]+\}\}' "$file"; then
    die "ledger contains an unresolved template placeholder"
  fi
}

require_ledger() {
  validate_root "$1"
  validate_ledger_file "$1/INVOICES.md"
}

amount_to_cents() {
  case "$1" in
    *.*)
      whole=${1%%.*}
      fraction=${1#*.}
      ;;
    *)
      whole=$1
      fraction=00
      ;;
  esac
  cents="${whole}${fraction}"
  while [ "${#cents}" -gt 1 ] && [ "${cents#0}" != "$cents" ]; do
    cents=${cents#0}
  done
  printf '%s\n' "$cents"
}

add_cents() {
  left=$1
  right=$2
  carry=0
  result=
  while [ -n "$left" ] || [ -n "$right" ] || [ "$carry" -ne 0 ]; do
    left_digit=0
    right_digit=0
    if [ -n "$left" ]; then
      left_digit=${left#${left%?}}
      left=${left%?}
    fi
    if [ -n "$right" ]; then
      right_digit=${right#${right%?}}
      right=${right%?}
    fi
    digit_total=$((left_digit + right_digit + carry))
    result="$((digit_total % 10))$result"
    carry=$((digit_total / 10))
  done
  while [ "${#result}" -gt 1 ] && [ "${result#0}" != "$result" ]; do
    result=${result#0}
  done
  printf '%s\n' "${result:-0}"
}

next_id() {
  awk -F'|' '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^\|/ {
      n = trim($2)
      if (n ~ /^I[0-9][0-9][0-9][0-9]$/) {
        num = substr(n, 2) + 0
        if (num > max) max = num
      }
    }
    END {printf "I%04d\n", max + 1}
  ' "$1/INVOICES.md"
}

init_ledger() {
  root=$1
  project_name=$2
  currency=$3
  cadence=$4
  base_fee=$5
  max_total=$6
  terms_source=$7
  created=$8
  validate_root "$root"
  validate_text "project name" "$project_name"
  validate_text "currency" "$currency"
  validate_text "billing cadence" "$cadence"
  validate_amount "base fee" "$base_fee"
  case "$max_total" in
    none) ;;
    *) validate_amount "maximum total cost" "$max_total" ;;
  esac
  validate_text "terms source" "$terms_source"
  validate_date "created date" "$created"
  [ ! -e "$root/INVOICES.md" ] && [ ! -L "$root/INVOICES.md" ] || die "INVOICES.md already exists or is symlinked at $root"
  tmp=$(mktemp "$root/.invoice-ledger-init.XXXXXX")
  init_tmp=$tmp
  cleanup_init() { rm -f "$init_tmp"; }
  trap cleanup_init EXIT
  if [ "${ARCH_INVOICE_FAIL_AT:-}" = init-render-failure ]; then
    printf '# incomplete render\n' > "$tmp"
    render_ok=false
  elif sed \
    -e "s|{{PROJECT_NAME}}|$(escape_sed "$project_name")|g" \
    -e "s|{{CURRENCY}}|$(escape_sed "$currency")|g" \
    -e "s|{{CADENCE}}|$(escape_sed "$cadence")|g" \
    -e "s|{{BASE_FEE}}|$(escape_sed "$base_fee")|g" \
    -e "s|{{MAX_TOTAL}}|$(escape_sed "$max_total")|g" \
    -e "s|{{TERMS_SOURCE}}|$(escape_sed "$terms_source")|g" \
    -e "s|{{CREATED_DATE}}|$(escape_sed "$created")|g" \
    "$TEMPLATE_DIR/INVOICES.md" > "$tmp"; then
    render_ok=true
  else
    render_ok=false
  fi
  if [ "$render_ok" != true ]; then
    die "ledger render failed; INVOICES.md unchanged"
  fi
  validate_ledger_file "$tmp"
  [ ! -e "$root/INVOICES.md" ] && [ ! -L "$root/INVOICES.md" ] || die "INVOICES.md appeared during initialization; refusing to overwrite it"
  if ! mv "$tmp" "$root/INVOICES.md"; then
    die "ledger publish failed; INVOICES.md unchanged"
  fi
  trap - EXIT
  printf 'created ledger: %s/INVOICES.md\n' "$root"
}

validate_correction_target() {
  root=$1
  new_id=$2
  correction=$3
  [ "$correction" != - ] || return 0

  target=${correction#Corrects }
  target=${target%% *}
  [ "$target" != "$new_id" ] || die "correction cannot target its own row id: $target"

  target_state=$(awk -F'|' -v target="$target" '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^\|/ {
      id = trim($2)
      correction = trim($12)
      if (id == target) target_count++
      if (correction ~ ("^Corrects " target " — ")) corrections++
    }
    END {printf "%d %d\n", target_count + 0, corrections + 0}
  ' "$root/INVOICES.md")
  target_count=${target_state%% *}
  correction_count=${target_state#* }
  [ "$target_count" = 1 ] || die "correction target must resolve to exactly one earlier row: $target"
  [ "$correction_count" = 0 ] || die "correction target was already corrected: $target"
}

append_row() {
  root=$1
  invoice_number=$2
  period_start=$3
  period_end=$4
  base=$5
  expenses=$6
  total=$7
  sent=$8
  paid=$9
  status=${10}
  correction=${11}
  require_ledger "$root"
  validate_text "invoice number" "$invoice_number"
  validate_date "period start" "$period_start"
  validate_date "period end" "$period_end"
  [ "$(printf '%s\n%s\n' "$period_start" "$period_end" | sort | head -1)" = "$period_start" ] || die "period start is after period end"
  validate_amount "base" "$base"
  validate_amount "expenses" "$expenses"
  validate_amount "total" "$total"
  base_cents=$(amount_to_cents "$base")
  expense_cents=$(amount_to_cents "$expenses")
  total_cents=$(amount_to_cents "$total")
  [ "$(add_cents "$base_cents" "$expense_cents")" = "$total_cents" ] || die "total must equal base + expenses"
  case "$sent" in -) ;; *) validate_date "sent date" "$sent" ;; esac
  case "$paid" in -) ;; *) validate_date "paid date" "$paid" ;; esac
  case "$status" in
    draft|sent|paid|void) ;;
    *) die "unknown status: $status (expected draft, sent, paid, or void)" ;;
  esac
  case "$correction" in
    -) ;;
    "Corrects I"[0-9][0-9][0-9][0-9]" — "*)
      correction_reason=${correction#* — }
      validate_text "correction reason" "$correction_reason"
      ;;
    *) die "correction must be '-' or 'Corrects I#### — reason'" ;;
  esac

  id=$(next_id "$root")
  validate_correction_target "$root" "$id" "$correction"
  tmp=$(mktemp "$root/.invoice-ledger.XXXXXX")
  if ! awk -v row="| $id | $invoice_number | $period_start | $period_end | $base | $expenses | $total | $sent | $paid | $status | $correction |" '
    /<!-- invoices:end -->/ {print row; inserted=1}
    {print}
    END {if (!inserted) exit 3}
  ' "$root/INVOICES.md" > "$tmp"; then
    rm -f "$tmp"
    die "ledger append failed; INVOICES.md unchanged"
  fi
  mv "$tmp" "$root/INVOICES.md"
  printf 'appended %s: %s (%s..%s) total %s\n' "$id" "$invoice_number" "$period_start" "$period_end" "$total"
}

set_lifecycle() {
  root=$1
  id=$2
  event=$3
  event_date=$4
  require_ledger "$root"
  validate_text "row id" "$id"
  printf '%s' "$id" | grep -Eq '^I[0-9]{4}$' || die "row id must be I####: $id"
  validate_date "event date" "$event_date"
  case "$event" in
    sent|paid|void) ;;
    *) die "unknown lifecycle event: $event (expected sent, paid, or void)" ;;
  esac

  tmp=$(mktemp "$root/.invoice-ledger.XXXXXX")
  if ! awk -F'|' -v id="$id" -v event="$event" -v d="$event_date" '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    BEGIN {found=0}
    /^\|/ && trim($2)==id {
      sent = trim($9); paid = trim($10); status = trim($11)
      if (event == "sent") { sent = d; status = "sent" }
      if (event == "paid") { paid = d; status = "paid" }
      if (event == "void") { status = "void" }
      print "| " trim($2) " | " trim($3) " | " trim($4) " | " trim($5) " | " trim($6) " | " trim($7) " | " trim($8) " | " sent " | " paid " | " status " | " trim($12) " |"
      found++
      next
    }
    {print}
    END {exit found == 1 ? 0 : 2}
  ' "$root/INVOICES.md" > "$tmp"; then
    rm -f "$tmp"
    die "row id must resolve to exactly one ledger row: $id"
  fi
  if [ "${ARCH_INVOICE_FAIL_AT:-}" = lifecycle-before-history ]; then
    rm -f "$tmp"
    die "injected lifecycle failure; INVOICES.md unchanged"
  fi
  if ! printf -- '- %s: %s marked %s\n' "$event_date" "$id" "$event" >> "$tmp"; then
    rm -f "$tmp"
    die "lifecycle history update failed; INVOICES.md unchanged"
  fi
  if ! mv "$tmp" "$root/INVOICES.md"; then
    rm -f "$tmp"
    die "lifecycle publish failed; INVOICES.md unchanged"
  fi
  printf 'lifecycle updated: %s -> %s (%s)\n' "$id" "$event" "$event_date"
}

status_ledger() {
  root=$1
  require_ledger "$root"
  currency=$(trim_field "$root/INVOICES.md" "Currency")
  cap=$(trim_field "$root/INVOICES.md" "Maximum Total Cost")
  sed -n '/<!-- invoices:start -->/,/<!-- invoices:end -->/p' "$root/INVOICES.md" | awk -F'|' -v currency="$currency" -v cap="$cap" '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    function jdn(y, m, d, a) { a = int((14 - m) / 12); y = y + 4800 - a; m = m + 12 * a - 3
      return d + int((153 * m + 2) / 5) + 365 * y + int(y / 4) - int(y / 100) + int(y / 400) - 32045 }
    function datejdn(s) { return jdn(substr(s,1,4)+0, substr(s,6,2)+0, substr(s,9,2)+0) }
    /^\|/ {
      id = trim($2)
      if (id !~ /^I[0-9][0-9][0-9][0-9]$/) next
      rows++
      ids[rows] = id
      ps[rows] = trim($4); pe[rows] = trim($5)
      totals[rows] = trim($8) + 0
      statuses[rows] = trim($11)
      corr = trim($12)
      if (statuses[rows] != "void" && corr ~ /^Corrects I[0-9][0-9][0-9][0-9]/) corrected[substr(corr, 10, 5)] = 1
    }
    END {
      total = 0; outstanding = 0; periods = 0
      for (i = 1; i <= rows; i++) {
        if (statuses[i] == "void" || (ids[i] in corrected)) continue
        total += totals[i]
        if (statuses[i] == "sent") outstanding += totals[i]
        periods++
        starts[periods] = ps[i]; ends[periods] = pe[i]
      }
      printf "currency=%s\n", currency
      printf "total=%.2f\n", total
      printf "outstanding=%.2f\n", outstanding
      if (cap == "none") {
        printf "cap=none\n"
      } else {
        pct = (cap + 0 > 0) ? total / (cap + 0) * 100 : 0
        printf "cap=%.2f\n", cap + 0
        printf "pct=%.1f\n", pct
        if (pct >= 80) printf "CAP WARNING: %.1f%% of Maximum Total Cost consumed\n", pct
      }
      # sort periods by start (insertion sort; ledgers are small)
      for (i = 2; i <= periods; i++) {
        s = starts[i]; e = ends[i]; j = i - 1
        while (j > 0 && starts[j] > s) { starts[j+1] = starts[j]; ends[j+1] = ends[j]; j-- }
        starts[j+1] = s; ends[j+1] = e
      }
      if (periods > 0) max_end = ends[1]
      for (i = 2; i <= periods; i++) {
        if (datejdn(starts[i]) > datejdn(max_end) + 1)
          printf "coverage gap: %s..%s\n", max_end, starts[i]
        if (datejdn(ends[i]) > datejdn(max_end)) max_end = ends[i]
      }
      if (periods > 0) printf "last period end: %s\n", max_end
    }
  '
}

case "${1:-}" in
  init)
    [ $# -eq 9 ] || die "usage: invoice-ledger.sh init <project-root> <project-name> <currency> <cadence> <base-fee> <max-total|none> <terms-source> <date>"
    init_ledger "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
    ;;
  allocate)
    [ $# -eq 2 ] || die "usage: invoice-ledger.sh allocate <project-root>"
    require_ledger "$2"
    next_id "$2"
    ;;
  append)
    [ $# -eq 12 ] || die "usage: invoice-ledger.sh append <project-root> <invoice-number> <period-start> <period-end> <base> <expenses> <total> <sent|-> <paid|-> <status> <correction|->"
    append_row "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}" "${11}" "${12}"
    ;;
  set-lifecycle)
    [ $# -eq 5 ] || die "usage: invoice-ledger.sh set-lifecycle <project-root> <row-id> <sent|paid|void> <date>"
    set_lifecycle "$2" "$3" "$4" "$5"
    ;;
  status)
    [ $# -eq 2 ] || die "usage: invoice-ledger.sh status <project-root>"
    status_ledger "$2"
    ;;
  *)
    die "usage: invoice-ledger.sh {init|allocate|append|set-lifecycle|status} ..."
    ;;
esac
