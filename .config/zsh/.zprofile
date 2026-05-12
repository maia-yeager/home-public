() {

# Only load if not an interactive shell (e.g. Sublime Merge).
if [[ ! -o interactive ]]; then
  local brew_path=/opt/homebrew/bin/brew
  [[ -f $brew_path ]] && eval "$($brew_path shellenv)"

  [[ -f $XDG_CONFIG_HOME/env.d/ssh.zsh ]] &&
    source $XDG_CONFIG_HOME/env.d/ssh.zsh
fi

}
