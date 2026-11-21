# dotfiles — CachyOS · Niri · Noctalia

My CachyOS desktop: **Niri** compositor + **Noctalia** shell, fish + starship, Alacritty,
wallpaper-driven Material You theming across GTK/Qt/Alacritty/btop/Firefox/Zen, YubiKey for SSH/GPG.
Hardware it is tuned for: Samsung Odyssey G9 (5120x1440@120 on DP-1), RTX 4070 Super (+ AMD iGPU), MX Master 3.

Rebuilding with Claude? Hand it this repo — [`CLAUDE.md`](CLAUDE.md) is the step-by-step playbook.

## Layout

| Path | What | Restored to |
|---|---|---|
| `home/` | Mirror of `$HOME` (list in `paths.txt`) | `~` (copied, not symlinked) |
| `browser/firefox`, `browser/zen` | `chrome/` userChrome/userContent + `user.js` | default profile dir |
| `system/etc/` | NVIDIA PowerMizer fix, DoT DNS, `en_IN` locale, snapper `home` config, limine cmdline | `/etc` |
| `gsettings.txt` | Icons (Papirus-Dark), cursor (Bibata-Modern-Ice), fonts (Inter 11) | dconf |
| `packages/pacman.txt` / `aur.txt` | Explicitly installed native / AUR packages | pacman / paru |
| `sync.sh` | live machine → repo (`--check` = report drift only) | |
| `install.sh` | repo → fresh machine | |

What lives in `home/`:

| Area | Files |
|---|---|
| Niri | `.config/niri/config.kdl` + `cfg/{animation,autostart,keybinds,input,display,layout,colors,rules,misc}.kdl` |
| Noctalia | `.config/noctalia/config.toml` (user templates), `templates/`, `.local/state/noctalia/settings.toml` (bar, dock, theme mode, wallpaper) |
| Terminal / shell | `alacritty/`, `fish/config.fish`, `fish/functions/`, `fish/conf.d/`, `starship.toml`, `.zshrc`, `bat/`, `btop/`, `fastfetch/`, `micro/` |
| Toolkits | `gtk-3.0/`, `gtk-4.0/`, `qt5ct/`, `qt6ct/`, `.icons/default/index.theme` |
| Apps | `solaar/config.yaml`, `pywalfox/config.json`, `mimeapps.list` (Zen = default browser), `user-dirs.dirs` |
| Browser host | `{.config/mozilla,.mozilla}/native-messaging-hosts/pywalfox.json` → `/usr/bin/noctalia` |
| YubiKey | `.gnupg/gpg-agent.conf`, `.ssh/config`, `environment.d/gpg-ssh.conf`, `fish/conf.d/gpg-ssh.fish` |

Files are **copied** rather than symlinked because Noctalia and Solaar rewrite their
configs (and Noctalia regenerates the colour files), which would replace symlinks.

**Generated files** (rewritten by Noctalia from the wallpaper, so they change whenever the wallpaper or
day/night mode changes — commit them, but don't hand-edit): `niri/cfg/colors.kdl`, `alacritty/themes/noctalia-{dark,light}.toml`,
`gtk-*/noctalia*.css`, `qt*ct/colors/noctalia.conf`, `btop/themes/noctalia.theme`, starship palette, `pywalfox/config.json`.
Edit the **templates** in `.config/noctalia/templates/` instead.

## Usage

```fish
# is the repo up to date with this machine?
./sync.sh --check           # exit 1 + list of differences if not

# capture current machine state into the repo, then review + commit
./sync.sh && git diff

# restore on a fresh CachyOS install (pick "no desktop" or any DE in the installer)
git clone https://github.com/defyjoy/.dotfiles.git ~/Projects/dotfiles && cd ~/Projects/dotfiles
./install.sh                # or --no-pkgs / --no-system
```

To track another file, add its `$HOME`-relative path to `paths.txt` and run `./sync.sh`.
To track another `/etc` file, add it to `SYSTEM_FILES` in `lib.sh`.

## Manual steps after install

- **Wallpapers** (~80 MB) are not in git. Copy them to `~/Pictures/Wallpapers` — Noctalia derives the whole palette
  from the wallpaper, and `settings.toml` points at a file in there. Wallpaper automation (shuffle) is on.
- **Initramfs**: `sudo limine-mkinitcpio` (not `mkinitcpio -P`) so `nvidia-power.conf` takes effect.
- **Limine**: `system/etc/default/limine` holds the old root UUID; merge the cmdline by hand.
- **Snapper /home**: `sudo snapper -c home create-config /home` first, then let `install.sh` overwrite the config
  (hourly 5 / daily 7, `ALLOW_USERS`). Optionally make `~/.local/share/Steam` its own subvolume to keep games out of snapshots.
- **DNS**: `resolved.conf` is the single source. Stop NetworkManager pushing DHCP DNS on each connection:
  `nmcli con mod "<name>" ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes ipv4.dns "" ipv6.dns ""`.
- **Display**: `niri/cfg/display.kdl` names output `DP-1`. On other hardware check `niri msg outputs` and adjust.
- **Login screen**: `cosmic-greeter` (enabled by `install.sh` if no display manager is set); pick the **niri** session.
- **Browsers**: launch Firefox/Zen once so a profile exists, then re-run `./install.sh --no-pkgs --no-system`.
  Install the **Pywalfox** extension in Firefox. No `pywalfox` pip package is needed — Noctalia itself is the native host
  (the manifests in `native-messaging-hosts/` point at `/usr/bin/noctalia`).
- **Solaar**: quit the running `solaar` before editing its config, or it overwrites it on exit.
- **YubiKey** (see below).

## YubiKey (SSH + GPG)

YubiKey 5, originally set up on macOS. Two independent pieces:

- **GitHub SSH = FIDO2 resident key.** The key lives on the YubiKey; the files in `~/.ssh` are just handles. Recreate them with
  `cd ~/.ssh && ssh-keygen -K` (FIDO2 PIN + touch) — this writes `id_ed25519_sk_rk_<name>`; `.ssh/config` uses
  `id_ed25519_sk_rk_defyjoy` for `github.com` with `IdentitiesOnly yes`. Test: `ssh -T git@github.com` (touch when it blinks).
  gpg-agent cannot serve `sk-` keys, so this must stay an `IdentityFile`.
- **GPG = OpenPGP card applet** (sign/encrypt/auth RSA-2048; signing requires touch). `gpg-agent.conf` enables ssh support and
  pinentry-qt, so `SSH_AUTH_SOCK` points at gpg-agent (set in fish, zsh and `environment.d`). The public key is **not** on any
  keyserver — import it from a backup / the Mac (`gpg --import pubkey.asc`), run `gpg --card-status`, then set ultimate trust.
- scdaemon uses its **built-in CCID driver**; `pcscd`/`ccid` are not used. Only add `disable-ccid` to `scdaemon.conf` if you
  install and run `pcscd` + `ccid`.

## Gotchas

- Keep niri **2.5px corners and gaps 8**.
- Alacritty `import = [...]` must stay multi-line (Noctalia's apply script breaks one-line arrays).
- Alacritty is always dark: `themes/noctalia-wallpaper.toml` imports `noctalia-dark.toml`.
- Noctalia templates support `{{mode}}` and filters, not `{% if %}`.
- Noctalia theme mode is `auto` with a fixed schedule (light 08:00, dark 17:00); it also flips gsettings
  `gtk-theme`/`color-scheme`, which is why those two are not tracked in `gsettings.txt`.
- Firefox rule in `niri/cfg/rules.kdl` needs `draw-border-with-background false`, otherwise the focus ring paints behind the translucent window.
- The AUR package `zen` is the Zen *programming language*, not the browser (that is `zen-browser-bin` from the CachyOS repo).

## Not included (deliberately)

Secrets and machine state: SSH/GPG **keys** (only `.ssh/config` and `gpg-agent.conf` are kept), `~/.kube`, `~/.docker`, `~/.claude*`,
browser profiles (only chrome CSS and `user.js` are kept), `fish_variables`, Noctalia history/clipboard/usage state,
`*.bak` files and `niri/backup-*`, COSMIC leftovers, micro's bundled syntax files, wallpapers.
