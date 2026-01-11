#Requires AutoHotkey v2.0

class ConfigManager {
    static FilePath := A_ScriptDir "\settings.ini"

    /**
     * Load settings from file to ListView
     */
    static Load(LV, HotkeyMgr) {
        if !FileExist(this.FilePath)
            return ""

        globalShowKey := ""
        try {
            content := FileRead(this.FilePath, "UTF-8")
            loop parse, content, "`n", "`r" {
                if (A_LoopField = "")
                    continue

                fields := StrSplit(A_LoopField, "|")

                ; Special case for global app hotkey
                if (fields[1] = "APP_HOTKEY") {
                    globalShowKey := fields[2]
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
        return globalShowKey
    }

    /**
     * Save ListView content and global settings to file
     */
    static Save(LV, globalShowKey := "") {
        try {
            fileContent := ""

            ; Save global show key first
            if (globalShowKey != "") {
                fileContent .= "APP_HOTKEY|" . globalShowKey . "`n"
            }

            loop LV.GetCount() {
                type := LV.GetText(A_Index, 1)
                name := LV.GetText(A_Index, 2)
                ; target is at col 4
                target := LV.GetText(A_Index, 4)
                ; raw hotkey is at col 5
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
