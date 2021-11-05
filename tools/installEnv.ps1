# Requires: 
#   - Vscode
#   - 'code' installed to path (Non-Windows if on windows you just need to sign out and sign back in to add to path)
#   - Docker or Docker Desktop (for the devcontainer to actually open this script can function without docker installed)

# Run this Command with administrator powershell shell
# Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.github.com/NoahIles/quickstart/devEnvs/tools/installEnv.ps1')) 

# This is a Helper Function to promt the user if they want to continue with the installer or not
$INSTALL_LOCATION = "${HOME}/development/"
function askContinue {
    param(
        $exit = $true
    )
    Write-Host "Press 'y' or enter to continue...Or Any Other Key to exit"
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    if(!($key.Character -like 'y' -or $key.Character -like 'Y' -or $key.VirtualKeyCode -eq 13)) {
        if($exit) {
            exit 1
        }else{
            return $false
        }
    }else {
        return $true
    }
}

# This will ask if you want to delete the old files and start over or specify a new install directory (if you want to install to a different location)
function askcleanInstall {
    if(Test-Path $INSTALL_LOCATION){
        Write-Host "Would you like to remove the old dev Environment?"
        if(askContinue -exit:$false) {
            Write-Host "Removing old dev environment"
            Get-ChildItem $INSTALL_LOCATION/.* | Write-Host
            # Remove-Item -recurse -force
        } 
        Write-Host "Would you like to specify a new install location?"
        # Write-Host "If You do you will need to modify the InstallEnv.ps1 script within the tools folder"
        #TODO: Implement Custom Install location
        askContinue

    }

}

#This function is how we download the environment configuration files
function downloadHelper {
    Set-Location $INSTALL_LOCATION
    Write-Output "Installing devEnv deploy and debug config"
    Invoke-WebRequest -Uri "https://api.github.com/repos/noahiles/quickstart/zipball/devEnvs" -OutFile 'cppEnv.zip'
}


# This function creates the actual development environment for VSCode
# Downloading the repository from github which includes a .devcontainer environment and a default debugging config
function downloadDevEnv {
    if(Test-Path $INSTALL_LOCATION) {
        Write-Host "The Development Environment might already be installed."
        askcleanInstall
        mkdir $INSTALL_LOCATION
    }
    else{
        mkdir $INSTALL_LOCATION
    }
    if(!(Test-Path $HOME/.zsh_history)){
        "" | out-file $HOME/.zsh_history -Append
    }
    downloadHelper
    Write-Output "Installing the code extension needed to open up the devEnvironment in vscode"
    code --install-extension ms-vscode-remote.vscode-remote-extensionpack
    Expand-Archive $HOME/development/cppEnv.zip -DestinationPath $INSTALL_LOCATION 
    Set-Location "${INSTALL_LOCATIONNoah}*quickstart*"
    Move-Item -Path ./* -DestinationPath $INSTALL_LOCATION
    Write-Output "Cleaning Up..."
    rm "${INSTALL_LOCATION}*quickstart*"
    rm $HOME/development/cppEnv.zip
    Write-Output "DONE, Opening devEnv code folder in vscode"
    Write-Output "Successfully installed development folder in your Home folder."
    code -n  $HOME/development/cpp.code-workspace
    askContinue
}

# This is another Helper function that will try to use windows winget to install dependencies
function askInstall {
    Param(
        $app
    )
    if($app -like "Docker"){
        Write-Host "Installing Docker using winget"
        winget install docker.dockerdesktop
    }elseif($app -like "code"){
        Write-Host "Installing VSCode using winget"
        winget install code
    }else{
        Write-Host "Unknown or Invalid App..." 
    }
}
function askInstall {
    Param(
        $app
    )
    if($app -like "Docker"){
        Write-Host "Installing Docker using winget"
        # winget install docker.dockerdesktop
    }elseif($app -like "code"){
        Write-Host "Installing VSCode using winget"
        # winget install code
    }else{
        Write-Host "Unknown or Invalid App..." 
    }
}


# Check for dependencies before downloading the devEnvironment
# Ask to install the dependencies if they are not installed
if(!($env:PROCESSOR_ARCHITECTURE.Contains("64"))){
    Write-Host "This script requires 64 bit architecture"
    Write-Host "You might need a new computer/os"
    askContinue  
}
elseif ((!(Test-Path "$HOME\AppData\Local\Programs\Microsoft Vs Code\Code.exe") -and !(Test-Path "C:\Program Files\Microsoft VS Code\Code.exe") )){
    Write-Host "Microsoft VS Code not installed Please install And try again"
    askInstall "code"
    askContinue
}
elseif(!(Test-Path "C:\Program Files\Docker\Docker\Docker.exe")){
    Write-Host "Docker not installed Please install"
    Write-Host "This script will complete without Docker but DevEnv wont launch without it."
    askInstall "Docker"
}
else{
    Write-Host "Docker and VSCODE are Installed!"
    Write-Host "All requirements met."
}

downloadDevEnv