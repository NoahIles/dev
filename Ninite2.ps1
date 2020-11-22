iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
$applist = ('7zip','audacity','chromium','cinebench','cpu-z','discord','disk2vhd','dropbox','ds4windows','git','googlechrome','googledrive','hashtab','jre8','keepassx','logitechgaming','malwarebytes','nomacs','obs-studio','paint.net','prime95','qbittorrent','rufus','sharex','steam','VisualStudioCode','vlc','windirstat')
#Functions
function Install-Apps{
    param($Applications)
        choco install $Applications -y -r 
    return
}
Install-Apps -Applications $applist
