#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${ARCHITECTURE_STUDIO_STATE_DIR:-$HOME/.claude}"
ENABLED="$DATA_DIR/.architecture-studio-update-check-enabled"
CACHE="$DATA_DIR/.architecture-studio-version-check"

case "${1:-}" in
  status)
    if [ -f "$ENABLED" ]; then
      printf 'enabled\n'
    else
      printf 'disabled\n'
    fi
    ;;
  enable)
    mkdir -p "$DATA_DIR"
    umask 077
    : > "$ENABLED"
    chmod 600 "$ENABLED" 2>/dev/null || true
    rm -f "$CACHE"
    printf 'enabled\n'
    ;;
  disable)
    rm -f "$ENABLED"
    printf 'disabled\n'
    ;;
  *)
    printf 'usage: %s {status|enable|disable}\n' "$0" >&2
    exit 2
    ;;
esac
