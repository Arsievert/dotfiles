if status is-interactive
    # Setup GPG_TTY for signed commits.
    set -x GPG_TTY (tty)
    # Add brew to environment.
    eval (/opt/homebrew/bin/brew shellenv | source)
    # Initialize Starship prompt.
    starship init fish | source
end

# Environment variables
set -gx EDITOR /opt/homebrew/bin/emacs
set -gx VISUAL $EDITOR

# Add rust binaries to PATH
fish_add_path $HOME/.cargo/bin
