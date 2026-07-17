#!/usr/bin/env nu

# niri output manager — nushell port of niri-manage-outputs (bash), for evaluation.
# Structured-data version: niri's JSON is filtered with native `where`, no jq.

# niri returns outputs as a record keyed by connector; `values` -> list of outputs.
def outputs [] {
    niri msg --json outputs | from json | values
}

# Active outputs have a non-null current_mode; inactive ones are null.
def by-state [state: string] {
    if $state == "active" {
        outputs | where current_mode != null
    } else {
        outputs | where current_mode == null
    }
}

# Prompt for one output of the given state, return its connector name (port).
def select-output [state: string] {
    let outs = (by-state $state)
    if ($outs | is-empty) {
        notify-send "Error" $"No ($state) outputs found"
        exit 1
    }
    let names = ($outs | each {|o| $"($o.make) ($o.model)" })
    let selected = if ($names | length) > 1 {
        $names | str join "\n" | fuzzel --dmenu --prompt "Select output: " | str trim
    } else {
        $names | first
    }
    if ($selected | is-empty) { exit 1 }
    $outs | where {|o| $"($o.make) ($o.model)" == $selected } | get 0.name
}

def enable [] {
    # No quoting needed for spaces in $port — nu passes vars as single args.
    niri msg output (select-output "inactive") on
}

def disable [] {
    niri msg output (select-output "active") off
}

def scale [] {
    let port = (select-output "active")
    let value = ("1.0\n1.25\n1.5\n1.75\n2.0" | fuzzel --dmenu --prompt "Scale: " | str trim)
    if ($value | is-empty) { exit 0 }
    niri msg output $port scale $value
}

def brightness [] {
    let port = (select-output "active")
    let value = ("5\n15\n50\n75\n85\n95" | fuzzel --dmenu --prompt "Brightness %: " | str trim)
    if ($value | is-empty) { exit 0 }
    noctalia msg brightness-set $port $value
}

def nightlight [] {
    noctalia msg nightlight-toggle
}

def main [] {
    let active = (by-state "active" | length)
    let inactive = (by-state "inactive" | length)

    let actions = (
        ["scale" "brightness" "nightlight"]
        | (if $active > 1 { prepend "disable" } else { $in })
        | (if $inactive > 0 { prepend "enable" } else { $in })
    )

    let action = ($actions | str join "\n" | fuzzel --dmenu --prompt "Output action: " | str trim)
    match $action {
        "disable" => (disable)
        "enable" => (enable)
        "scale" => (scale)
        "brightness" => (brightness)
        "nightlight" => (nightlight)
        _ => (exit 0)
    }
}
