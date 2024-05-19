if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Setup GPG_TTY for signed commits.
set -x GPG_TTY (tty)
# Add brew to environment.
eval (/opt/homebrew/bin/brew shellenv | source)
