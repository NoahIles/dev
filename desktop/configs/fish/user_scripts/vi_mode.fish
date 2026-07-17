# This is for Vi Bindings and settings
#
# Set the variable first so plugins like fish_ai can detect vi mode
set -g fish_key_bindings fish_vi_key_bindings

# Use --no-erase to preserve key bindings from fisher plugins (like fish_ai)
fish_vi_key_bindings --no-erase insert

# Re-bind fish_ai keys now that fish_key_bindings is set
# This is needed because conf.d/fish_ai.fish runs before config.fish
if functions -q _fish_ai_bind
    _fish_ai_bind
end

# Fish Cursor settings
set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_replace_one underscore
set fish_cursor_replace underscore
set fish_cursor_external line 
set fish_cursor_visual block

