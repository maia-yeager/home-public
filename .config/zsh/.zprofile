# Don't duplicate work done by z4h and .zshrc.
if [[ ! -o interactive ]] {
  source ${XDG_CONFIG_HOME:-$HOME/.config}/env.d/_login
  # Re-source _xdg to process $PATH changes from _login
  source ${XDG_CONFIG_HOME:-$HOME/.config}/env.d/_xdg
  for i ($XDG_CONFIG_HOME/env.d/[^_.]*(N)) source $i
}
