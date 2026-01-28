#! /usr/bin/env bash
set -euo pipefail

# Use BASE_DIR from environment (set by Python CLI) or determine it from script location
[ -z "$BASE_DIR" ] && BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )
SCRIPT_DIR="$BASE_DIR/quickstart"

echo "Running osx quickstart"

BACKUP_PATH="$HOME/BrewBackup/Brewfile"

# BACKUP Brew packages 
brew_start(){
  if command -v brew >/dev/null 2>&1; then
    echo "brew is already installed, backing up..."
    mkdir -p "$(dirname $BACKUP_PATH)"
    brew bundle dump --file="$BACKUP_PATH" --force
    echo "Created file at $BACKUP_PATH" 
    cat $BACKUP_PATH
    # Ensure fzf is installed for next step
    ! command -v fzf >/dev/null 2>&1 && brew install fzf
  else
    echo "You can install brew... using "
    echo "/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)""
    exit
  fi
}

install_brew_apps(){
  BUNDLE=$(ls $SCRIPT_DIR/apps/ | fzf)
  brew bundle install --file=$SCRIPT_DIR/apps/$BUNDLE
}

changeShell_adv(){
  FISH_PATH="$(which fish)"

  if ! grep -q "^$FISH_PATH$" /etc/shells; then
    echo "You may need this command to allow fish as shell"
    echo 'echo "$(which fish)" | sudo tee -a /etc/shells'
    echo "chsh -s $FISH_PATH"
  fi
}

brew_start
install_brew_apps
changeShell_adv
