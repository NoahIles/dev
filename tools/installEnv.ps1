# Requires: 
#   - Vscode
#   - 'code' installed to path (Non-Windows if on windows you just need to sign out and sign back in to add to path)
#   - Docker or Docker Desktop (for the devcontainer to actually open this script can function without docker installed)

# Run this Command with administrator powershell shell
# Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.github.com/NoahIles/quickstart/devEnvs/tools/installEnv.ps1')) 
function askContinue {
    Write-Host "Press 'y' to continue...Or Any Other Key to exit"
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    if(!($key.Character -like 'y' -or $key.Character -like 'Y' -or $key.VirtualKeyCode -eq 13)) {
        exit 1
    }
}

if(!($env:PROCESSOR_ARCHITECTURE.Contains("64"))){
    Write-Host "This script requires 64 bit architecture"
    Write-Host "You might need a new computer/os"
    askContinue

}
else if ((!(Test-Path "$HOME\AppData\Local\Programs\Microsoft Vs Code\Code.exe") -and !(Test-Path "C:\Program Files\Microsoft VS Code\Code.exe") )){
    Write-Host "Microsoft VS Code not installed Please install And try again"
    askContinue
}
elseif(!(Test-Path "C:\Program Files\Docker\Docker\Docker.exe")){
    Write-Host "Docker not installed Please install"
    Write-Host "This script will complete without Docker but DevEnv wont launch without it."
}
else{
    Write-Host "All requirements met"
}
if(!(Test-Path $HOME/development)){
    mkdir $HOME/development
}
if(!(Test-Path $HOME/.zsh_history)){
    "" | out-file $HOME/.zsh_history -Append
}
Set-Location $HOME/development/ 
Write-Output "Installing devEnv deploy and debug config"
curl https://github.com/NoahIles/quickstart/archive/devEnvs.zip -OutFile 'cppEnv.zip' -SslProtocol 'Tls12' 
Write-Output "Installing the code extension needed to open up the devEnvironment in vscode"
code --install-extension ms-vscode-remote.vscode-remote-extensionpack
Expand-Archive ~/development/cppEnv.zip -DestinationPath ~/development/
rm cppEnv.zip
Write-Output "Cleaning Up..."
code -n  .