# Only load Homebrew environment if not an interactive shell (e.g. Sublime Merge).
if [[ ! -o interactive ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export SSH_AUTH_SOCK=${HOME}/.ssh/agent.sock
fi
