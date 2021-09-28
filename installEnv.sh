#! /usr/bin/env bash

# sudo apt-get update && sudo apt-get upgrade -y
# sudo apt-get install --no-install-recommends -y apt-transport-https ca-certificates software-properties-common \
#     zsh git vim unzip wget curl htop tmux

mkdir ~/development

cd ~/development/
curl -O https://github.com/NoahIles/quickstart/archive/devEnvs.zip
unzip devEnvs.zip

mkdir ~/development/.devcontainer/
mv ~/development/quickstart-devEnvs/cppENV/* ~/development/.devcontainer/

code ~/development/ 


