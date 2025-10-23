#! /usr/bin/env bash

echo "Running osx quickstart"

if command -v brew >/dev/null 2>&1; then
  echo "brew is already installed, backing up..."
  mkdir -p "$HOME/BrewBackup"
  brew bundle dump --file="$HOME/BrewBackup/Brewfile" --force
else
  echo "installing brew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi



# brew bundle install --file=$SCRIPT_PATH/apps/PersonalBrewfile


# brew bundle --file="$SCRIPT_PATH/apps/PersonalBrewfile"