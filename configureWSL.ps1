Read-Host -Prompt "Hello are you woke?"
write-output "Setting Default WSL version 2"
wsl --set-default-version 2
#if kernal error https://docs.microsoft.com/en-us/windows/wsl/wsl2-kernel
choco install wsl2 -params "/retry:true"
choco install wsl-kalilinux