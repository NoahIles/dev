#Requires -RunAsAdministrator
#User input Function
function Prompt-User(){
    param($prompt_string)
    $response = Read-Host -Prompt "$prompt_string"
    $response = $response.toLower()
    if(($response -like 'y') -or ($response -like 'ye') -or ($response -like 'yes')){
        return $true
    }
    else {
        return $false
    }
}
#Installs Chocolatey if needed
$chocoInstalled = powershell choco -v
if(-not($chocoInstalled))
{
    write-output "Seems Chocolatey is not installed, installing now"
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}
else {
    write-output "Chocolatey is already Installed!! Beginning Packege Installation!!"
}
#* App Genres
$telemetry_stuff = ('blackbird', 'disable-nvidia-telemetry')
$Bundles = ('adobereader','office365business')
$Dev_stuff = ('jdk8','jre8','vcredist140', 'git', 'VisualStudioCode','mingw')
$Utilities = ('nircmd', 'hashtab', '7zip', 'disk2vhd', 'windirstat', 'rufus')
$benchMarks = ('cpu-z','cinebench','prime95')
$apps = ('Vivaldi','audacity','discord','google-drive-file-stream','dropbox','googlechrome','keepassx','logitechgaming','nomacs','obs-studio','qbittorrent','steam','vlc')
$install_List = @()
$genreTable = @{
    telemetry_Stuff = $telemetry_stuff
    Bundles = $Bundles
    Development_Tools = $Dev_stuff
    Utility_Programs = $Utilities
    main_apps = $apps
}
#* Prompts the user for which Genres they want to install
foreach ($Genre in $genreTable.keys) {
    $r = Prompt-User -prompt_string "Would you like to install $Genre : $($genreTable[$Genre])"
    if($r){
        $install_List += ($($genreTable[$Genre]))
    }
}
#* Installs Selected Apps/Genres
if(($install_List) -and (Prompt-User -prompt_string "Would you like to install $($Install_List.length()) packeges")){
    choco install $install_List -y -r 
}
#* WSL 2 stuff 
if(Prompt-User -prompt_string "Would you Like to Install WSL2?"){
    write-output "Enabling Required Windows Features"
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    write-output "Setting Default WSL version 2"
    wsl --set-default-version 2
    choco install wsl2 -params "/retry:true"
    choco install wsl-kalilinux
}
#* I know that setting-sync exists this might be a better solution but also would lead to bloated vscode
#VSCODE extension stuff
if(Prompt-User -prompt_string "Would you Like to Install base VSCODE Extensions"){
    $extensions = "aaron-bond.better-comments,ahmadawais.shades-of-purple,donjayamanne.githistory,dracula-theme.theme-dracula,eamodio.gitlens,esbenp.prettier-vscode,Gruntfuggly.todo-tree,kevinkyang.auto-comment-blocks,maptz.regionfolder,ms-vscode-remote.vscode-remote-extensionpack,ms-vscode.cpptools"
    $extensions | % {"code --install-extensions $_"}
}
# git config --global user.email "NoahIles@gmail.com"
# git config --global user.name "Noah"
# TODO: add git user configuration :: user.name user.email 
# TODO: add WSL configuration commands, oh-my-zsh
# TODO: add VScode settings 
# TODO: automate .ssh / .zshrc /
