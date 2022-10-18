#!/bin/sh

HERE="$(readlink -f "$0" | xargs dirname)"

if [ ! -d /dev/lxd ]; then
    echo    "This is meant to be run in an LXD container."
    echo -n "Are you sure you want to continue? (type: YES) "

    read RESPONSE
    if [ "$RESPONSE" != "YES" ]; then
        echo
        echo Aborting.
        exit 1
    fi
fi

cp "${HERE}"/dot-config/* "${XDG_CONFIG_HOME:-$HOME/.config}" \
    --verbose \
    --recursive \
    --interactive \
    "$@"

cp "${HERE}"/dot-vim/* "$HOME/.vim" \
    --verbose \
    --recursive \
    --interactive \
    "$@"

"$HOME/.config/bin/vim-init.sh"
