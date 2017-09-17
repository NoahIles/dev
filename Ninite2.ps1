#AppList
$applist = ('googlechrome','chromium','notepadplusplus','firefox','sharex','windirstat','7zip','VisualStudioCode','steam','vlc','qbittorrent','spotify','discord','putty','malwarebytes','battle.net','keepassx','dropbox','git','disk2vhd','mpc-hc','nomacs')
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
