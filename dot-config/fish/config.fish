#!/bin/fish

fish_vi_key_bindings

starship init fish | source

# Disable the fish greeting
set -gx fish_greeting

# Tell Snapcraft to build inside the LXD container
set -gx SNAPCRAFT_BUILD_ENVIRONMENT host

# Enable Snapcraft's experimental extensions
set -gx SNAPCRAFT_ENABLE_EXPERIMENTAL_EXTENSIONS 1

# Set Snapcraft Store credentials from ~/secrets
set -gx SNAPCRAFT_ENABLE_STORE_CREDENTIALS (cat $HOME/secrets/snapcraft.login)
