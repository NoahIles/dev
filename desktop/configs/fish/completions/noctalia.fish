# Helper: true when 'msg' is on the line but no msg-subcommand has been typed yet
function __noctalia_no_msg_cmd
    set -l tokens (commandline -opc)
    if not contains msg $tokens
        return 1
    end
    set -l msg_cmds \
        bar-auto-hide-set bar-hide bar-show bar-toggle \
        brightness-down brightness-set brightness-up \
        caffeine-disable caffeine-enable caffeine-toggle \
        config-reload \
        desktop-widgets-edit desktop-widgets-exit desktop-widgets-toggle-edit \
        dock-hide dock-reload dock-show dock-toggle \
        dpms-off dpms-on \
        greeter-sync \
        media \
        mic-mute mic-volume-down mic-volume-set mic-volume-up \
        nightlight-disable nightlight-enable nightlight-force-toggle nightlight-toggle \
        notification-clear-active notification-clear-history \
        notification-dnd-set notification-dnd-status notification-dnd-toggle \
        panel-close panel-open panel-toggle \
        power-cycle power-set \
        screen-lock screenshot-fullscreen screenshot-region \
        scripted-widget settings-toggle status suspend \
        templates-apply \
        theme-mode-get theme-mode-set theme-mode-toggle theme-wallpaper-scheme-set \
        volume-down volume-mute volume-set volume-up \
        wallpaper-random wallpaper-set
    for tok in $tokens
        if contains $tok $msg_cmds
            return 1
        end
    end
    return 0
end

# ── Top-level options and subcommands ─────────────────────────────────────────
complete -c noctalia -f -n "not __fish_seen_subcommand_from msg theme config" -a msg    -d "Send a command to the running instance"
complete -c noctalia -f -n "not __fish_seen_subcommand_from msg theme config" -a theme  -d "Generate a color palette from an image"
complete -c noctalia -f -n "not __fish_seen_subcommand_from msg theme config" -a config -d "Config support and replay helpers"
complete -c noctalia -f -n "not __fish_seen_subcommand_from msg theme config" -s h -l help    -d "Show help message"
complete -c noctalia -f -n "not __fish_seen_subcommand_from msg theme config" -s v -l version -d "Show version information"
complete -c noctalia -f -n "not __fish_seen_subcommand_from msg theme config" -s d -l daemon  -d "Run in background"

# ── noctalia msg subcommands ───────────────────────────────────────────────────
complete -c noctalia -f -n __noctalia_no_msg_cmd -a bar-auto-hide-set           -d "Set auto-hide state for a bar"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a bar-hide                    -d "Hide the bar and release its layout gap"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a bar-show                    -d "Show the bar"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a bar-toggle                  -d "Toggle bar visibility"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a brightness-down             -d "Decrease brightness"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a brightness-set              -d "Set brightness"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a brightness-up               -d "Increase brightness"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a caffeine-disable            -d "Disable caffeine (idle inhibitor)"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a caffeine-enable             -d "Enable caffeine (idle inhibitor)"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a caffeine-toggle             -d "Toggle caffeine (idle inhibitor)"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a config-reload               -d "Reload the config file"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a desktop-widgets-edit        -d "Open the desktop widgets editor"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a desktop-widgets-exit        -d "Close the desktop widgets editor"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a desktop-widgets-toggle-edit -d "Toggle desktop widgets edit mode"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a dock-hide                   -d "Hide the dock (persists override)"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a dock-reload                 -d "Reload dock configuration"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a dock-show                   -d "Show the dock (persists override)"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a dock-toggle                 -d "Toggle dock visibility (persists override)"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a dpms-off                    -d "Turn monitors off"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a dpms-on                     -d "Turn monitors on"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a greeter-sync                -d "Sync wallpaper and colors to Noctalia Greeter"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a media                       -d "Control active media playback"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a mic-mute                    -d "Toggle microphone mute"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a mic-volume-down             -d "Decrease microphone volume"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a mic-volume-set              -d "Set microphone volume"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a mic-volume-up               -d "Increase microphone volume"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a nightlight-disable          -d "Disable night light schedule"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a nightlight-enable           -d "Enable night light schedule"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a nightlight-force-toggle     -d "Toggle forced night light mode"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a nightlight-toggle           -d "Toggle night light schedule"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a notification-clear-active   -d "Dismiss all currently active notifications"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a notification-clear-history  -d "Clear notification history"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a notification-dnd-set        -d "Set notification Do Not Disturb state"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a notification-dnd-status     -d "Print notification Do Not Disturb state"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a notification-dnd-toggle     -d "Toggle notification Do Not Disturb state"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a panel-close                 -d "Close the active panel"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a panel-open                  -d "Open a panel by id"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a panel-toggle                -d "Toggle a panel by id"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a power-cycle                 -d "Switch to the next power profile (wraps)"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a power-set                   -d "Set the UPower power profile"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a screen-lock                 -d "Lock the session"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a screenshot-fullscreen       -d "Capture the focused monitor"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a screenshot-region           -d "Start an interactive region screenshot"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a scripted-widget             -d "Dispatch an event to a scripted bar widget"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a settings-toggle             -d "Toggle the settings window"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a status                      -d "Print current state as JSON"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a suspend                     -d "Suspend the system"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a templates-apply             -d "Apply configured theme templates for current palette"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a theme-mode-get              -d "Print the current resolved theme mode"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a theme-mode-set              -d "Set theme mode and persist to settings.toml"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a theme-mode-toggle           -d "Toggle theme mode between dark and light"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a theme-wallpaper-scheme-set  -d "Set wallpaper palette generation scheme"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a volume-down                 -d "Decrease speaker volume"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a volume-mute                 -d "Toggle speaker mute"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a volume-set                  -d "Set speaker volume"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a volume-up                   -d "Increase speaker volume"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a wallpaper-random            -d "Switch to a random wallpaper immediately"
complete -c noctalia -f -n __noctalia_no_msg_cmd -a wallpaper-set               -d "Set wallpaper for all or a specific output"

# ── noctalia msg <cmd> argument completions ────────────────────────────────────

complete -c noctalia -f \
    -n "__fish_seen_subcommand_from msg; and __fish_seen_subcommand_from bar-auto-hide-set" \
    -a "on off true false 1 0"

complete -c noctalia -f \
    -n "__fish_seen_subcommand_from msg; and __fish_seen_subcommand_from media" \
    -a "next previous toggle stop"

complete -c noctalia -f \
    -n "__fish_seen_subcommand_from msg; and __fish_seen_subcommand_from notification-dnd-set" \
    -a "on off true false 1 0"

complete -c noctalia -f \
    -n "__fish_seen_subcommand_from msg; and __fish_seen_subcommand_from power-set" \
    -a "performance balanced power-saver"

complete -c noctalia -f \
    -n "__fish_seen_subcommand_from msg; and __fish_seen_subcommand_from screenshot-fullscreen" \
    -a "pick monitor all"

complete -c noctalia -f \
    -n "__fish_seen_subcommand_from msg; and __fish_seen_subcommand_from theme-mode-set" \
    -a "dark light auto"

complete -c noctalia -f \
    -n "__fish_seen_subcommand_from msg; and __fish_seen_subcommand_from theme-wallpaper-scheme-set" \
    -a "m3-tonal-spot m3-content m3-fruit-salad m3-rainbow m3-monochrome vibrant faithful dysfunctional muted"

# brightness commands accept an optional monitor selector as first arg
complete -c noctalia -f \
    -n "__fish_seen_subcommand_from msg; and __fish_seen_subcommand_from brightness-down brightness-up brightness-set" \
    -a "current all"

# ── noctalia theme ─────────────────────────────────────────────────────────────
complete -c noctalia -f \
    -n "__fish_seen_subcommand_from theme" -l scheme -r \
    -d "Color scheme" \
    -a "m3-tonal-spot m3-content m3-fruit-salad m3-rainbow m3-monochrome vibrant faithful dysfunctional muted"
complete -c noctalia -f -n "__fish_seen_subcommand_from theme" -l dark           -d "Emit only the dark variant"
complete -c noctalia -f -n "__fish_seen_subcommand_from theme" -l light          -d "Emit only the light variant"
complete -c noctalia -f -n "__fish_seen_subcommand_from theme" -l both           -d "Emit both dark and light variants"
complete -c noctalia -f -n "__fish_seen_subcommand_from theme" -l list-templates -d "List built-in, cached, and user templates"
complete -c noctalia -f -n "__fish_seen_subcommand_from theme" -l builtin-config -d "Process the shipped built-in template catalog"
complete -c noctalia -f -n "__fish_seen_subcommand_from theme" -l default-mode -r -d "Template default mode" -a "dark light"
complete -c noctalia    -n "__fish_seen_subcommand_from theme" -l theme-json -r   -d "Load precomputed dark/light token maps from JSON"
complete -c noctalia    -n "__fish_seen_subcommand_from theme" -s o -r            -d "Write JSON to file instead of stdout"
complete -c noctalia    -n "__fish_seen_subcommand_from theme" -s r -r            -d "Render a template file to an output path"
complete -c noctalia    -n "__fish_seen_subcommand_from theme" -s c -r            -d "Process a TOML template config file"

# ── noctalia config ────────────────────────────────────────────────────────────
complete -c noctalia -f \
    -n "__fish_seen_subcommand_from config; and not __fish_seen_subcommand_from replay-report" \
    -a replay-report -d "Reconstruct config from a support report"
complete -c noctalia \
    -n "__fish_seen_subcommand_from config; and __fish_seen_subcommand_from replay-report" \
    -l target -r -d "Target directory"
complete -c noctalia -f \
    -n "__fish_seen_subcommand_from config; and __fish_seen_subcommand_from replay-report" \
    -l force     -d "Overwrite existing files"
complete -c noctalia -f \
    -n "__fish_seen_subcommand_from config; and __fish_seen_subcommand_from replay-report" \
    -l flattened -d "Reconstruct as a single flattened config.toml"
