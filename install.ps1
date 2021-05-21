#Requires -RunAsAdministrator
#Run with `Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.github.com/NoahIles/quickstart/Windows/install.ps1'))`
$install_location = "$HOME/Documents"
Set-Location $install_location
Invoke-WebRequest https://github.com/NoahIles/quickstart/archive/Windows.zip -OutFile 'quickstart.zip'
Expand-Archive "./quickstart.zip" ./
$Install_App_Script = (Get-ChildItem $install_location/quickstart-Windows -Filter "Ninite2.ps1" ).FullName 
if($Install_App_Script){
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression $Install_App_Script
}else {
    Write-Output "Install Script Failed"
}
