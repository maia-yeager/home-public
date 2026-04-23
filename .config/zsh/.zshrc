# Personal Zsh configuration file. It is strongly recommended to keep all
# shell customization and configuration (including exported environment
# variables such as PATH) in this file or in files sourced from it.
#
# Documentation: https://github.com/romkatv/zsh4humans/blob/v5/README.md.

# Wrap in self-executing function for easy locals cleanup.
() {

# Lifted variables that are required for zstyle configuration commands.
export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=1

local xdg_config_home='~/.config' # Quote to prevent in-place expansion.

local extra_env=$xdg_config_home/.env.zsh
local npm_config_userconfig=$xdg_config_home/npm/rc
local screenrc=$xdg_config_home/screen/rc
local tmux_config=$xdg_config_home/tmux/tmux.conf

# If you are using a two-line prompt with an empty line before it, add this
# for smoother rendering:
POSTEDIT=$'\n\n\e[2A'

# Periodic auto-update on Zsh startup: 'ask' or 'no'.
# You can manually run `z4h update` to update everything.
zstyle ':z4h:' auto-update      'ask'
# Ask whether to auto-update this often; has no effect if auto-update is 'no'.
zstyle ':z4h:' auto-update-days '28'

# Keyboard type: 'mac' or 'pc'.
zstyle ':z4h:bindkey' keyboard  'mac'

# Start tmux if appropriate.
local sock
if [[ -n "$TMUX_TMPDIR" && -d "$TMUX_TMPDIR" && -w "$TMUX_TMPDIR" ]]; then
  sock=$TMUX_TMPDIR
elif [[ -d /tmp && -w /tmp ]]; then
  sock=/tmp
elif [[ -n "$TMPDIR" && -d "$TMPDIR" && -w "$TMPDIR" ]]; then
  sock=$TMPDIR
fi
if ! type tmux &> /dev/null || [[
  -z "$sock"
  || -z "${Z4H_SSH}" # SSH tmux within local tmux isn't a great experience.
  || "$TERM_PROGRAM" == "tmux"
  || "$TERMINAL_EMULATOR" == "JetBrains-JediTerm"
]]; then
  zstyle ':z4h:' start-tmux 'no'
else
  sock=${sock%/}/z4h-tmux-$UID-$TERM
  local tmux_args=(-uf "${tmux_config/#\~/$HOME}")
  local -a tmux_cmds=()
  # Enable iTerm tmux integration. Don't use LC_TERMINAL.
  [[ "$LC_TERMINAL" == "iTerm2" ]] && tmux_args+=(-CC)

  # Below adapted from Z4H built-in tmux logic.
  # Specify supported terminal colours and features.
  if (( terminfo[colors] >= 256 )); then
    tmux_cmds+=(set -g default-terminal tmux-256color ';')
    if [[ $COLORTERM = *(24bit|truecolor)* ]]; then
      tmux_cmds+=(set -ga terminal-features ',*:RGB:usstyle:overline' ';')
      sock+='-tc'
    fi
  else
    tmux_cmds+=(set -g default-terminal screen ';')
  fi
  # Append a unique per-installation number to the socket path to work
  # around a bug in tmux. See https://github.com/romkatv/zsh4humans/issues/71.
  if [[ -e $Z4H/tmux/stamp ]]; then
    local stamp
    IFS= read -r stamp < $Z4H/tmux/stamp || return
    sock+=-${stamp%%.*}
  fi
  tmux_args+=(-S "$sock")

  zstyle ':z4h:' start-tmux command tmux $tmux_args -- "${tmux_cmds[@]}" new -As main
fi

# Whether to move prompt to the bottom when zsh starts and on Ctrl+L.
zstyle ':z4h:' prompt-at-bottom 'no'

# Mark up shell's output with semantic information.
zstyle ':z4h:' term-shell-integration 'yes'

# Right-arrow key accepts one character ('partial-accept') from
# command autosuggestions or the whole thing ('accept')?
zstyle ':z4h:autosuggestions' forward-char 'accept'

# Recursively traverse directories when TAB-completing files.
zstyle ':z4h:fzf-complete' recurse-dirs 'yes'
# Rebind `Tab` in fzf from `up` to `repeat`
zstyle ':z4h:fzf-complete' fzf-bindings tab:repeat

# Enable direnv to automatically source .envrc files.
zstyle ':z4h:direnv' enable 'no'

# Enable ('yes') or disable ('no') automatic teleportation of z4h over
# Defer to custom implementation.
zstyle ':z4h:ssh:*'                    enable 'yes'
# Determine using :my:z4h:ssh:<user>:<host> settings.
zstyle ':my:z4h:ssh:maia*:*:*'            enable 'yes'
zstyle ':my:z4h:ssh:*yeager:*:*'          enable 'yes'
zstyle ':my:z4h:ssh:*:*.am.yeagers.co:22' enable 'yes'
zstyle ':my:z4h:ssh:*:*:*'                enable 'no'

# Copy these environment variables over to the remote host.
zstyle ':my:z4h:ssh:*:*' send-vars-prefix LC_MY_Z4H_
zstyle ':my:z4h:ssh:*:*' send-vars        COLORTERM

# Explicitly set the default command, so Z4H doesn't override settings
# from .ssh/config
# https://github.com/romkatv/zsh4humans/blob/cd6c4770c802c3a17b4c43e5587adabb9a370a75/fn/-z4h-cmd-ssh#L81-L84
zstyle ':z4h:ssh:*' ssh-command command ssh

# Send these files over to the remote host when connecting over SSH to the
# enabled hosts.
local ssh_dir='~/.ssh'
local -a ssh_extra_files=(
  $extra_env
  $npm_config_userconfig
  $screenrc
  $ssh_dir/allowed_signers
  $ssh_dir/conf.d
  $ssh_dir/config
  $tmux_config
  $xdg_config_home/nano
)
zstyle ':z4h:ssh:*' send-extra-files $ssh_extra_files

zstyle ':completion:*:ssh:argument-1:'       tag-order  hosts users
zstyle ':completion:*:scp:argument-rest:'    tag-order  hosts files users
zstyle ':completion:*:(ssh|scp|rdp):*:hosts' hosts

# Tip: Replace %m with ${${${Z4H_SSH##*:}//\%/%%}:-%m}. This makes a difference
# when using SSH teleportation: the title will show the hostname as you typed
# it on the command line when connecting rather than the hostname reported by
# the remote machine.
zstyle ':z4h:term-title:ssh' preexec '􀤆 %n@'${${${Z4H_SSH##*:}//\%/%%}:-%m}': ${1//\%/%%}'
zstyle ':z4h:term-title:ssh' precmd  '􀤆 %n@'${${${Z4H_SSH##*:}//\%/%%}:-%m}': %~'

# Clone additional Git repositories from GitHub.
#
# This doesn't do anything apart from cloning the repository and keeping it
# up-to-date. Cloned files can be used after `z4h init`. This is just an
# example. If you don't plan to use Oh My Zsh, delete this line.
# z4h install ohmyzsh/ohmyzsh || return

# Install or update core components (fzf, zsh-autosuggestions, etc.) and
# initialize Zsh. After this point console I/O is unavailable until Zsh
# is fully initialized. Everything that requires user interaction or can
# perform network I/O must be done above. Everything else is best done below.
z4h init || return

# Export environment variables.
export XDG_CONFIG_HOME=${xdg_config_home/#\~/$HOME}
export GPG_TTY=$TTY
export HOMEBREW_NO_ENV_HINTS=1
export LESS='--ignore-case --quit-if-one-screen --LONG-PROMPT --RAW-CONTROL-CHARS --HILITE-UNREAD --tabs=4 --window=-4'
export MANPAGER='less +Gg' # Show scroll progress in man pages.
export NPM_CONFIG_USERCONFIG=${npm_config_userconfig/#\~/$HOME}
export SCREENRC=${screenrc/#\~/$HOME}

# Extend PATH.
path=(
  $HOME/bin
  $HOME/.local/bin
  $path
  $HOMEBREW_PREFIX/opt/libpq/bin # After $path, to defer to any installed Postgres.
)
local zsh_site_fns=$XDG_CONFIG_HOME/zsh/site-functions
fpath=(
  $zsh_site_fns
  $fpath
)

# Source additional local files if they exist.
z4h source ${extra_env/#\~/$HOME}

# This function is invoked by zsh4humans on every ssh command after
# the instructions from ssh-related zstyles have been applied. It allows
# us to configure ssh teleportation in ways that cannot be done with
# zstyles.
#
# Within this function we have readonly access to the following parameters:
#
# - z4h_ssh_client  local hostname
# - z4h_ssh_host    remote hostname as it was specified on the command line
#
# We also have read & write access to these:
#
# - z4h_ssh_enable          1 to use ssh teleportation, 0 for plain ssh
# - z4h_ssh_send_files      list of files to send to the remote; keys are local
#                           file names, values are remote file names
# - z4h_ssh_retrieve_files  the same as z4h_ssh_send_files but for pulling
#                           files from remote to local
# - z4h_retrieve_history    list of local files into which remote $HISTFILE
#                           should be merged at the end of the connection
# - z4h_ssh_command         command to use instead of `ssh`
z4h-ssh-configure() {
  emulate -L zsh

  # Link SSH_AUTH_SOCK to common location.
  z4h_ssh_prelude+=(
    'my_z4h_ssh_auth_sock="$HOME/.ssh/agent.sock"'
    '
    if test -e "$SSH_AUTH_SOCK"; then
      ln -sf "$SSH_AUTH_SOCK" "$my_z4h_ssh_auth_sock"
      export SSH_AUTH_SOCK="$my_z4h_ssh_auth_sock"
    else
      rm -f "$my_z4h_ssh_auth_sock"
    fi
    '
    'unset my_z4h_ssh_auth_sock'
  )

  # Extend possible SSH teleportation to config based on user@host:port zstyles.
  local my_z4h_ssh_user my_z4h_ssh_host my_z4h_ssh_port
  if [[ -n $user_host ]]; then
    local ssh_config=$(command ssh $user_host -G)
    my_z4h_ssh_user=$(awk '$1 == tolower("User") {print $2}' <<< $ssh_config)
    # Get the finalized hostname, falling back to original host.
    my_z4h_ssh_host=${$(awk '$1 == tolower("Hostname") {print $2}' <<< $ssh_config):-$z4h_ssh_host}
    my_z4h_ssh_port=$(awk '$1 == tolower("Port") {print $2}' <<< $ssh_config)
  fi
  local -r my_z4h_ssh_user my_z4h_ssh_host my_z4h_ssh_port
  local -r zstyle_namespace=:my:z4h:ssh:$my_z4h_ssh_user:$my_z4h_ssh_host:$my_z4h_ssh_port

  # Copy environment variables, if prefix exists.
  local ssh_vars_prefix
  if zstyle -s ${zstyle_namespace} send-vars-prefix ssh_vars_prefix; then
    local -a ssh_vars=()
    if zstyle -a ${zstyle_namespace} send-vars ssh_vars; then
      for ssh_var in $ssh_vars; do
        local ssh_send_var=$ssh_vars_prefix$ssh_var
        z4h_ssh_prelude+=("export $ssh_var=\$$ssh_send_var")
        z4h_ssh_command+=("-o SetEnv='$ssh_send_var=${(P)ssh_var}'")
      done
      z4h_ssh_run+=("unset -m '$ssh_vars_prefix*'")
    fi
  fi

  # Enable or disable SSH teleportation based on custom config.
  zstyle -t ${zstyle_namespace} enable || z4h_ssh_enable=0
}

# Application configuration.
if [[ -z "${Z4H_SSH}" ]]; then
  # Link the local SSH authentication socket.
  local ssh_auth_sock
  if [[ "$(uname)" == "Darwin" ]]; then
    ssh_auth_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  else
    ssh_auth_sock=${HOME}/.1password/agent.sock
  fi
  if [[ -e "$ssh_auth_sock" ]]; then
    export SSH_AUTH_SOCK=${HOME}/.ssh/agent.sock
    ln -sf ${ssh_auth_sock} ${SSH_AUTH_SOCK}
  fi
fi
# Set editor in order of preference based on what's available.
if type nano &> /dev/null; then
  export EDITOR=nano
elif type pico &> /dev/null; then
  export EDITOR=pico
elif type vim &> /dev/null; then
  export EDITOR=vim
elif type vi &> /dev/null; then
  export EDITOR=vi
fi

# Use additional Git repositories pulled in with `z4h install`.
#
# This is just an example that you should delete. It does nothing useful.
# z4h source ohmyzsh/ohmyzsh/lib/diagnostics.zsh  # source an individual file
# z4h load   ohmyzsh/ohmyzsh/plugins/emoji-clock  # load a plugin

# Autoload functions.
autoload -Uz -- zmv ${zsh_site_fns}/[^_]*(N:t)
[[ $COLORTERM = *(24bit|truecolor)* ]] || zmodload zsh/nearcolor

# Define key bindings.
z4h bindkey     z4h-eof                 Ctrl+D              # help make transient prompt behave consistently from SSH
z4h bindkey     undo                    Ctrl+/ Shift+Tab    # undo the last command line change
z4h bindkey     redo                    Option+/            # redo the last undone command line change

z4h bindkey     z4h-cd-back             Shift+Left          # cd into the previous directory
z4h bindkey     z4h-cd-forward          Shift+Right         # cd into the next directory
z4h bindkey     z4h-cd-up               Shift+Up            # cd into the parent directory
z4h bindkey     z4h-cd-down             Shift+Down          # cd into a child directory
if (( $+functions[toggle-home-git-repo] )); then
  zle -N toggle-home-git-repo
  z4h bindkey toggle-home-git-repo    Ctrl+P              # cycle home git repository
fi

# Define functions and completions.
# List terminal colour codes.
function colours {
  for i in {0..255}; do
    print -Pn "%K{$i}  %k%F{$i} ${(l:3::0:)i}%f   " ${${(M)$((i%6)):#3}:+$'\n'}
  done
}

# Free up an in-use port.
function free-port {
    readonly port=${1:?"Please specify a port"}
    kill $(lsof -i tcp:"$port" | grep LISTEN | awk '{print $2}')
}

if type ffmpeg &> /dev/null; then
  function dv { discord-video $@ }
  compdef _files discord-video dv
fi

# Make directory and switch to it.
function md { [[ $# == 1 ]] && mkdir -p -- ${1} && cd -- ${1} }
compdef _directories md

# ls "aliases" with completions.
if type eza &> /dev/null; then
    function ll { eza -l -g --icons $@ }
    function ls { eza --icons $@ }
    function la { eza -a --icons $@ }
    function lt { eza --tree --icons -a -I '.git|__pycache__|.mypy_cache|.ipynb_checkpoints' }
    compdef _eza ll ls la lt
fi

# Define named directories: ~w <=> Windows home directory on WSL.
[[ -n $z4h_win_home ]] && hash -d w=$z4h_win_home

# Define aliases.
alias colors="colours"
alias fp="free-port"

alias diff="${aliases[diff]:-diff} --color=auto -u"
type say &> /dev/null && alias say="${aliases[say]:-say} --interactive"
type tree &> /dev/null && alias tree="${aliases[tree]:-tree} -aI .git"

}

# Set shell options: http://zsh.sourceforge.net/Doc/Release/Options.html.
setopt extended_glob # make additional glob options available
setopt glob_dots     # no special treatment for file names with a leading dot
setopt ignore_eof    # help make transient prompt behave consistently from SSH
setopt no_auto_menu  # require an extra TAB press to open the completion menu
