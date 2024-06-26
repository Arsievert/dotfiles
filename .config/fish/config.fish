if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Setup GPG_TTY for signed commits.
set -x GPG_TTY (tty)
# Add brew to environment.
eval (/opt/homebrew/bin/brew shellenv | source)

# Add rust binaries to PATH
if test -d $HOME/.cargo/bin
    set -gx PATH $HOME/.cargo/bin $PATH
end
