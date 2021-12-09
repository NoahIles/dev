# Quickstart : Get Your Dev Environment Ready
A cpp Development Environment Quick Deployment.

## Table of Contents 
**Installation Instructions**
+ [Windows](#windows)
+ [Mac OSX & Linux]()

**Notes**
* [Usage:](#usage-)

## Installation: 
Instructions for installing and using this coding environment for various platforms. 
### Windows
#### Prerequisites (for Windows):
+ [Docker/Docker Desktop ](https://www.docker.com/products/docker-desktop)
+ [vscode](https://www.docker.com/products/docker-desktop)

**OR** 
+ [winget](https://docs.microsoft.com/en-us/windows/package-manager/winget/)

**NOTE0:** Some Windows computers will already have winget installed this script should detect it if it is.

0. Install the Prerequisites above and restart your computer.
1. Then Use this command inside an **elevated Powershell** to install the devEnvironment for Vscode.
```ps1
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.github.com/NoahIles/quickstart/devEnvs/tools/installEnv.ps1')) 
```
If you get an error "Could not create SSL/TLS secure channel"
Your may first need to run: 
```ps1
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; 
```


### Mac OSX & Linux
#### Prerequisites (For Mac OSX)
+ MacOs 10.14 -> 12.0.1+
#### Prerequisites (For Linux)
+ **zsh**
    - Install with  
    ``` 
    apt install zsh 
    or
    yum install zsh
    ``` 

* The unix version detects your opperating system;
* On **MacOs** it will use Homebrew to install the necessary dependencies.
* On **Linux** it will use apt or yum to install dependencies.

#### Download With: 
```sh
/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/NoahIles/quickstart/devEnvs/tools/installEnv.sh)"
```
* It Will create a new folder called 'development' within your '$Home' folder. 
* I reccomend that you create a shortcut to this folder on your desktop or finder sidebar.


## Usage: 

### In order to open the environment 

**NOTE1:** This container by default creates a folder in your home folder called development 

1. Open the new developement Folder in vscode
    + Open a Terminal and run `code ~/development`
2. You should see a notification suggesting you reopen within the container
    + If You Dont see this you can: 
        - Open the Command Palate with (F1) and type `rebuild`
3. Be Patient as it builds the first time subsequent times should take less time. 


### In order to use the debugger

1. you need your code i.e. (the binary you use to run_tests) to a defined **path** defined within the cpp.code-workspace file 
2. open the a file within that folder and press F5.
3. Enter the name of the binary and the test you want to run.


## Explanations:

This Dev environment uses clangd code server for code analysis linting and code formating. 



# TODO FIXME:

12-9-21 Testing Quickstart devEnv 
* Fix Winget Detection (at least on windows 11)
* Fix/ensure docker detection works
    + try winget list -or test-path
* In detection of Old environment 
    + ensure it was created by our script and not already there
* Fix the email of transcript 
