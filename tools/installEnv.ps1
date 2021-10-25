# Requires: 
#   - Vscode
#   - 'code' installed to path (Non-Windows if on windows you just need to sign out and sign back in to add to path)
#   - Docker or Docker Desktop (for the devcontainer to actually open this script can function without docker installed)

# Run this Command with administrator powershell shell
# Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.github.com/NoahIles/quickstart/devEnvs/installEnv.ps1')) 
mkdir ~/development
cd ~/development/
curl https://github.com/NoahIles/quickstart/archive/devEnvs.zip -OutFile 'cppEnv.zip'
"" | out-file ~/.zsh_history -Append
code --install-extension ms-vscode-remote.vscode-remote-extensionpack
unzip xvf cppEnv.zip
rm cppEnv.zip
code -n  .