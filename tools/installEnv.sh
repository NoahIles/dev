#! /usr/bin/env bash
# Requires: 
#   - Macos (uses Homebrew)
dependencies=(
  "docker"
  "docker-compose"
  "visual-studio-code"
  "git"
)
# ask the user if they want to use homebrew to install dependencies
# if they say yes install homebrew and all dependencies
# if they do not have homebrew, install it
if [["$OSTYPE" == "darwin"* ]]; then
  # check if homebrew is installed
  echo "Do you want to install dependencies using Homebrew? (y/n)"
  read -r homebrew
  if ! command -v brew >/dev/null 2>&1; then
    # install homebrew
    if [ "$homebrew" == "y" ]; then
      echo "Installing Homebrew"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
      echo "Skipping Homebrew/Dependencies Install Please Make sure you install docker and vscode on your own."
    fi
  fi
  # install dependencies
  if [ "$homebrew" == "y" ]; then
    # check if dependencies are installed. 
    # if not install them
    for dependency in "${dependencies[@]}"; do
      if ! command -v $dependency >/dev/null 2>&1; then
        echo "Installing $dependency"
        brew install --cask $dependency
      fi
    done
  fi
# More Mac os Steps 
elif [["$OSTYPE" == "linux"* ]]; then
  echo "Your are running this script on Linux!"
  # check for apt
  if command -v apt >/dev/null 2>&1; then
    echo "using apt to install dependencies."
    # install dependencies
    for dependency in "${dependencies[@]}"; do
      if ! command -v $dependency >/dev/null 2>&1; then
        echo "Installing $dependency"
        sudo apt-get install $dependency -y
      fi
    done
  elif command -v yum >/dev/null 2>&1; then
    echo "using yum to install dependencies."
    # install dependencies
    for dependency in "${dependencies[@]}"; do
      if ! command -v $dependency >/dev/null 2>&1; then
        echo "Installing $dependency"
        sudo yum install $dependency -y
      fi
    done
  else
    echo "You are running this script on a Linux system that does not have apt or yum installed."
    echo "Please install docker and vscode on your own."
  fi
else
  echo "Unsupported OS"
  exit 1
fi
# check if ~/development exists
if [ ! -d ~/development ]; then
  mkdir ~/development
fi
# check if ~/.zsh_history exists
if [ ! -f ~/.zsh_history ]; then
  touch ~/.zsh_history
fi
cd ~/development/
# If git exists use git clone otherwise curl 
if [ -x "$(command -v git)" ]; then
  git clone --recursive --depth 1 --branch devEnvs --filter=blob:none  ~/development
else
  echo "Git not installed. Install Failed"
fi

code --install-extension ms-vscode-remote.vscode-remote-extensionpack
code -n  .
#! Verify that this extension actually gets installed. 