#!/usr/bin/env bash
# Capture the live configuration from this machine into the repo.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
cd "$REPO"

echo ":: home files"
paths | while read -r p; do
  p="${p%/}"; src="$HOME/$p"
  [[ -e "$src" ]] || { echo "   skip (missing): $p"; continue; }
  mkdir -p "home/$(dirname "$p")"
  rsync -a --delete "${EXCLUDES[@]}" "$src" "home/$(dirname "$p")/"
done

echo ":: browsers"
for b in firefox:"$HOME/.config/mozilla/firefox" zen:"$HOME/.config/zen"; do
  name=${b%%:*}; prof=$(default_profile "${b#*:}" || true)
  [[ -n "$prof" ]] || continue
  mkdir -p "browser/$name"
  [[ -d "$prof/chrome" ]] && rsync -a --delete "$prof/chrome/" "browser/$name/chrome/"
  [[ -f "$prof/user.js" ]] && cp "$prof/user.js" "browser/$name/"
done

echo ":: system files"
for f in "${SYSTEM_FILES[@]}"; do
  if [[ -r "$f" ]]; then install -Dm644 "$f" "system$f"
  elif [[ -e "$f" ]]; then mkdir -p "system$(dirname "$f")"; pkexec cat "$f" > "system$f"; fi
done

echo ":: gsettings"
gsettings list-recursively org.gnome.desktop.interface \
  | grep -E ' (gtk-theme|icon-theme|cursor-theme|cursor-size|font-name|document-font-name|monospace-font-name|color-scheme|font-hinting|font-antialiasing) ' \
  > gsettings.txt

echo ":: packages"
pacman -Qqen > packages/pacman.txt
pacman -Qqem > packages/aur.txt

git status --short
