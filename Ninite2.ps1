#Requires -RunAsAdministrator
#Installs Chocolatey 
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
#List of apps to install
$telemetry_stuff = ('blackbird', 'disable-nvidia-telemetry')
$Bundles = ('adobereader','office365business')
$Dev_stuff = ('jdk8','jre8','vcredist140', 'git', 'VisualStudioCode','mingw')
$Utilities = ('nircmd', 'hashtab', '7zip', 'disk2vhd', 'windirstat', 'rufus')
$benchMarks = ('cpu-z','cinebench','prime95')
$apps = ('Vivaldi','audacity','discord','google-drive-file-stream','dropbox','googlechrome','keepassx','logitechgaming','nomacs','obs-studio','qbittorrent','steam','vlc')
$install_List = $telemetry_stuff + $Bundles + $Dev_stuff + $Utilities + $apps
#Install Command 
choco install $install_List -y -r 

#WSL 2 stuff 
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
wsl --set-default-version 2
choco install wsl2 -params "/retry:true"
choco install wsl-kalilinux

# TODO:  and make interactive  
# TODO: add git user configuration :: user.name user.email 
# TODO: add WSL commands, oh-my-zsh
# TODO: add VScode extensions // settings 
# TODO: automate .ssh / .zshrc /
