
#! /usr/bin/env bash
set -euo pipefail

# Use BASE_DIR from environment (set by Python CLI) or determine it from script location
[ -z "$BASE_DIR" ] && BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )
SCRIPT_DIR="$BASE_DIR/quickstart"

# Copy Fish Config
echo "Running Shared scripts"

# Fish
if [ -d "$BASE_DIR/env/fish" ]; then
  mkdir -p "$HOME/.config/fish"
  cp -r "$BASE_DIR/env/fish/"* "$HOME/.config/fish/"
  echo "source $HOME/.config/fish/essentials.fish" >> "$HOME/.config/fish/config.fish"
fi

if command -v fish ; then 
  # Install fisher 
  fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
  # this will install all plugins the the fish_plugins file if it exists 
  fish -c "fisher update" 
else
  echo "Fish not installed rerun script with fish on path"
fi


