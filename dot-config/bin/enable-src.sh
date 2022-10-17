#!/bin/sh

sudo sed -i 's/^# deb-src/deb-src/' /etc/apt/sources.list && \
sudo apt update
