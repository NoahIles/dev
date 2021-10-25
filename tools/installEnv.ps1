# Requires: 
#   - Vscode
#   - 'code' installed to path (Non-Windows if on windows you just need to sign out and sign back in to add to path)
#   - Docker or Docker Desktop (for the devcontainer to actually open this script can function without docker installed)

# Run this Command with administrator powershell shell
# Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.github.com/NoahIles/quickstart/devEnvs/tools/installEnv.ps1')) 
if(!$env:PROCESSOR_ARCHITECTURE.Contains("64")){
    Write-Host "This script requires 64 bit architecture"
    exit 1
}
elseif(!Test-Path "C:\Program Files\Microsoft VS Code\Code.exe"){
    Write-Host "Microsoft VS Code not installed Please install And try again"
    exit 1
}
elseif(!Test-Path "C:\Program Files\Docker\Docker\Docker.exe"){
    Write-Host "Docker not installed Please install"
    Write-Host "This script will complete without Docker but DevEnv wont launch without it."
}
else{
    Write-Host "All requirements met"
}
if(!Test-Path ~/development){
    mkdir -p ~/development
}
if(!Test-Path ~/.zsh_history){
    "" | out-file ~/.zsh_history -Append
}
Set-Location ~/development/
Write-Output "Installing devEnv deploy and debug config"
curl https://github.com/NoahIles/quickstart/archive/devEnvs.zip -OutFile 'cppEnv.zip'
Write-Output "Installing the code extension needed to open up the devEnvironment in vscode"
code --install-extension ms-vscode-remote.vscode-remote-extensionpack
Expand-Archive ~/development/cppEnv.zip -DestinationPath ~/development/
rm cppEnv.zip
Write-Output "Cleaning Up..."
code -n  .