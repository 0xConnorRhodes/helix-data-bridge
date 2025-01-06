#!/usr/bin/env bash

sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y \
  autoconf \
  patch \
  build-essential \
  rustc \
  libssl-dev \
  libyaml-dev \
  libreadline6-dev \
  zlib1g-dev \
  libgmp-dev \
  libncurses5-dev \
  libffi-dev \
  libgdbm6 \
  libgdbm-dev \
  libdb-dev \
  uuid-dev

curl https://mise.run | MISE_VERSION=v2024.12.20 sh

echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
eval "$(~/.local/bin/mise activate bash)"

mise use --global ruby@3.3.6

git clone https://github.com/0xConnorRhodes/ruby-modules.git /tmp/ruby-modules && \
    find /tmp/ruby-modules -type f ! -name "*.rb" -delete && \
    cp -r /tmp/ruby-modules/* $HOME/.local/share/mise/installs/ruby/latest/lib/ruby/site_ruby/ && \
    rm -rf /tmp/ruby-modules

git clone https://github.com/0xConnorRhodes/verkada-api-rb.git /tmp/ruby-vapi && \
    find /tmp/ruby-vapi -type f ! -name "*.rb" -delete && \
    cp -r /tmp/ruby-vapi/* $HOME/.local/share/mise/installs/ruby/latest/lib/ruby/site_ruby/ && \
    rm -rf /tmp/ruby-vapi

$HOME/.local/share/mise/installs/ruby/3.3.6/bin/gem update --system

exec bash # reload bash to apply mise activation

# TODO:
# bundle install in the project directory
# install vapi
