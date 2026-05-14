# Don't duplicate work done by z4h and .zshrc.
if [[ ! -o interactive ]]; then
  source ${XDG_CONFIG_HOME:-$HOME/.config}/env.d/_login
  # Re-source _xdg to process $PATH changes from _login
  source ${XDG_CONFIG_HOME:-$HOME/.config}/env.d/_xdg
  source $XDG_CONFIG_HOME/env.d/[^_.]*(N)
fi
