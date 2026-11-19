# Shared helpers for sync.sh / install.sh
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXCLUDES=(--exclude='*.bak' --exclude='*.bak-*' --exclude='backup-*/' --exclude='current-theme.toml')

paths() { grep -vE '^\s*(#|$)' "$REPO/paths.txt"; }

# Firefox / Zen keep profiles under random names; pick the one marked default in installs.ini.
default_profile() { # $1 = profile root (e.g. ~/.config/mozilla/firefox)
  local root="$1" p
  [[ -f "$root/installs.ini" ]] && p=$(grep -m1 '^Default=' "$root/installs.ini" | cut -d= -f2-)
  [[ -z "$p" && -f "$root/profiles.ini" ]] && p=$(grep -m1 '^Path=' "$root/profiles.ini" | cut -d= -f2-)
  [[ -n "$p" && -d "$root/$p" ]] && echo "$root/$p"
}

SYSTEM_FILES=(
  /etc/modprobe.d/nvidia-power.conf
  /etc/systemd/resolved.conf
  /etc/locale.conf
  /etc/snapper/configs/home
  /etc/default/limine
)
