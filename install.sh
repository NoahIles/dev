#!/usr/bin/env bash
set -euo pipefail

DEST="$HOME/dev"

if [ -d "$DEST" ]; then
    echo "› $DEST already exists, skipping clone"
else
    echo "› Cloning dev..."
    git clone https://github.com/NoahIles/dev.git "$DEST"
fi

exec "$DEST/start" install
