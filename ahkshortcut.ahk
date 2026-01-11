#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Set working directory
SetWorkingDir(A_ScriptDir)

; Include modules
#Include Lib\Actions.ahk
#Include Lib\Config.ahk
#Include Lib\Hotkeys.ahk
#Include Lib\UI.ahk
#Include Lib\Eval.ahk

; --- Tray Menu Settings ---
A_TrayMenu.Delete()
A_TrayMenu.Add("Show UI", (*) => ShortcutUI.Show())
A_TrayMenu.Add("Open Folder", (*) => Run('explore "' A_ScriptDir '"'))
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Show UI"
A_TrayMenu.ClickCount := 1

; Set Tray and Window Icon
if FileExist(A_ScriptDir "\icon.ico") {
    try TraySetIcon(A_ScriptDir "\icon.ico")
} else {
    try TraySetIcon("shell32.dll", 264)
}

; --- Initialize GUI ---
try {
    ShortcutUI.Create()
    ShortcutUI.Show() ; Force show on start for debugging
} catch Error as e {
    MsgBox("Critical Error during Init:`n`n" . e.Message . "`n`nStack:`n" . e.Stack, "Error", 16)
    ExitApp()
}
