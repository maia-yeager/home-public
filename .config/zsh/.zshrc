# Personal Zsh configuration file. It is strongly recommended to keep all
# shell customization and configuration (including exported environment
# variables such as PATH) in this file or in files sourced from it.
#
# Documentation: https://github.com/romkatv/zsh4humans/blob/v5/README.md.

# Wrap in self-executing function for easy locals cleanup.
() {

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
  local -a tmux_cmds=()
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
zstyle ':z4h:ssh:*'                       enable 'yes'
# Determine using :my:z4h:ssh:<user>:<host>:<port> settings.
zstyle ':my:z4h:ssh:maia*:*'              enable 'yes'
zstyle ':my:z4h:ssh:*yeager:*'            enable 'yes'
zstyle ':my:z4h:ssh:*:*.am.yeagers.co:22' enable 'yes'
zstyle ':my:z4h:ssh:*'                    enable 'no'

# Copy these environment variables over to the remote host.
zstyle ':my:z4h:ssh:*' send-vars        COLORTERM

# Explicitly set the default command, so Z4H doesn't override settings
# from .ssh/config
# https://github.com/romkatv/zsh4humans/blob/cd6c4770c802c3a17b4c43e5587adabb9a370a75/fn/-z4h-cmd-ssh#L81-L84
zstyle ':z4h:ssh:*' ssh-command command ssh

# Send these files over to the remote host when connecting over SSH to the
# enabled hosts.
local -aU ssh_global_extra_files=(
  $HOME/.profile
  $HOME/.ssh/allowed_signers
  $HOME/.ssh/config
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
  $XDG_CONFIG_HOME/zsh/zle
)
# Ensure that home directory refs start with '~', not $HOME, since the remote
# $HOME path might not match the local $HOME path.
zstyle ':z4h:ssh:*'               send-extra-files ${ssh_global_extra_files/#$HOME/\~}
local -aU ssh_home_extra_files=(
  $ssh_global_extra_files
  $HOME/.ssh/conf.d/home
)
zstyle ':z4h:ssh:*.am.yeagers.co' send-extra-files ${ssh_home_extra_files/#$HOME/\~}

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

}

# Install or update core components (fzf, zsh-autosuggestions, etc.) and
# initialize Zsh. After this point console I/O is unavailable until Zsh
# is fully initialized. Everything that requires user interaction or can
# perform network I/O must be done above. Everything else is best done below.
z4h init || return

# Export environment variables.
# export DO_NOT_TRACK=1

# Extend PATH.
path=(
  $HOME/bin
  $HOME/.local/bin
  $HOME/Library/"Application Support"/JetBrains/Toolbox/scripts
  $HOMEBREW_PREFIX/opt/gawk/libexec/gnubin # Not linked by default.
  $HOMEBREW_PREFIX/opt/ffmpeg-full/bin # Not linked by default.
  $HOMEBREW_PREFIX/opt/rustup/bin # Before $path, in case rust is already installed.
  $path
  $HOMEBREW_PREFIX/opt/libpq/bin # After $path, to defer to any installed Postgres.
  $ANDROID_HOME/emulator
  $ANDROID_HOME/platform-tools
)
fpath=(
  $XDG_CONFIG_HOME/zsh/fn
  $XDG_CONFIG_HOME/zsh/zle
  $fpath
)

# Source additional local files if they exist.
z4h source $XDG_CONFIG_HOME/env.d/[^_.]*(N)

# Application configuration.
command -v mise &>/dev/null && eval "$(mise activate zsh)" &>/dev/null

# Use additional Git repositories pulled in with `z4h install`.
#
# This is just an example that you should delete. It does nothing useful.
# z4h source ohmyzsh/ohmyzsh/lib/diagnostics.zsh  # source an individual file
# z4h load   ohmyzsh/ohmyzsh/plugins/emoji-clock  # load a plugin

# Autoload functions.
autoload -Uz -- -init-zle age z4h-ssh-configure zmv
(( $+functions[-init-zle] )) && -init-zle
[[ $COLORTERM = *(24bit|truecolor)* ]] || zmodload zsh/nearcolor

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
z4h bindkey   rationalize-dot       .

# Define functions and completions.
# List terminal colour codes.
function colours {
  for i ({0..255}) {
    print -Pn "%K{$i}  %k%F{$i} ${(l:3::0:)i}%f   " ${${(M)$((i%6)):#3}:+$'\n'}
  }
}

# Make directory and switch to it.
function md { [[ $# == 1 ]] && mkdir -p -- ${1} && cd -- ${1} }
compdef _directories md

if command -v eza &>/dev/null; then
  function la { ${=aliases[eza]:-eza} --icons -1aaglo $@ }
  function ll { ${=aliases[eza]:-eza} --icons -1glo $@ }
  function ls { ${=aliases[eza]:-eza} --icons $@ }
  compdef _eza la ll ls
else
  function la { ${=aliases[ls]:-ls} -al $@ }
  function ll { ${=aliases[ls]:-ls} -l $@ }
  compdef _ls la ll
fi
if command -v discord-video &>/dev/null; then
  function dv { discord-video $@ }
  compdef _files discord-video dv
fi
if command -v htop &>/dev/null; then
  function top { ${=aliases[htop]:-htop} $@ }
  compdef _htop top
fi
if command -v rsync &>/dev/null; then
  function archive {
    ${=aliases[rsync]:-rsync} -aAUXf "R $RSYNC_PARTIAL_DIR/" --delete-after --partial-dir --info $@
  }
  compdef _rsync archive
fi
if command -v tree &>/dev/null; then
  function lt { ${=aliases[tree]:-tree} --gitignore --metafirst --noreport $@ }
  compdef _tree lt
fi

# Define named directories: ~w <=> Windows home directory on WSL.
[[ -n $z4h_win_home ]] && hash -d w=$z4h_win_home

# Define aliases. If using mixing functions and aliases, use the format
# `${=aliases[eza]:-eza}` to expand the alias like non-zsh shells.
if command -v apfel-run &>/dev/null; then
  alias ai="${aliases[apfel-run]:-apfel-run}"
  alias cmd="${aliases[apfel-run]:-apfel-run} -p cmd"
  alias explain="${aliases[apfel-run]:-apfel-run} -p explain"
fi
alias cat="${aliases[cat]:-cat} -v"
alias clear="z4h-clear-screen-soft-top"
alias colors="colours"
alias diff="${aliases[diff]:-diff} --color=auto -u"
alias fp="free-port"
command -v mise &>/dev/null && alias x="${aliases[mise]:-mise} run"
if command -v rlwrap &>/dev/null; then
  alias rlwrap="${aliases[rlwrap]:-rlwrap} -Atdumb"
  # Add Bash-like keyboard handling.
  for com (dash nc) {
    command -v $com &>/dev/null && alias $com="${aliases[rlwrap]:-rlwrap} $com"
  }
fi
alias root="sudo -Es"
command -v rsync &>/dev/null &&
  alias rsync="${aliases[rsync]:-rsync} -h --info=name0,progress2,stats2 --timeout=60"
command -v say &>/dev/null && alias say="${aliases[say]:-say} --interactive"
command -v tree &>/dev/null && alias tree="${aliases[tree]:-tree} -aI .git"
# Disable globbing for specific commands.
for com (alias expr find mattrib mcopy mdir mdel which) {
  command -v $com &>/dev/null && alias $com="noglob ${aliases[$com]:-$com}"
}

# Set shell options: http://zsh.sourceforge.net/Doc/Release/Options.html.
setopt glob_dots     # no special treatment for file names with a leading dot
setopt ignore_eof    # help make transient prompt behave consistently from SSH
setopt no_auto_menu  # require an extra TAB press to open the completion menu
