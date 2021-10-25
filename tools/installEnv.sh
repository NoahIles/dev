#! /usr/bin/env bash
# Requires: 
#   - Macos (uses Homebrew)
dependencies=(
  "docker"
  "docker-compose"
  "visual-studio-code"
)

# ask the user if they want to use homebrew to install dependencies
# if they say yes install homebrew and all dependencies
# if they do not have homebrew, install it
echo "Do you want to install dependencies using Homebrew? (y/n)"
read homebrew
if [ "$homebrew" == "y" ]; then
  echo "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install --cask ${dependencies[@]}
else
  echo "Skipping Dependencies Install Please Make sure you install docker and vscode"
fi
mkdir ~/development
cd ~/development/
touch $HOME/.zsh_history
git clone --recursive --depth 1 --branch devEnvs --filter=blob:none  ~/development
code -n  .
#! Verify that this extension actually gets installed. 
code --install-extension ms-vscode-remote.vscode-remote-extensionpack
tar xvf cppEnv.tar
rm -f ./cppEnv.tar