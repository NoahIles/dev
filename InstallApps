#!/bin/zsh
#install Rosetta 2 
echo "Installing Rosetta 2 "; softwareupdate --install-rosetta  --agree-to-license
#install xcode development tools 
echo "Installing xCode DevTools "; xcode-select --install
#Install HomeBrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
#Brew app install catagories list 
dev=(docker git visual-studio-code iterm2 bat)
general=(alfred zerotier-one qbittorent spotify iina discord keepassx)
cloudStorage=(google-drive-file-stream dropbox)
# wireshark, removed
echo "Installing Brew Casks..."
# Brew Install commands
echo "Installing Dev Stuff";     brew install ${dev[@]}
echo "Installing General Stuff"; brew install ${general[@]}
echo "Installing cloud Storage"; brew install ${cloudStorage[@]}
echo "Installing Oh-My-Zsh...";  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" #Oh-My-Zsh
#Powerlevel 10k | Terminal Theme 
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

echo "Installing Misc Brew Stuff";    brew install mas dust tealdeer gping # MAS (Mac appstore interface), Better unix tools 
tldr --update
#  a tool which allows you to install apps from mac app store via CLI  # think this is a key 1 2 3 ? 
# echo "Installing Mac App Store Apps";  mas install  1402042596 462054704 46205843 #  word, excel,
# 408981434 , adblock removed

# zshrc stuff 
# plugins=(zsh-z git osx vscode alias-finder flutter)
#
