# This is for Vi Bindings and settings
#
set -g fish_key_bindings fish_vi_key_bindings

# Use --no-erase to preserve key bindings from fisher plugins
fish_vi_key_bindings --no-erase insert

# Fish Cursor settings
set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_replace_one underscore
set fish_cursor_replace underscore
set fish_cursor_external line 
set fish_cursor_visual block

