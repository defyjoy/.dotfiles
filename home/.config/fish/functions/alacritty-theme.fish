function alacritty-theme --description 'Pick an Alacritty theme with live preview'
    set -l themes_dir /usr/lib/node_modules/alacritty-themes/themes
    set -l current ~/.config/alacritty/current-theme.toml
    set -l backup (mktemp)

    if not test -d $themes_dir
        echo "Themes not found in $themes_dir (is alacritty-themes installed?)" >&2
        return 1
    end

    # Alacritty reloads current-theme.toml live, so copying a theme previews it.
    test -f $current; and cp $current $backup

    if set -q argv[1]
        set -l file $themes_dir/$argv[1].toml
        if not test -f $file
            echo "No theme named '$argv[1]'. Run 'alacritty-theme' to browse." >&2
            rm -f $backup
            return 1
        end
        cp $file $current
        echo "Applied $argv[1]"
        rm -f $backup
        return 0
    end

    set -l choice (path basename -E $themes_dir/*.toml | \
        fzf --prompt='Theme> ' --height=60% --reverse \
            --header='↑/↓ previews live · Enter applies · Esc cancels' \
            --bind "focus:execute-silent(cp $themes_dir/{}.toml $current)")

    if test -n "$choice"
        cp $themes_dir/$choice.toml $current
        echo "Applied $choice"
    else if test -s $backup
        cp $backup $current
        echo "Cancelled, theme restored"
    end
    rm -f $backup
end
