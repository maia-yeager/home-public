# Personal Zsh configuration file. It is strongly recommended to keep all
# shell customization and configuration (including exported environment
# variables such as PATH) in this file or in files sourced from it.
#
# Documentation: https://github.com/romkatv/zsh4humans/blob/v5/README.md.

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
() {
  local sock
  if [[ -n $TMUX_TMPDIR && -d $TMUX_TMPDIR && -w $TMUX_TMPDIR ]] {
    sock=$TMUX_TMPDIR
  } elif [[ -n $XDG_RUNTIME_DIR && -d $XDG_RUNTIME_DIR && -w $XDG_RUNTIME_DIR ]] {
    sock=$XDG_RUNTIME_DIR
  } elif [[ -n $TMPDIR && -d $TMPDIR && -w $TMPDIR ]] {
    sock=$TMPDIR
  } elif [[ -d /tmp && -w /tmp ]] {
    sock=/tmp
  }
  if ! command -v tmux &>/dev/null || [[
    -z $sock
    || -z $Z4H_SSH # SSH tmux within local tmux isn't a great experience.
    || $TERM_PROGRAM == tmux
    || $TERMINAL_EMULATOR = JetBrains*
  ]] {
    zstyle ':z4h:' start-tmux 'no'
  } else {
    sock=${sock%/}/z4h-tmux-$UID-$TERM
    local tmux_args=(-uf $TMUX_CONFIG)
    local -a tmux_cmds
    # Enable iTerm tmux integration.
    [[ $LC_TERMINAL == iTerm2 ]] && tmux_args+=(-CC)

    # Below adapted from Z4H built-in tmux logic.
    # Specify supported terminal colours and features.
    if (( terminfo[colors] >= 256 )) {
      tmux_cmds+=(set -g default-terminal tmux-256color ';')
      if [[ $COLORTERM = *(24bit|truecolor)* ]]; then
        tmux_cmds+=(set -ga terminal-features ',*:RGB:usstyle:overline' ';')
        sock+='-tc'
      fi
    } else {
      tmux_cmds+=(set -g default-terminal screen ';')
    }
    # Append a unique per-installation number to the socket path to work
    # around a bug in tmux. See https://github.com/romkatv/zsh4humans/issues/71.
    if [[ -e $Z4H/tmux/stamp ]] {
      local stamp
      IFS= read -r stamp < $Z4H/tmux/stamp || return
      sock+=-${stamp%%.*}
    }
    tmux_args+=(-S $sock)

    zstyle ':z4h:' start-tmux command tmux $tmux_args -- "${tmux_cmds[@]}" new -As main
  }
}

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

# Explicitly set the default SSH command, so Z4H doesn't override settings
# from '.ssh/config'.
# https://github.com/romkatv/zsh4humans/blob/cd6c4770c802c3a17b4c43e5587adabb9a370a75/fn/-z4h-cmd-ssh#L81-L84
zstyle ':z4h:ssh:*'             ssh-command command ssh
# Enable ('yes') or disable ('no') automatic teleportation of z4h over
# Defer to custom implementation.
zstyle ':z4h:ssh:*'             enable      'yes'
# Determine using :my:z4h:ssh:<user>:<host>:<port> settings.
zstyle ':my:z4h:ssh:maia*:*'    enable      'yes'
zstyle ':my:z4h:ssh:*yeager:*'  enable      'yes'
zstyle ':my:z4h:ssh:*'          enable      'no'
# Copy these environment variables over to the remote host. Always sent
# regardless of whether automatic teleportation is enabled for a host.
zstyle ':my:z4h:ssh:*'          send-vars   COLORTERM
() {
  # Send these files over to the remote host when connecting over SSH to the
  # enabled hosts.
  local -aU ssh_global_extra_files=(
    $HOME/.hushlogin
    $HOME/.profile
    $HOME/.ssh/allowed_signers
    $HOME/.ssh/config
    $HOME/.zshenv
    $NPM_CONFIG_USERCONFIG
    $SCREENRC
    $TMUX_CONFIG
    $XDG_CONFIG_HOME/env.d
    $XDG_CONFIG_HOME/git/config
    $XDG_CONFIG_HOME/git/ignore
    $XDG_CONFIG_HOME/glow
    $XDG_CONFIG_HOME/homebrew
    $XDG_CONFIG_HOME/htop
    $XDG_CONFIG_HOME/mise
    $XDG_CONFIG_HOME/nano
    $XDG_CONFIG_HOME/python
    $XDG_CONFIG_HOME/vim
    $XDG_CONFIG_HOME/zsh/fn
    $XDG_CONFIG_HOME/zsh/zle/^local.*
    $XDG_CONFIG_HOME/zsh-abbr
  )
  zstyle ':my:z4h:ssh:*'                send-extra-files $ssh_global_extra_files
  local -aU ssh_home_extra_files=(
    $ssh_global_extra_files
    $HOME/.ssh/conf.d/home
  )
  zstyle ':my:z4h:ssh:*.am.yeagers.co'  send-extra-files $ssh_home_extra_files
}

zstyle ':completion:*:ssh:argument-1:'       tag-order  hosts users
zstyle ':completion:*:scp:argument-rest:'    tag-order  hosts files users
zstyle ':completion:*:(ssh|scp|rdp):*:hosts' hosts

# Tip: Replace %m with ${${${Z4H_SSH##*:}//\%/%%}:-%m}. This makes a difference
# when using SSH teleportation: the title will show the hostname as you typed
# it on the command line when connecting rather than the hostname reported by
# the remote machine.
zstyle ':z4h:term-title:ssh' preexec '􀤆 %n@'${${${Z4H_SSH##*:}//\%/%%}:-%m}': ${1//\%/%%}'
zstyle ':z4h:term-title:ssh' precmd  '􀤆 %n@'${${${Z4H_SSH##*:}//\%/%%}:-%m}': %~'

# Plugin manager configuration. Used for recursively cloning Git repositories.
autoload -Uz -- $XDG_CONFIG_HOME/zsh/fn/-z4h-postinstall-zcomet
zstyle ':z4h:agkozak/zcomet'  postinstall '-z4h-postinstall-zcomet'
zstyle ':zcomet:*'            home-dir    $XDG_CACHE_HOME/zcomet
zstyle ':my:zcomet:'          repos       olets/zsh-abbr

# Clone additional Git repositories from GitHub.
#
# This doesn't do anything apart from cloning the repository and keeping it
# up-to-date. Cloned files can be used after `z4h init`.
z4h install agkozak/zcomet || return
z4h install olets/zsh-autosuggestions-abbreviations-strategy || return

# Install or update core components (fzf, zsh-autosuggestions, etc.) and
# initialize Zsh. After this point console I/O is unavailable until Zsh
# is fully initialized. Everything that requires user interaction or can
# perform network I/O must be done above. Everything else is best done below.
z4h init || return

# Environment variables targeting ZSH.
path=(
  $HOME/bin
  $HOME/.local/bin
  $HOME/Library/"Application Support"/JetBrains/Toolbox/scripts
  $HOMEBREW_PREFIX/opt/gawk/libexec/gnubin # Not linked by default.
  $HOMEBREW_PREFIX/opt/ffmpeg-full/bin # Not linked by default.
  $HOMEBREW_PREFIX/opt/rustup/bin # Before $path, in case rust is already installed.
  $path
  $HOMEBREW_PREFIX/opt/libpq/bin # After $path, to defer to any installed Postgres.
)
fpath=(
  $XDG_CONFIG_HOME/zsh/fn
  $XDG_CONFIG_HOME/zsh/zle
  $fpath
)
ABBR_EXPANSION_CURSOR_MARKER='…'
ABBR_LINE_CURSOR_MARKER=$ABBR_EXPANSION_CURSOR_MARKER
ABBR_REGULAR_ABBREVIATION_GLOB_PREFIXES+=( '* -- ' )
ABBR_REGULAR_ABBREVIATION_SCALAR_PREFIXES+=( ' ' )
ABBR_SET_EXPANSION_CURSOR=1
ABBR_SET_LINE_CURSOR=1
ZSH_AUTOSUGGEST_STRATEGY=( abbreviations $ZSH_AUTOSUGGEST_STRATEGY )

# Load modules.
[[ $COLORTERM = *(24bit|truecolor)* ]] || zmodload zsh/nearcolor

# Autoload functions.
autoload -Uz -- -init-fn -init-zle age zmv
-init-fn
-init-zle

# Source scripts and load plugins.
z4h source $XDG_CONFIG_HOME/env.d/[^_.]*(N)
init-zcomet
z4h load olets/zsh-autosuggestions-abbreviations-strategy
command -v mise &>/dev/null && eval "$(mise activate zsh)" &>/dev/null

# Define key bindings.
z4h bindkey   z4h-eof                     Ctrl+D            # help make transient prompt behave consistently from SSH
z4h bindkey   undo                        Ctrl+/ Shift+Tab  # undo the last command line change
z4h bindkey   redo                        Option+/          # redo the last undone command line change

z4h bindkey   z4h-cd-back                 Shift+Left        # cd into the previous directory
z4h bindkey   z4h-cd-forward              Shift+Right       # cd into the next directory
z4h bindkey   z4h-cd-up                   Shift+Up          # cd into the parent directory
z4h bindkey   z4h-cd-down                 Shift+Down        # cd into a child directory

if [[ -z $Z4H_SSH ]] {
  z4h bindkey local.toggle-home-git-repo  Ctrl+P            # cycle home git repository
}
z4h bindkey   rationalize-dot             .

# Define functions and completions.
command -v discord-video &>/dev/null && compdef _files discord-video
# List terminal colour codes.
function colors {
  for i ({0..255}) {
    print -Pn "%K{$i}  %k%F{$i} ${(l:3::0:)i}%f   " ${${(M)$((i%6)):#3}:+$'\n'}
  }
}
# Make directory and switch to it.
function md { [[ $# == 1 ]] && mkdir -p -- ${1} && cd -- ${1} }
compdef _directories md

# Define named directories: ~w <=> Windows home directory on WSL.
[[ -n $z4h_win_home ]] && hash -d w=$z4h_win_home

# Define aliases.
alias clear="z4h-clear-screen-soft-top"
alias diff="${aliases[diff]:-diff} --color=auto"
if command -v eza &>/dev/null; then
  alias eza="${aliases[eza]:-eza} --icons"
  function la { eza -1aaglo $@ }
  function ll { eza -1glo $@ }
  function ls { eza $@ }
  compdef _eza la ll ls
else
  function la { ls -al $@ }
  function ll { ls -l $@ }
  compdef _ls la ll
fi
if command -v htop &>/dev/null; then
  function top { htop $@ }
  compdef _htop top
fi
command -v rlwrap &>/dev/null && for com (dash nc) {
  command -v $com &>/dev/null &&
    alias $com="${aliases[rlwrap]:-rlwrap} -Atdumb $com"
}
if command -v tree &>/dev/null; then
  alias tree="${aliases[tree]:-tree} -I .DS_Store"
  function lt { tree -a --gitignore --metafirst --noreport $@ }
  compdef _tree lt
fi

# Set shell options: http://zsh.sourceforge.net/Doc/Release/Options.html.
setopt glob_dots     # no special treatment for file names with a leading dot
setopt ignore_eof    # help make transient prompt behave consistently from SSH
setopt no_auto_menu  # require an extra TAB press to open the completion menu
