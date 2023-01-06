#!/bin/sh
# vim: sw=2

. /etc/lsb-release

set -ex

error() {
  echo "$@"
  exit 1
}

check_environment() {
  if [ ! -d /dev/lxd ]; then
    error "This script is only meant to be run in an LXD container."
  fi

  if [ "$DISTRIB_ID" != "Ubuntu" ]; then
    error "Non-Ubuntu systems are not supported."
  fi
}

install_packages() {
  pkgs="""
  snap
  git
  tree
  squashfuse
  fish
  nnn
  ripgrep
  fd-find
  """

  if [ "$DISTRIB_CODENAME" = "jammy" ]; then
    pkgs="$pkgs foot"
  else
    mkdir -p "$HOME/.config/fish/conf.d"
    echo "set -x TERM xterm" >> "$HOME/.config/fish/conf.d/term.fish"
  fi

  # shellcheck disable=SC2086
  sudo apt install -y $pkgs

  # sudo snap install --channel=latest/edge snapcraft --classic
  sudo snap install /work/snapcraft/*.snap --classic --dangerous
  # sudo snap set system experimental.parallel-instances=true
  # sudo snap install --name=snapcraft_6 --channel=6.x/stable snapcraft --classic

  sudo snap install starship
}

setup_vim() {
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  vim -T dumb -n -es -c PlugInstall -c qa
}

check_environment

sudo apt update && sudo apt upgrade -y
install_packages
setup_vim

sudo chsh -s /usr/bin/fish "$USER"
