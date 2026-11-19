#!/usr/bin/env bash
# Restore this configuration on a fresh CachyOS install.
#   ./install.sh            everything
#   ./install.sh --no-pkgs  skip package installation
#   ./install.sh --no-system skip /etc files
set -euo pipefail
source "$(dirname "$0")/lib.sh"
cd "$REPO"
PKGS=1 SYSTEM=1
for a in "$@"; do case $a in --no-pkgs) PKGS=0;; --no-system) SYSTEM=0;; esac; done

if ((PKGS)); then
  echo ":: packages"
  sudo pacman -S --needed - < <(comm -12 <(sort packages/pacman.txt) <(pacman -Slq | sort))
  if command -v paru >/dev/null; then paru -S --needed - < packages/aur.txt
  else echo "   paru not found; install AUR packages manually: packages/aur.txt"; fi
fi

echo ":: home files (existing files are backed up to ~/.dotfiles-backup)"
BK="$HOME/.dotfiles-backup/$(date +%F-%H%M%S)"
rsync -a --backup --backup-dir="$BK" home/ "$HOME/"

echo ":: browsers (profile must exist: launch the browser once first)"
for b in firefox:"$HOME/.config/mozilla/firefox" zen:"$HOME/.config/zen"; do
  name=${b%%:*}; prof=$(default_profile "${b#*:}" || true)
  [[ -d "browser/$name" ]] || continue
  if [[ -n "$prof" ]]; then rsync -a "browser/$name/" "$prof/"; echo "   $name -> $prof"
  else echo "   $name: no profile yet, skipped"; fi
done

echo ":: gsettings"
while read -r schema key val; do gsettings set "$schema" "$key" "$val"; done < gsettings.txt

if ((SYSTEM)); then
  echo ":: system files"
  for f in "${SYSTEM_FILES[@]}"; do
    [[ -f "system$f" ]] || continue
    [[ $f == /etc/default/limine ]] && { echo "   skip $f (contains root UUID; merge by hand)"; continue; }
    [[ -f $f ]] && sudo cp "$f" "$f.pre-dotfiles"
    sudo install -Dm644 "system$f" "$f"
  done
  sudo systemctl enable --now systemd-resolved snapper-timeline.timer snapper-cleanup.timer
  grep -q '^SNAPPER_CONFIGS=.*home' /etc/conf.d/snapper 2>/dev/null \
    || echo "   NOTE: add 'home' to SNAPPER_CONFIGS in /etc/conf.d/snapper (and create /home/.snapshots)"
  echo "   rebuild initramfs for the NVIDIA option: sudo limine-mkinitcpio"
fi

echo ":: done. Log out and pick the niri session."
