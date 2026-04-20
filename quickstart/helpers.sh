#! /usr/bin/env bash

maybe_sudo() {
  if [ "$(id -u)" -eq 0 ] || ! command -v sudo &> /dev/null; then
    "$@"
  else
    sudo "$@"
  fi
}
