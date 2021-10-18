#Requires -RunAsAdministrator
#!!!! THis doesn't work on Windows 10 as of yet October 2021 !!!! waiting for preview release
#TODO: Do You need WSL at all? 
#TODO: TEST FOR Old windows versions
# Lol winget is still preview
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