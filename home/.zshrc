source /usr/share/cachyos-zsh-config/cachyos-config.zsh

# YubiKey: use gpg-agent as ssh-agent
export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
