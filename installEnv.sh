#! /usr/bin/env bash
# Requires: 
#   - Macos (uses Homebrew)
dependencies=(
  "docker"
  "docker-compose"
  "visual-studio-code"
)
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
brew update
brew install ${dependencies[@]}
mkdir ~/development
cd ~/development/
curl -O -L https://raw.githubusercontent.com/NoahIles/quickstart/devEnvs/cppEnv.tar
code --install-extension ms-vscode-remote.vscode-remote-extensionpack
tar xvf cppEnv.tar
code -n  .