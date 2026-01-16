#! /usr/bin/env bash

echo "Running osx quickstart"

BACKUP_PATH="$HOME/BrewBackup/Brewfile"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# BACKUP Brew packages 

if command -v brew >/dev/null 2>&1; then
  echo "brew is already installed, backing up..."
  mkdir -p "$(dirname $BACKUP_PATH)"
  brew bundle dump --file="$BACKUP_PATH" --force
  echo "Created file at $BACKUP_PATH" 
  cat $BACKUP_PATH
  # Ensure fzf is installed for next step
  brew install fzf
else
  echo "You can install brew... using "
  echo "/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)""
  exit
fi

BUNDLE=$(ls $SCRIPT_DIR/apps/ | fzf)
brew bundle install --file=$SCRIPT_DIR/apps/$BUNDLE

FISH_PATH="$(which fish)"

if ! grep -q "^$FISH_PATH$" /etc/shells; then
  echo "You may need this command to allow fish as shell"
  echo 'echo "$(which fish)" | sudo tee -a /etc/shells'
  echo "chsh -s $FISH_PATH"
fi

