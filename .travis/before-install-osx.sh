#!/bin/sh

export HOMEBREW_NO_ANALYTICS=1

brew update
brew unlink python@2
brew upgrade git
brew install ccache ninja

echo "Unsetting git config protocol.version"
git config --global --unset protocol.version
git config --list --show-origin

export PATH="/usr/local/opt/ccache/libexec:$PATH"

