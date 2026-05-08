# Coerce non-conformant apps to use XDG-like file structures.
defaults write org.hammerspoon.Hammerspoon MJConfigFile ${XDG_CONFIG_HOME}/hammerspoon/init.lua
export ANDROID_AVD_HOME=$XDG_DATA_HOME/android/avd
export ANDROID_USER_HOME=$XDG_DATA_HOME/android
export CARGO_HOME=$XDG_DATA_HOME/cargo
export COPILOT_HOME=$XDG_DATA_HOME/copilot
export GNUPGHOME=$XDG_DATA_HOME/gnupg
export GOPATH=$XDG_DATA_HOME/go
export GVIMINIT='let $MYGVIMRC="$XDG_CONFIG_HOME/vim/gvimrc" | source $MYGVIMRC'
export LESSHISTFILE=$XDG_STATE_HOME/lesshst # for versions lower than 598
export NODE_REPL_HISTORY=$XDG_STATE_HOME/node_repl_history
export NPM_CONFIG_CACHE=$XDG_CACHE_HOME/npm
export NPM_CONFIG_INIT_MODULE=$XDG_CONFIG_HOME/npm/config/npm-init.js
export NPM_CONFIG_TMP=$XDG_RUNTIME_DIR/npm
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
export PYTHON_HISTORY=$XDG_STATE_HOME/python_history
export PYTHONSTARTUP=$XDG_CONFIG_HOME/python/pythonrc # for versions lower than 3.13.0a3
export RUSTUP_HOME=$XDG_DATA_HOME/rustup
export SCREENRC=$XDG_CONFIG_HOME/screen/screenrc
export SQLITE_HISTORY=$XDG_STATE_HOME/sqlite_history
export TERMINFO=$XDG_DATA_HOME/terminfo
export TERMINFO_DIRS=$XDG_DATA_HOME/terminfo:/usr/share/terminfo
export VIMINIT='let $MYVIMRC="$XDG_CONFIG_HOME/vim/vimrc" | source $MYVIMRC'
type adb &> /dev/null && alias adb="HOME=${XDG_DATA_HOME}/android ${aliases[adb]:-adb}"
type bash &> /dev/null && alias bash="HISTFILE=${XDG_STATE_HOME}/bash/history ${aliases[bash]:-bash}"
type wget &> /dev/null && alias wget="${aliases[wget]:-wget} --hsts-file=${XDG_DATA_HOME}/wget-hsts"
