# Requires: 
#   - Vscode
#   - 'code' installed to path (Non-Windows if on windows you just need to sign out and sign back in to add to path)
#   - Docker or Docker Desktop (for the devcontainer to actually open this script can function without docker installed)

# Run this Command with administrator powershell shell
# Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.github.com/NoahIles/quickstart/devEnvs/installEnv.ps1')) 
mkdir ~/development
cd ~/development/
curl https://raw.githubusercontent.com/NoahIles/quickstart/devEnvs/cppEnv.tar -OutFile 'cppEnv.tar'
"" | out-file ~/.zsh_history -Append
code --install-extension ms-vscode-remote.vscode-remote-extensionpack
tar xvf cppEnv.tar
code -n  .