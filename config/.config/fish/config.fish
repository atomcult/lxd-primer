#!/bin/fish

fish_vi_key_bindings

starship init fish | source

# Aliases
alias fd fdfind
alias ip "ip --color=auto"
alias less "less --ignore-case --RAW-CONTROL-CHARS"

# Disable the fish greeting
set -gx fish_greeting

# Add scripts path
set -gx --append PATH "$HOME/.config/bin"

# Setup the defaults
set -gx EDITOR vim
set -gx VISUAL $EDITOR
set -gx PAGER less

# Tell Snapcraft to build inside the LXD container
set -gx SNAPCRAFT_BUILD_ENVIRONMENT host

# Enable Snapcraft's experimental extensions
set -gx SNAPCRAFT_ENABLE_EXPERIMENTAL_EXTENSIONS 1

# Set Snapcraft Store credentials from ~/secrets
set -gx SNAPCRAFT_ENABLE_STORE_CREDENTIALS (cat $HOME/secrets/snapcraft.login)
