#!/usr/bin/env bash
# Capture the live configuration from this machine into the repo.
#   ./sync.sh          copy live state into the repo (then review `git diff` and commit)
#   ./sync.sh --check  report drift between live state and the repo; changes nothing,
#                      exits 1 if anything differs
set -euo pipefail
source "$(dirname "$0")/lib.sh"
cd "$REPO"
CHECK=0; [[ ${1:-} == --check ]] && CHECK=1
DRIFT=0
drift() { DRIFT=1; echo "   $*"; }

# gtk-theme and color-scheme are left out: Noctalia flips them with day/night mode.
GSETTINGS_KEYS=' (icon-theme|cursor-theme|cursor-size|font-name|document-font-name|monospace-font-name|font-hinting|font-antialiasing) '
gsettings_now() { gsettings list-recursively org.gnome.desktop.interface | grep -E "$GSETTINGS_KEYS"; }

echo ":: home files"
while read -r p; do
  p="${p%/}"; src="$HOME/$p"
  [[ -e "$src" ]] || { echo "   skip (missing on this machine): $p"; continue; }
  if ((CHECK)); then
    out=$(rsync -anci --delete "${EXCLUDES[@]}" "$src" "home/$(dirname "$p")/" | grep -vE '^(\.d|created directory)' || true)
    d=$(dirname "$p"); [[ $d == . ]] && d= || d="$d/"
    [[ -n $out ]] && { DRIFT=1; sed "s|^[^ ]* |   ~/$d|" <<<"$out"; }
  else
    mkdir -p "home/$(dirname "$p")"
    rsync -a --delete "${EXCLUDES[@]}" "$src" "home/$(dirname "$p")/"
  fi
done < <(paths)

echo ":: browsers"
for b in firefox:"$HOME/.config/mozilla/firefox" zen:"$HOME/.config/zen"; do
  name=${b%%:*}; prof=$(default_profile "${b#*:}" || true)
  [[ -n "$prof" ]] || continue
  if ((CHECK)); then
    [[ -d "$prof/chrome" ]] && { out=$(rsync -anci --delete "$prof/chrome/" "browser/$name/chrome/" | grep -v '^\.d' || true)
      [[ -n $out ]] && { DRIFT=1; sed "s|^[^ ]* |   $name chrome/|" <<<"$out"; }; }
    [[ -f "$prof/user.js" ]] && ! cmp -s "$prof/user.js" "browser/$name/user.js" && drift "$name user.js"
  else
    mkdir -p "browser/$name"
    [[ -d "$prof/chrome" ]] && rsync -a --delete "$prof/chrome/" "browser/$name/chrome/"
    [[ -f "$prof/user.js" ]] && cp "$prof/user.js" "browser/$name/"
  fi
done

echo ":: system files"
for f in "${SYSTEM_FILES[@]}"; do
  [[ -e "$f" ]] || { echo "   skip (missing): $f"; continue; }
  if ((CHECK)); then
    if [[ -r "$f" ]]; then cmp -s "$f" "system$f" || drift "$f"
    else echo "   not readable without root, not checked: $f"; fi
  elif [[ -r "$f" ]]; then install -Dm644 "$f" "system$f"
  else mkdir -p "system$(dirname "$f")"; pkexec cat "$f" > "system$f"; fi
done

echo ":: gsettings"
if ((CHECK)); then diff -q <(gsettings_now) gsettings.txt >/dev/null || drift "gsettings.txt"
else gsettings_now > gsettings.txt; fi

echo ":: packages"
if ((CHECK)); then
  for kind in pacman:en aur:em; do
    out=$(diff <(pacman -Qq"${kind#*:}") "packages/${kind%%:*}.txt" \
          | sed -n "s/^< /   + ${kind%%:*} (installed, not in repo) /p; s/^> /   - ${kind%%:*} (in repo, not installed) /p" || true)
    [[ -n $out ]] && { DRIFT=1; echo "$out"; }
  done
  if ((DRIFT)); then echo ":: DRIFT: live state differs from the repo (run ./sync.sh to capture)"; exit 1; fi
  echo ":: in sync"; exit 0
fi
pacman -Qqen > packages/pacman.txt
pacman -Qqem > packages/aur.txt

git status --short
