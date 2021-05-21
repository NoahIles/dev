#Requires -RunAsAdministrator
$install_location = "$HOME/Documents"
Set-Location $install_location
Invoke-WebRequest https://github.com/NoahIles/quickstart/archive/Windows.zip -OutFile 'quickstart.zip'
Expand-Archive quickstart
$Install_App_Script = (Get-ChildItem $install_location/quickstart-Windows -Filter "Ninite2.ps1" ).FullName 
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression $Install_App_Script