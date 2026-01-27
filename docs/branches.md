# Quickstart : Get Your Computer Ready
Scripts to get your Computer up and running ASAP.
Choose the Branch Corrosponding to your Needs.

# Legacy Git branches 

## devEnvs
Uses docker/vscode devcontainers to create and deploy portable environment on all platforms. 

## Windows
Uses Powershell along with chocolatey A packege manager for windows. To bulk install applications and environments. 

### Usage
Simply open an elevated Powershell and run this command 
`Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.github.com/NoahIles/quickstart/Windows/install.ps1'))`

Includes Flows for WSL2 and VSCODE

## Mac OSX
Uses a shell script to install apps
Utilizes Brew, Brew Casks, and MAS (Mac Appstore Installer) to install apps. 
This Repository Provides Methods 

TODO: single command deploy

## Linux 
Uses Shell script to install Zsh, Oh-my-zsh and generaly prepare environment

## HTPC 
Uses Docker-Compose to deploy Home Theater Services 