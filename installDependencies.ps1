#Requires -RunAsAdministrator
#TODO: Do You need WSL at all? 
wsl --install
winget install vscode
winget install docker

#TODO:
# Ask user if they want to install WSL or a specific distro
#Test if any wsl distributions exist and if not, install the latest one

#TODO:
# Run installEnv.sh to complete the installation
# Should it be in the WSL environment?
# Where should we put the environment? Prompt? 