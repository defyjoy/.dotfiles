# dotfiles — CachyOS · Niri · Noctalia

My CachyOS desktop: **Niri** compositor + **Noctalia** shell, fish + starship, Alacritty,
wallpaper-driven Material You theming across GTK/Qt/Alacritty/btop/Firefox.
Hardware it is tuned for: Samsung Odyssey G9 (5120x1440@120 on DP-1), RTX 4070 Super, MX Master 3.

## Layout

| Path | What | Restored to |
|---|---|---|
| `home/` | Mirror of `$HOME` (list in `paths.txt`) | `~` (copied, not symlinked) |
| `browser/firefox`, `browser/zen` | `chrome/` userChrome/userContent + `user.js` | default profile dir |
| `system/etc/` | NVIDIA PowerMizer fix, DoT DNS, `en_IN` locale, snapper `home` config, limine cmdline | `/etc` |
| `gsettings.txt` | GTK theme, icons (Papirus-Dark), cursor (Bibata-Modern-Ice), fonts (Inter 11) | dconf |
| `packages/pacman.txt` / `aur.txt` | Explicitly installed native / AUR packages | pacman / paru |

Files are **copied** rather than symlinked because Noctalia and Solaar rewrite their
configs (and Noctalia regenerates the colour files), which would replace symlinks.

## Usage

```fish
# capture current machine state into the repo, then review + commit
./sync.sh && git diff

# restore on a fresh CachyOS install (pick "no desktop" or any DE in the installer)
git clone <repo> ~/Projects/dotfiles && cd ~/Projects/dotfiles
./install.sh                # or --no-pkgs / --no-system
```

To track another file, add its `$HOME`-relative path to `paths.txt` and run `./sync.sh`.

## Manual steps after install

- **Wallpapers** (~80 MB) are not in git. Copy them to `~/Pictures/Wallpapers` — Noctalia derives the whole palette from the wallpaper.
- **Initramfs**: `sudo limine-mkinitcpio` (not `mkinitcpio -P`) so `nvidia-power.conf` takes effect.
- **Limine**: `system/etc/default/limine` holds the old root UUID; merge the cmdline by hand.
- **Snapper /home**: `sudo snapper -c home create-config /home` first, then let `install.sh` overwrite the config
  (hourly 5 / daily 7, `ALLOW_USERS`). Optionally make `~/.local/share/Steam` its own subvolume to keep games out of snapshots.
- **DNS**: `resolved.conf` is the single source. Stop NetworkManager pushing DHCP DNS on each connection:
  `nmcli con mod "<name>" ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes ipv4.dns "" ipv6.dns ""`.
- **Browsers**: launch Firefox/Zen once so a profile exists, then re-run `./install.sh --no-pkgs --no-system`.
  Install the Pywalfox extension + `pywalfox install` for the native host.
- **Solaar**: quit the running `solaar` before editing its config, or it overwrites it on exit.

## Gotchas

- Keep niri **2.5px corners and gaps 8**.
- Alacritty `import = [...]` must stay multi-line (Noctalia's apply script breaks one-line arrays).
- Alacritty is always dark: `themes/noctalia-wallpaper.toml` imports `noctalia-dark.toml`.
- Noctalia templates support `{{mode}}` and filters, not `{% if %}`.
- Firefox rule in `niri/cfg/rules.kdl` needs `draw-border-with-background false`, otherwise the focus ring paints behind the translucent window.

## Not included (deliberately)

Secrets and machine state: `~/.ssh`, `~/.kube`, `~/.docker`, `~/.claude*`, browser profiles (only chrome CSS and `user.js` are kept),
`fish_variables`, `*.bak` files and `niri/backup-*`, COSMIC leftovers, micro's bundled syntax files.
