function starship-theme --description 'Pick a Starship preset with a live rendered preview'
    set -l cfg ~/.config/starship.toml
    set -l presets (starship preset --list)

    if set -q argv[1]
        if not contains -- $argv[1] $presets
            echo "No preset named '$argv[1]'. Run 'starship-theme' to browse." >&2
            return 1
        end
        test -f $cfg; and cp $cfg $cfg.bak
        starship preset $argv[1] -o $cfg --force; or return 1
        echo "Applied $argv[1] (previous config saved as starship.toml.bak)"
        return 0
    end

    set -l tmp (mktemp -d)
    # Each preview renders the real prompt for the current directory.
    set -l preview "starship preset {} -o $tmp/{}.toml --force && env STARSHIP_CONFIG=$tmp/{}.toml starship prompt --terminal-width \$FZF_PREVIEW_COLUMNS --status 0 --cmd-duration 2400"

    set -l choice (printf '%s\n' $presets | \
        fzf --ansi --prompt='Starship> ' --height=70% --reverse \
            --header='↑/↓ previews · Enter applies · Esc cancels' \
            --preview $preview --preview-window=down,40%,wrap)
    rm -rf $tmp

    if test -n "$choice"
        starship-theme $choice
    end
end
