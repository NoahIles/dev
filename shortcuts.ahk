#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
^!Numpad1::
    Run, cmd.exe /C start /min nircmd setdefaultsounddevice scarlet 1
    return
^!Numpad2::
    Run, cmd.exe /C start /min nircmd setdefaultsounddevice scarlet 2
    return
^!Numpad4::
    Run, cmd.exe /C start /min nircmd setdefaultsounddevice behringer 1
    return
^!Numpad5::
    Run, cmd.exe /C start /min nircmd setdefaultsounddevice behringer 2
    return