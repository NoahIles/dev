#! /usr/bin/env bash

set -e

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export PARENT_DIR="$(dirname "$SCRIPT_DIR")"

install(){

    # Get OS 
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID=$ID
    else
        OS_ID=$(uname -s)
    fi

    case "$OS_ID" in
        "arch"|"CachyOS Linux")
            echo "Detected Arch Linux"
            exec $SCRIPT_DIR/arch.sh
            ;;
        "fedora"|"centos"|"rhel")
            echo "Detected Fedora/RHEL-based Linux"
            echo "Not currently supported"   
            exit 1
            ;;
        "debian"|"ubuntu"|"mint")
            echo "Detected Debian/Ubuntu-based Linux"
              exec $SCRIPT_DIR/deb.sh
            ;;
        "Darwin")
            echo "Detected macOS"
            exec $SCRIPT_DIR/osx.sh 
            ;;
        *)
            echo "Unknown or unsupported OS: $OS_ID"
            exit 1
            ;;
    esac
}

showhelp(){
    printf "
Syntax:
    $0 <subcommand> [OPTIONS]... 
SubCommands:
    install     runs shared.sh and specific install for your achitecture 
    list        Lists available modules to run
    run         Run one or more modules taken as arguments or through fzf if available
    help        See This help message
    "
}



case $1 in
  # Global help
  ""|help|--help|-h)showhelp;exit;;
  # Correct subcommand
  install|list)
    SUBCMD_NAME=$1
    SUBCMD_DIR=./sdata/subcmd-$1
    shift;;
  run)
    SUBCMD_NAME=$1
    SUBCMD_DIR=./sdata/subcmd-install
    shift;;
  # Wrong subcommand
  *)printf "${STY_RED}Unknown subcommand \"$1\".${STY_RST}\n";showhelp_global;exit 1;;
esac


case ${SUBCMD_NAME} in
    install)
        install;;
    list)
        for file in $(/bin/ls ./cmd); do
            echo -n $file " "
        done;;
    run)
        echo "Unimplemented";;
        # Ensure each file is valid and run it with bash

esac

