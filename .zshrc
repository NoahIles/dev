#
#       Created by Noah Iles Updated 4-19-2021
#
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="refined" #ZSH_THEME="amuse"
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" "refined" "arrow" "amuse")

#* Removes annoying beep sounds
unsetopt BEEP
#* output aliases for commands if they exist
ZSH_ALIAS_FINDER_AUTOMATIC=true
#Need this to enable syntax highlighting plugin
ZSH_DISABLE_COMPFIX="true"

#Export Commands
export ZSH="$HOME/.oh-my-zsh"
export PATH="$PATH:$HOME/bin/flutter/bin"
export PATH="$PATH:$HOME/bin/csci/"
export WIND="/mnt/c/"
export CHROME_EXECUTABLE="$WIND/Program Files/Google/Chrome/Application/chrome.exe"

# Android
export ANDROID_HOME=$HOME/bin/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$ANDROID_HOME/emulator:$PATH

# Java
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

#alias rt ="run_tests run"
#* vsCode diff function usage: cDiff 01 
cDiff()
{
    code -r "tests/t$1.in"
    code -rd "tests/t$1.out" "results/t$1.myout" 
}

#* Adds a file to an encrpted archive 
#* Usage = encrpt_archive <ofile_name.7z> <Path-to-add-to-archive> <password>
encrpyt_7z()
{
    7z -mhc=on -mhe=on -p$3 a $1 $2
}

# Uncomment the following line to automatically update without prompting.
DISABLE_UPDATE_PROMPT="true"

plugins=(git vscode alias-finder zsh-z) # zsh-syntax-highlighting

source $ZSH/oh-my-zsh.sh

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi