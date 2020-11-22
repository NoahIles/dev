#Requires -RunAsAdministrator
#Installs Chocolatey 
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
#List of apps to install
$applist = ('7zip','audacity','chromium','cinebench','cpu-z','discord','disk2vhd','dropbox','ds4windows','git','googlechrome','googledrive','hashtab','jre8','keepassx','logitechgaming','malwarebytes','nomacs','obs-studio','paint.net','prime95','qbittorrent','rufus','sharex','steam','VisualStudioCode','vlc','windirstat')
#Install Command 
choco install $applist -y -r 
