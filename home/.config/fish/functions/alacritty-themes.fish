# Shadows the alacritty-themes npm CLI, which writes a deprecated top-level `import`.
function alacritty-themes --wraps alacritty-theme --description 'Alias for alacritty-theme'
    alacritty-theme $argv
end
