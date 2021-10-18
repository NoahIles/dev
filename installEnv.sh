#! /usr/bin/env bash
# Requires: 
#   - Vscode
#   - 'code' installed to path (Non-Windows)
#   - Docker or Docker Desktop

mkdir ~/development
cd ~/development/
curl -O -L https://raw.githubusercontent.com/NoahIles/quickstart/devEnvs/cppEnv.tar
code --install-extension ms-vscode-remote.vscode-remote-extensionpack
tar xvf cppEnv.tar
code -n  .