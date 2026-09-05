function reboot-windows --description 'Set BootNext to Windows and reboot'
    # Windows renumbers EFI entries, so resolve it by name rather than hardcoding.
    set -l entry (efibootmgr | string replace -rf '^Boot(....)\*? Windows Boot Manager(\t.*)?$' '$1')[1]
    if test -z "$entry"
        echo "reboot-windows: no Windows Boot Manager EFI entry found" >&2
        return 1
    end
    pkexec efibootmgr --bootnext $entry; and systemctl reboot $argv
end
