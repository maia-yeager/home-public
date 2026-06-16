. "${XDG_CONFIG_HOME:-$HOME/.config}"/env/-init
. "${XDG_CONFIG_HOME:-$HOME/.config}"/env/-login
. "${XDG_CONFIG_HOME:-$HOME/.config}"/env/-xdg
. "${XDG_CONFIG_HOME:-$HOME/.config}"/env/[!-.]* 2>/dev/null

export BASH_SILENCE_DEPRECATION_WARNING=1 # macOS >= 10.15 (Catalina)

# Add to $PATH if missing.
case :$PATH: in
  *:$HOME/bin:*) ;;
  *) PATH="$HOME/bin:$PATH" ;;
esac
case :$PATH: in
  *:$HOME/.local/bin:*) ;;
  *) PATH="$HOME/.local/bin:$PATH" ;;
esac
case :$PATH: in
  *:$HOMEBREW_PREFIX/opt/rustup/bin:*) ;;
  *) PATH="$HOMEBREW_PREFIX/opt/rustup/bin:$PATH" ;;
esac
case :$PATH: in
  *:$HOMEBREW_PREFIX/opt/libpq/bin:*) ;;
  *) PATH="$HOMEBREW_PREFIX/opt/libpq/bin:$PATH" ;;
esac
case :$PATH: in
  *:$ANDROID_HOME/emulator:*) ;;
  *) PATH="$ANDROID_HOME/emulator:$PATH" ;;
esac
case :$PATH: in
  *:$ANDROID_HOME/platform-tools:*) ;;
  *) PATH="$ANDROID_HOME/platform-tools:$PATH" ;;
esac
