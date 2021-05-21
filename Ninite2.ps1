#Requires -RunAsAdministrator
 #Configuration settings
 $assumeNeedToInstall = $true #Assumes You will need to install Chocolatey (A Windows Package manager) 
#User input Function
function QuestionUser() {
    param([string]$prompt_string)
    $response = Read-Host -Prompt "$prompt_string (default is yes)"
    $response = $response.toLower()
    if (($response -like 'y') -or ($response -like 'ye') -or ($response -like 'yes' -or ($response -like ''))) {
        return $true
    }
    else {
        return $false
    }
}
set-location $PSScriptRoot #Just some extra assurance that we are in the right loaction
# Oh-My-posh Installation 
if (QuestionUser -prompt_string "Would you like to install Oh-My-Posh for a better Powershell?"){
    Write-Output "Installing Oh-My-Posh for a better PWSH experience This may take a minute..."
    Install-Module oh-my-posh -Scope CurrentUser
    Write-Output "Note: Oh-my-posh requires script execution on powershell Startup"
    Set-ExecutionPolicy Bypass
    #If local theme exists move/replace in theme
    if (QuestionUser -prompt_string "Would you like to Copy Powershell Themes") {
        if (test-path "cinnamon.omp.json" ) {
            $path = (Get-ChildItem -Path "$HOME/Documents/WindowsPowerShell/Modules/oh-my-posh/" -Filter "cinnamon.omp.json" -Recurse).Directory.FullName
            Copy-Item ".\cinnamon.omp.json" $path -Force
            Write-Output "Copied Provided Cinnamon theme to the themes folder"
        } else { 
            Write-Output "Failed to find Cinnamon theme. Moving on..."
        }
        $items = (Get-Item "*.omp.json" | Where-Object Name -notlike "cinnamon*").FullName
        if ($items.Length -gt 0) {
            Write-Output "Extra Themes found Copying to theme folder"
            $items | ForEach-Object copy-item $_ $path -force
        } else {
            Write-Output "Didn't find any Other Themes to install. Moving on..."
        }
        $SET_THEME = Set-PoshPrompt -Theme cinnamon
        Add-Content $PROFILE $SET_THEME #powershell configuration file  
    }
}

# Installs Chocolatey if needed
$chocoInstalled = powershell choco -v
if (-not($chocoInstalled) -or $assumeNeedToInstall ) {
    write-output "Seems Chocolatey is not installed, installing now"
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}
else {
    write-output "Chocolatey is already Installed!! Beginning Packege Installation!!"
}
#* App Genres
$telemetry_stuff = ('blackbird', 'disable-nvidia-telemetry') # I think both of these packeges are broken atm
$bundles = ('adobereader', 'office365business')
$dev_stuff = ('jdk8', 'jre8', 'git', 'VisualStudioCode', 'mingw')
$utilities = ('nircmd', 'hashtab', '7zip', 'disk2vhd', 'windirstat', 'rufus', '7-taskbar-tweaker', 'autohotkey')
$benchMarks = ('cpu-z', 'cinebench', 'prime95')
$apps = ('Vivaldi', 'audacity', 'discord', 'google-drive-file-stream', 'dropbox', 'googlechrome', 'keepassx', 'logitechgaming', 'nomacs', 'obs-studio', 'qbittorrent', 'steam', 'vlc')
$install_List = @()
$genreTable = @{
    Telemetry_Stuff   = $telemetry_stuff # Disables some Telemetry
    Bundles           = $bundles 
    Development_Tools = $dev_stuff # Java, vscode/C++ tools
    Utility_Programs  = $utilities # MISC
    Main_Apps         = $apps
}
#* Prompts the user for which Genres they want to install
foreach ($Genre in $genreTable.keys) {
    $r = QuestionUser -prompt_string "Would you like to install $Genre : $($genreTable[$Genre])"
    if ($r) {
        $install_List += ($genreTable[$Genre])
    }
}
#* Installs Selected Apps/Genres
if (($install_List) -and (QuestionUser -prompt_string "Install_List created Begin installing packeges?")) {
    #$len = $install_List.length() #! figure out Why $install_List is a string instead of an Array Object
    write-output "Preparing to Install packeges"
    choco install $install_List -y -r 
}
#* I know that setting-sync exists this might be a better solution but also would lead to bloated vscode
#VSCODE extension stuff
if (QuestionUser -prompt_string "Would you Like to Install base VSCODE Extensions") {
    $extensions = "aaron-bond.better-comments,ahmadawais.shades-of-purple,donjayamanne.githistory,dracula-theme.theme-dracula,eamodio.gitlens,esbenp.prettier-vscode,Gruntfuggly.todo-tree,kevinkyang.auto-comment-blocks,maptz.regionfolder,ms-vscode-remote.vscode-remote-extensionpack,ms-vscode.cpptools"
    $extensions | ForEach-Object { "code --install-extensions $_" }
}
#* WSL 2 stuff 
if (QuestionUser -prompt_string "Would you Like to Install WSL2?") {
    write-output "Enabling Required Windows Features"
    # Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    # dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    #make sure windows version is >=2004
    # dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    Write-Output "After the restart you should be able to install a wsl distrobution from the Store"
    choco install wsl2 -y -params "/retry:true" 
    #* Windows INsider preview has implemented a new command which will significantly simplify wsl2 installation 
    #? wsl --install -d <Distribution Name> 
}
# git config --global user.email "NoahIles@gmail.com"
# git config --global user.name "Noah"
# TODO: automate .ssh / .zshrc  !!!!
# TODO: add git user configuration :: user.name user.email 
# TODO: add WSL configuration commands // make it handle restart properly
# TODO: add VScode settings 
# TODO: make breakout for-each genre
