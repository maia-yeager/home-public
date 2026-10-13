. "${XDG_CONFIG_HOME:-$HOME/.config}"/env/-init
. "${XDG_CONFIG_HOME:-$HOME/.config}"/env/-homebrew
. "${XDG_CONFIG_HOME:-$HOME/.config}"/env/[!-.]* 2>/dev/null

export BASH_SILENCE_DEPRECATION_WARNING=1 # macOS >= 10.15 (Catalina)

eval "$(mise activate bash)"
