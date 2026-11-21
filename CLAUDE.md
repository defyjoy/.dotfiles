# CLAUDE.md — rebuilding this desktop

This repo is the complete, reproducible state of the user's CachyOS + Niri + Noctalia desktop.
Read `README.md` first (layout, gotchas, YubiKey). This file is the playbook for doing a rebuild or a sync.

## Ground rules

- **sudo has no TTY** from a Claude session. Use `pkexec <cmd>` (polkit dialog), or ask the user to run
  `! ./install.sh` themselves. Never build the initramfs with `mkinitcpio -P` (an interactive wrapper); use `limine-mkinitcpio`.
- **Do not change** niri corner radius (2.5px) or gaps (8). Alacritty stays dark-only. Alacritty `import = [...]` stays multi-line.
- Never commit keys: only `.ssh/config` and `.gnupg/gpg-agent.conf` are tracked. Run a quick secret grep before committing.
- Edit colours via `home/.config/noctalia/templates/`, never the generated files (list in README → "Generated files").
- Commit or push only when the user asks.

## Task A: "is my machine in sync with the repo?"

```bash
./sync.sh --check        # exit 0 = in sync; otherwise lists each differing file/package
```
Diffs in generated colour files are expected after a wallpaper or day/night change. Hand-edited files
(`niri/cfg/*.kdl` except colors, `settings.toml`, `mimeapps.list`, fish, starship layout) are real changes.
Capture with `./sync.sh` (polkit prompt for the root-only snapper config), review `git diff`, then commit if asked.
New config worth tracking → add it to `paths.txt` (home) or `SYSTEM_FILES` in `lib.sh` (/etc), and update README.

## Task B: rebuild from scratch

1. **Base system**: CachyOS installed (any or no DE), user `defyjoy`, Limine bootloader, btrfs.
   Clone: `git clone https://github.com/defyjoy/.dotfiles.git ~/Projects/dotfiles` (HTTPS. SSH needs the YubiKey step first).
2. **Run the installer** (user runs it, needs sudo): `! cd ~/Projects/dotfiles && ./install.sh`
   Installs `packages/pacman.txt` (incl. meta packages `cachyos-niri-noctalia`, `cachyos-fish-config`,
   `cachyos-snapper-support`, `cosmic-greeter`) + `aur.txt` via paru, copies `home/` (backups in `~/.dotfiles-backup/`),
   fixes `.gnupg`/`.ssh` perms, sets fish as login shell, applies gsettings, installs `/etc` files, enables
   resolved/snapper timers and cosmic-greeter.
3. **Manual steps** in README → "Manual steps after install": wallpapers to `~/Pictures/Wallpapers`, `limine-mkinitcpio`,
   merge `/etc/default/limine` cmdline (root UUID differs), snapper `home` config, NetworkManager DNS, check
   `niri msg outputs` matches `DP-1` in `cfg/display.kdl`.
4. **Browsers**: user launches Firefox and Zen once → `./install.sh --no-pkgs --no-system` → install the Pywalfox extension in Firefox.
5. **YubiKey**: user runs `! cd ~/.ssh && ssh-keygen -K` (FIDO2 PIN + touch); test `ssh -T git@github.com`.
   GPG: import the public key from the user's backup, `gpg --card-status`, set trust 5. Then switch the remote to SSH if needed.
6. **Log out → cosmic-greeter → niri session.**

## Verify the rebuild

```bash
./sync.sh --check                                   # should report only generated colour files, if anything
niri validate                                       # config parses
niri msg outputs                                    # G9 at 5120x1440@119.999 on DP-1
grep -nE '^\s*(mode|sunrise|sunset)' ~/.local/state/noctalia/settings.toml   # mode auto, 08:00 / 17:00
noctalia msg theme-mode-get                         # light (08:00-17:00) or dark
nvidia-smi --query-gpu=pstate --format=csv,noheader # P0/P2 under load, not stuck at P8
resolvectl status | grep -E 'DNSOverTLS|Current DNS'  # +DNSOverTLS, 1.1.1.1#cloudflare-dns.com
snapper -c home list | head                         # works without root
ssh-add -L                                          # YubiKey card key (cardno:...)
ssh -T git@github.com                               # "Hi defyjoy!"
gpg --card-status                                   # YubiKey visible; with imported pubkey, `gpg -K` shows ssb>
```
Visual checks to ask the user about: translucent Alacritty/Firefox with blur, gradient focus ring, Noctalia bar + dock,
wallpaper-derived colours, MX Master 3 DPI/smart-shift (Solaar autostarts hidden).
