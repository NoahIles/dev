# Quickstart : Get Your Dev Environment Ready
A cpp Development Environment Quick Deployment.

## Installation: 
### Windows
#### Prerequisites (for Windows):
 **This Development Environment Depends on:**
+ [Docker/Docker Desktop ](https://www.docker.com/products/docker-desktop)
+ [vscode](https://www.docker.com/products/docker-desktop)

0. Install the Prerequisites above and restart your computer.
1. Then Use this command to install the devEnvironment for Vscode.
```ps1
 Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.github.com/NoahIles/quickstart/devEnvs/installEnv.ps1')) 
```

### Mac OSX
The Macos Version uses Homebrew to install the necessary dependencies. Use the following command to begin. It Will create a new folder called 'development' within your 'Home' folder in other words in your acounts user folder. 
```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/NoahIles/quickstart/devEnvs/installEnv.sh)"
```
I reccomend that you create a shortcut to this folder on your desktop or finder sidebar. 
You will need Docker installed in order to launch the coding environment. 

### Linux 
If You don't mind using homebrew you can use the Mac Os Instructions. 

#TODO: Linux version using apt / yum  

## Usage: 

**In order to open the environment**

1. Open the new developement Folder in vscode
    + Open a Terminal and run `code ~/development`
2. You should see a notification suggesting you reopen within the container
    + If You Dont see this you can: 
        - Open the Command Palate with (F1) and type `rebuild`
3. Be Patient as it builds the first time subsequent times should take less time. 
