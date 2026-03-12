#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="${HOME}/.claude/skills"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

ALL_SKILLS=(
  create-design-deck
  occupancy-calculator
  product-image-processor
  product-spec-bulk-cleanup
  product-spec-bulk-fetch
  product-spec-pdf-parser
  workplace-programmer
  zoning-analyzer
)

usage() {
  echo "Usage: ./install.sh [skill-name ...]"
  echo ""
  echo "Install Claude Code skills by symlinking into ~/.claude/skills/"
  echo ""
  echo "  ./install.sh                        Install all skills"
  echo "  ./install.sh workplace-programmer    Install one skill"
  echo "  ./install.sh --list                  List available skills"
  echo ""
  echo "Available skills:"
  for s in "${ALL_SKILLS[@]}"; do echo "  $s"; done
}

list_skills() {
  for s in "${ALL_SKILLS[@]}"; do echo "$s"; done
}

install_skill() {
  local skill="$1"
  local src="${REPO_DIR}/${skill}"
  local dest="${SKILLS_DIR}/${skill}"

  if [ ! -d "$src" ]; then
    echo "Error: skill '${skill}' not found in repo" >&2
    return 1
  fi

  if [ -L "$dest" ]; then
    echo "  ${skill} — already linked, skipping"
    return 0
  fi

  if [ -e "$dest" ]; then
    echo "  ${skill} — exists but is not a symlink, skipping (remove manually to reinstall)"
    return 0
  fi

  ln -s "$src" "$dest"
  echo "  ${skill} — installed"
}

# Parse args
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if [ "${1:-}" = "--list" ]; then
  list_skills
  exit 0
fi

# Ensure target directory exists
mkdir -p "$SKILLS_DIR"

# Determine which skills to install
if [ $# -eq 0 ]; then
  SELECTED=("${ALL_SKILLS[@]}")
  echo "Installing all skills..."
else
  SELECTED=("$@")
  echo "Installing selected skills..."
fi

for skill in "${SELECTED[@]}"; do
  install_skill "$skill"
done

echo "Done."
