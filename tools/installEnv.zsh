#! /usr/bin/env zsh
# Requires:
#   - Macos (uses Homebrew)
#   - Zsh (should be installed on newer macs) linux folk might need to run a quick `apt install zsh` first
#   - Git

INSTALL_LOCATION = "$HOME/development"
TMP_DIR = "$HOME/tmp"

dependencies=(
  "git"
  "docker"
  "docker-compose"
  "visual-studio-code"
)
#-----------------------------------------------------------------------------------------------------
# install dependencies if needed, use the installer passed in by parameter
#-----------------------------------------------------------------------------------------------------
install_dependencies() {
  for dependency in "${dependencies[@]}"; do
    if [[! command -v $dependency >/dev/null 2>&1]]; then
      echo "Installing $dependency"
      # $1 is the installer passed by parameter to the function ie: apt-get or yum
      $1 -y $dependency
    fi
  done
}

#-----------------------------------------------------------------------------------------------------
# ask the user if they want to use homebrew to install dependencies
# if they say yes install homebrew and all dependencies
#-----------------------------------------------------------------------------------------------------
# Macos Detected
if [[ "$OSTYPE" == "darwin"* ]]; then
  # check if homebrew is installed
  echo ""
  echo "Do you want to install dependencies using Homebrew? (y/n)"
  read -r homebrew
  if [[ $homebrew == "y" ]]; then
    if [ ! command -v brew >/dev/null 2>&1]; then
      echo "Installing Homebrew" # install homebrew
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      install_dependencies "brew install --cask" # install dependencies
    else
      brew update # Update Homebrew
    fi
    echo "Homebrew is installed, install depenencies now?"
    read -r homebrew
    if [ "$homebrew" == "y" ]; then
      install_dependencies "brew install --cask" # install dependencies
    else
      echo "Skipping Homebrew/Dependencies Install Please Make sure you install docker and vscode on your own."
    fi
  fi

# Linux OS Detected
elif [[ "$OSTYPE" == "linux"* ]]; then
  echo "Your are running this script on Linux!"
  # check for apt
  if command -v apt >/dev/null 2>&1; then
    echo "using apt to install dependencies."
    install_dependencies "sudo apt-get -y install" # install dependencies

  # if No apt check for yum
  elif command -v yum >/dev/null 2>&1; then
    echo "using yum to install dependencies."
    install_dependencies "sudo yum install -y" # install dependencies
  else
    echo "You are running this script on a Linux system that does not have apt or yum installed."
    echo "Please install docker and vscode on your own."
  fi
else
  echo "Unsupported OS"
  exit 1
fi

#-----------------------------------------------------------------------------------------------------
# Creates a development directory in your home directory and clones the development environment repo
# If git is not installed it currently fails.
#-----------------------------------------------------------------------------------------------------
# check if $INSTALL_LOCATION exists
if [-d $INSTALL_LOCATION/.git]; then
  echo "You Already have the repository would you like to try and update it?"
  read -r update
  if [ "$update" == "y" ]; then
    cd $INSTALL_LOCATION
    git pull
  else
    echo "Skipping update"
  fi
fi
#! Consider making this an elif?
if [ -d $INSTALL_LOCATION ]; then
  echo "development folder exists would you like to clean install?"
  read -r clean
  # echo "clean install is $clean"
  # This is a hard clean install of the repo from scratch
  # it would more more recommended to try a soft git pull if you have the repo already
  if [ "$clean" = "y" ]; then
    echo "Rescueing Code if it Exists"

    find $INSTALL_LOCATION -type 'd' -name '*[^.*]*' -mindepth 1 -maxdepth 1 |
      xargs -I '{}' mv -rf {} $TMP_DIR
    find $INSTALL_LOCATION -type 'f' -name '*[^.*]*' -not -path "*readme*" -mindepth 1 -maxdepth 1 |
      xargs -I '{}' mv -rf {} $TMP_DIR

  fi

fi
# check if $HOME/.zsh_history exists
if [ ! -f $HOME/.zsh_history ]; then
  touch $HOME/.zsh_history
fi
# If git exists use git clone otherwise curl
if [ -x "$(command -v git)" ]; then
  git clone --recursive --depth 1 --branch devEnvs --filter=blob:none https://github.com/NoahIles/quickstart.git $INSTALL_LOCATION
else
  echo "Git not installed. Install Failed"
fi
#! #TODO check if code is installed to path or installed at all.
code --install-extension ms-vscode-remote.vscode-remote-extensionpack
code -n $INSTALL_LOCATION/
#! Verify that this extension actually gets installed.
