# Personal Zsh configuration file. It is strongly recommended to keep all
# shell customization and configuration (including exported environment
# variables such as PATH) in this file or in files sourced from it.
#
# Documentation: https://github.com/romkatv/zsh4humans/blob/v5/README.md.

# Lifted variables that are required for zstyle configuration commands.
export SCREENRC="~/.config/screen/screenrc"

# Tip: Replace %m with ${${${Z4H_SSH##*:}//\%/%%}:-%m}. This makes a difference
# when using SSH teleportation: the title will show the hostname as you typed
# it on the command line when connecting rather than the hostname reported by
# the remote machine.
zstyle ':z4h:term-title:ssh' preexec '%n@'${${${Z4H_SSH##*:}//\%/%%}:-%m}': ${1//\%/%%}'
zstyle ':z4h:term-title:ssh' precmd  '%n@'${${${Z4H_SSH##*:}//\%/%%}:-%m}': %~'

# Periodic auto-update on Zsh startup: 'ask' or 'no'.
# You can manually run `z4h update` to update everything.
zstyle ':z4h:' auto-update      'ask'
# Ask whether to auto-update this often; has no effect if auto-update is 'no'.
zstyle ':z4h:' auto-update-days '28'

# Keyboard type: 'mac' or 'pc'.
zstyle ':z4h:bindkey' keyboard  'mac'

# Start tmux if not already in tmux.
if [[ -n ${SSH_TTY} ]]; then
    # zstyle ':z4h:' start-tmux command tmux -CC -u new -A -D -t main
    zstyle ':z4h:' start-tmux command tmux -u new -A -D -t main
else
    zstyle ':z4h:' start-tmux no
fi

# Whether to move prompt to the bottom when zsh starts and on Ctrl+L.
zstyle ':z4h:' prompt-at-bottom 'no'

# Mark up shell's output with semantic information.
[ -n "$TMUX" ] || zstyle ':z4h:' term-shell-integration 'yes'

# Right-arrow key accepts one character ('partial-accept') from
# command autosuggestions or the whole thing ('accept')?
zstyle ':z4h:autosuggestions' forward-char 'accept'

# Recursively traverse directories when TAB-completing files.
zstyle ':z4h:fzf-complete' recurse-dirs 'yes'
# Rebind `Tab` in fzf from `up` to `repeat`
zstyle ':z4h:fzf-complete' fzf-bindings tab:repeat

# Enable direnv to automatically source .envrc files.
zstyle ':z4h:direnv'         enable 'no'
# Show "loading" and "unloading" notifications from direnv.
zstyle ':z4h:direnv:success' notify 'yes'

# Enable ('yes') or disable ('no') automatic teleportation of z4h over
# SSH when connecting to these hosts.
zstyle ':z4h:ssh:sd-wan*'   enable 'no'
zstyle ':z4h:ssh:*.example-hostname2' enable 'no'
# The default value if none of the overrides above match the hostname.
zstyle ':z4h:ssh:*'                   enable 'yes'

# Send these files over to the remote host when connecting over SSH to the
# enabled hosts.
zstyle ':z4h:ssh:*' send-extra-files '~/.config/nano/nanorc' '~/.tmux.conf' "$SCREENRC"
zstyle ':completion:*:ssh:argument-1:'       tag-order  hosts users
zstyle ':completion:*:scp:argument-rest:'    tag-order  hosts files users
zstyle ':completion:*:(ssh|scp|rdp):*:hosts' hosts

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
export GPG_TTY=$TTY
export EDITOR=nano
export LESS='--ignore-case --quit-if-one-screen --LONG-PROMPT --RAW-CONTROL-CHARS --HILITE-UNREAD --tabs=4 --window=-4'

export BUN_INSTALL="~/.bun"
export PNPM_HOME="~/Library/pnpm"

# If you are using a two-line prompt with an empty line before it, add this
# for smoother rendering:
POSTEDIT=$'\n\n\e[2A'

# Extend PATH.
path=(
    ~/bin
    $BUN_INSTALL/bin
    $HOMEBREW_PREFIX/opt/libpq/bin
    $PNPM_HOME
    $path
    ~/.local/bin
)
fpath=(
    ~/.zsh/site-functions
    $fpath
)

# Source additional local files if they exist.
z4h source ~/.env.zsh

# Use additional Git repositories pulled in with `z4h install`.
#
# This is just an example that you should delete. It does nothing useful.
# z4h source ohmyzsh/ohmyzsh/lib/diagnostics.zsh  # source an individual file
# z4h load   ohmyzsh/ohmyzsh/plugins/emoji-clock  # load a plugin

# Autoload functions.
autoload -Uz -- zmv ~/.zsh/site-functions/[^_]*(N:t)

# Define key bindings.
z4h bindkey z4h-eof Ctrl+D
z4h bindkey undo Ctrl+/   Shift+Tab  # undo the last command line change
z4h bindkey redo Option+/            # redo the last undone command line change

z4h bindkey z4h-cd-back    Shift+Left   # cd into the previous directory
z4h bindkey z4h-cd-forward Shift+Right  # cd into the next directory
z4h bindkey z4h-cd-up      Shift+Up     # cd into the parent directory
z4h bindkey z4h-cd-down    Shift+Down   # cd into a child directory

if (( $+functions[toggle-home-git-repo] )); then
    zle -N toggle-home-git-repo
    bindkey '^P' toggle-home-git-repo
fi

# Define functions and completions.
# bun completions
[ -s "~/.bun/_bun" ] && source "~/.bun/_bun"

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

function dv { discord-video $@ }
compdef _files discord-video dv

# Make directory and switch to it.
function md { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }
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
[[ -z $z4h_win_home ]] || hash -d w=$z4h_win_home

# Define aliases.
alias colors="colours"
alias fp="free-port"

# Add flags to existing aliases.
alias diff="${aliases[diff]:-diff} --color=auto -u"
alias say="${aliases[say]:-say} --interactive"
alias tree='${aliases[tree]:-tree} -a -I .git'

# Set shell options: http://zsh.sourceforge.net/Doc/Release/Options.html.
setopt glob_dots     # no special treatment for file names with a leading dot
setopt no_auto_menu  # require an extra TAB press to open the completion menu
[ -n "$TMUX" ] && setopt ignore_eof || true # ignore EOF if in tmux
