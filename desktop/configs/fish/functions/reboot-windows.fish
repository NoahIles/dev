function reboot-windows --wraps='pkexec efibootmgr --bootnext 0001; and systemctl reboot' --description 'alias reboot-windows pkexec efibootmgr --bootnext 0001; and systemctl reboot'
    pkexec efibootmgr --bootnext 0001; and systemctl reboot $argv
end
