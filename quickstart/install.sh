#! /usr/bin/env bash
set -euo pipefail

# Use BASE_DIR from environment (set by Python CLI) or determine it from script location
[ -z "$BASE_DIR" ] && BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )
SCRIPT_DIR="$BASE_DIR/quickstart"

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
            exec "$SCRIPT_DIR/arch.sh"
            ;;
        "fedora"|"centos"|"rhel")
            echo "Detected Fedora/RHEL-based Linux"
            echo "Not currently supported"
            exit 1
            ;;
        "debian"|"ubuntu"|"mint")
            echo "Detected Debian/Ubuntu-based Linux"
            exec "$SCRIPT_DIR/deb.sh"
            ;;
        "Darwin")
            echo "Detected macOS"
            exec "$SCRIPT_DIR/osx.sh"
            ;;
        *)
            echo "Unknown or unsupported OS: $OS_ID"
            exit 1
            ;;
    esac
}
install