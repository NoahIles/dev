#! /usr/bin/env bash
# install fisher 
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

fisher install jhillyerd/plugin-git

if command -v docker >/dev/null 2>&1; then
  fisher install asim-tahir/docker-compose
fi