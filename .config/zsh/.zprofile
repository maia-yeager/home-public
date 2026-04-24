# Only load Homebrew environment if not an interactive shell (e.g. Sublime Merge).
[[ ! -o interactive ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
