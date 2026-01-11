#Requires AutoHotkey v2.0

class ConfigManager {
    static FilePath := A_ScriptDir "\settings.ini"

    /**
     * Load settings from file to ListView
     * Returns an object {appHotkey: str, hideOnLaunch: bool}
     */
    static Load(LV, HotkeyMgr) {
        settings := { appHotkey: "", hideOnLaunch: false }
        if !FileExist(this.FilePath)
            return settings

        try {
            content := FileRead(this.FilePath, "UTF-8")
            loop parse, content, "`n", "`r" {
                if (A_LoopField = "")
                    continue

                fields := StrSplit(A_LoopField, "|")

                ; Special case for global app hotkey
                if (fields[1] = "APP_HOTKEY") {
                    settings.appHotkey := fields[2]
                    continue
                }

                ; Special case for hide on launch
                if (fields[1] = "HIDE_ON_LAUNCH") {
                    settings.hideOnLaunch := (fields[2] = "1")
                    continue
                }

                if (fields.Length >= 4) {
                    type := fields[1]
                    name := StrReplace(fields[2], "\n", "`n")
                    target := StrReplace(fields[3], "\n", "`n")
                    hotkeyStr := fields[4]

                    ; Add to LV: [Type, Name, Hotkey(Human), Target, RawHotkey(Hidden)]
                    LV.Add("", type, name, ShortcutUI.ToHuman(hotkeyStr), target, hotkeyStr)
                    HotkeyMgr.Register(hotkeyStr, type, target)
                }
            }
        } catch Error as e {
            MsgBox("Failed to load config: " . e.Message, "Error", 16)
        }
        return settings
    }

    /**
     * Save ListView content and global settings to file
     */
    static Save(LV, appHotkey := "", hideOnLaunch := false) {
        try {
            fileContent := ""

            ; Save global settings first
            if (appHotkey != "") {
                fileContent .= "APP_HOTKEY|" . appHotkey . "`n"
            }
            fileContent .= "HIDE_ON_LAUNCH|" . (hideOnLaunch ? "1" : "0") . "`n"

            loop LV.GetCount() {
                type := LV.GetText(A_Index, 1)
                name := LV.GetText(A_Index, 2)
                target := LV.GetText(A_Index, 4)
                hotkeyStr := LV.GetText(A_Index, 5)

                ; Convert newlines to \n for storage
                cleanName := StrReplace(StrReplace(name, "`r`n", "\n"), "`n", "\n")
                cleanTarget := StrReplace(StrReplace(target, "`r`n", "\n"), "`n", "\n")

                fileContent .= type "|" cleanName "|" cleanTarget "|" hotkeyStr "`n"
            }

            if FileExist(this.FilePath)
                FileDelete(this.FilePath)
            FileAppend(fileContent, this.FilePath, "UTF-8")
        } catch Error as e {
            MsgBox("Failed to save config: " e.Message, "Error", 16)
        }
    }
}
