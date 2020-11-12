# This is very early attempt at a Powershell script that I now realize could be compacted into 3 lines...
# But hey it works still...
#
#
#Vars
$applist = ('7zip','audacity','battle.net','cinebench','cpu-z','discord','disk2vhd','dropbox','ds4windows','firefox','git','googlechrome','googledrive','hashtab','jre8','keepassx','logitechgaming','makemkv','malwarebytes','nomacs','notepadplusplus','obs-studio','paint.net','prime95','putty','qbittorrent','rufus','sharex','spotify','steam','VisualStudioCode','vlc','windirstat')
$chocolateyinstall = $true
#Functions
function Get-Applist {
    param($applist)
        $Applications = @()
        $AllResponse = Read-Host -Prompt "Type (A) to install all apps $($applist -join "`n")"
        foreach($app in $applist){
            if($AllResponse -match 'A|all'){
                $Applications = $applist
                break
            }
            else{
                $response = Read-Host -Prompt "Would you like to install $($App)"
                if(($response -like 'Y') -or ($response -like 'Ye') -or ($response -like 'Yes')){
                    $Applications += $app
                }
            }
        }
    return $Applications
}
function Install-Apps{
    param($Applications)
        choco install $Applications -y -r 
    return
}
#Commands
if($chocolateyinstall -eq $true){
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) #Installs Chocolatey 
}
$Applications = Get-Applist -Applist $Applist
Install-Apps -Applications $Applications
