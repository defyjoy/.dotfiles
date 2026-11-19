function cursor-theme --description 'Pick a cursor theme with live preview (niri + GTK + XWayland)'
    set -l niri_cfg ~/.config/niri/cfg/misc.kdl

    # Internal: apply one theme everywhere. Niri reloads its config live,
    # so this doubles as the preview while browsing.
    if test "$argv[1]" = --apply
        set -l name $argv[2]
        sed -i "s|xcursor-theme \".*\"|xcursor-theme \"$name\"|" $niri_cfg
        gsettings set org.gnome.desktop.interface cursor-theme $name
        mkdir -p ~/.icons/default
        printf '[Icon Theme]\nInherits=%s\n' $name >~/.icons/default/index.theme
        return 0
    end

    # Optional size: cursor-theme --size 32
    if test "$argv[1]" = --size
        sed -i "s|xcursor-size [0-9]*|xcursor-size $argv[2]|" $niri_cfg
        gsettings set org.gnome.desktop.interface cursor-size $argv[2]
        echo "Cursor size set to $argv[2]"
        return 0
    end

    # Every installed theme that actually ships cursors.
    set -l themes
    for d in /usr/share/icons/*/cursors ~/.local/share/icons/*/cursors ~/.icons/*/cursors
        test -d $d; and set -a themes (path basename (path dirname $d))
    end
    set themes (printf '%s\n' $themes | sort -u)

    set -l current (string match -rg 'xcursor-theme "(.*)"' <$niri_cfg)

    if set -q argv[1]
        if not contains -- $argv[1] $themes
            echo "No cursor theme named '$argv[1]'. Run 'cursor-theme' to browse." >&2
            return 1
        end
        cursor-theme --apply $argv[1]
        echo "Applied $argv[1]"
        return 0
    end

    set -l choice (printf '%s\n' $themes | \
        fzf --prompt='Cursor> ' --height=60% --reverse \
            --header="Current: $current · ↑/↓ previews live · Enter applies · Esc cancels" \
            --bind "focus:execute-silent(fish -c 'cursor-theme --apply {}')")

    if test -n "$choice"
        cursor-theme --apply $choice
        echo "Applied $choice (restart open apps to pick it up)"
    else if test -n "$current"
        cursor-theme --apply $current
        echo "Cancelled, restored $current"
    end
end
