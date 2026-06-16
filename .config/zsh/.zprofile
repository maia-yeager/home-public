# Don't duplicate work done by z4h and .zshrc.
if [[ ! -o interactive ]] {
  source ${XDG_CONFIG_HOME:-$HOME/.config}/env/-login
  # Re-source _xdg to process $PATH changes from -login
  source ${XDG_CONFIG_HOME:-$HOME/.config}/env/-xdg
  for i ($XDG_CONFIG_HOME/env/[^-]*(^D)) source $i
}
