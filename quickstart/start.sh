#! /usr/bin/env bash

export SHARED_APPS=(fish )
# export MAC_APPS=("")
# export PARU_APPS=()


export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export PARENT_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
else
    OS_ID=$(uname -s)
fi


$SCRIPT_DIR/shared.sh

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