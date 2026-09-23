#!/usr/bin/env bash
# Quick-and-dirty "update everything" for this machine.
#   ./update.sh            bump flake inputs + switch + mas + rustup
#   ./update.sh --no-flake just rebuild from the current flake.lock
#   ./update.sh --gc       ...and garbage-collect the nix store afterwards
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

HOST=macbook
DO_FLAKE=1
DO_GC=0
for arg in "$@"; do
  case "$arg" in
    --no-flake) DO_FLAKE=0 ;;
    --gc)       DO_GC=1 ;;
    -h|--help)  sed -n '2,5p' "$0"; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

say() { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }

if [[ $DO_FLAKE -eq 1 ]]; then
  say "Updating flake inputs"
  nix flake update

  say "Checking the config still evaluates"
  nix eval --raw ".#darwinConfigurations.${HOST}.system.drvPath" >/dev/null
fi

# darwin-rebuild also runs Homebrew: homebrew.onActivation has
# autoUpdate + upgrade + cleanup="zap", so brews/casks/taps update here too.
say "Rebuilding and switching"
sudo darwin-rebuild switch --flake ".#${HOST}"

if command -v mas >/dev/null 2>&1; then
  say "Mac App Store"
  mas upgrade || echo "  (mas had nothing to do, or failed — continuing)"
fi

if command -v rustup >/dev/null 2>&1; then
  say "Rust toolchains"
  # --no-self-update: rustup itself is managed by nix, it can't update in place
  rustup update --no-self-update || echo "  (rustup failed — continuing)"
fi

if [[ $DO_GC -eq 1 ]]; then
  say "Garbage collecting"
  sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +5
  nix-collect-garbage --delete-older-than 30d
  sudo nix-collect-garbage --delete-older-than 30d
fi

say "Done. claude: $(claude --version 2>/dev/null || echo '?')"
