#Requires AutoHotkey v2.0

class ShortcutUI {
    static MainGui := 0
    static LV := 0

    ; Control variables
    static TypeDDL := 0
    static NameEdit := 0
    static HotkeyCtrl := 0
    static TargetEdit := 0
    static WinCheck := 0
    static ConfigBtn := 0
    static ReloadBtn := 0
    static GbBtn := 0

    ; Global App Hotkey state
    static CurrentAppHotkey := ""

    static Create() {
        this.MainGui := Gui("+LastFound +Resize +MinSize850x400", "AHK Shortcut v2")
        this.MainGui.SetFont("s10", "Segoe UI")

        ; Row 1: Type, Name, Hotkey
        this.MainGui.Add("Text", "x10 y15", "Type:")
        this.TypeDDL := this.MainGui.Add("DropDownList", "x+5 yp-4 w80 Choose1", ["link", "run", "open", "send"])

        this.MainGui.Add("Text", "x+20 yp+4", "Name:")
        this.NameEdit := this.MainGui.Add("Edit", "x+5 yp-4 w120")

        this.MainGui.Add("Text", "x+20 yp+4", "Hotkey:")
        this.HotkeyCtrl := this.MainGui.Add("Hotkey", "x+5 yp-4 w100")
        this.WinCheck := this.MainGui.Add("Checkbox", "x+5 yp+4", "Win Key")

        ; Row 1 Buttons
        this.MainGui.Add("Button", "x+10 yp-4 w60 Default", "Add").OnEvent("Click", (*) => ShortcutUI.AddHotkey())
        this.MainGui.Add("Button", "x+10 yp w80", "Delete").OnEvent("Click", (*) => ShortcutUI.DeleteSelected())
        this.MainGui.Add("Button", "x+10 yp w80", "Edit").OnEvent("Click", (*) => ShortcutUI.EditSelected())

        ; "Gb" Global Settings Button (Placed at top right eventually via OnSize)
        this.GbBtn := this.MainGui.Add("Button", "x+10 yp w40", "Gb")
        this.GbBtn.OnEvent("Click", (*) => ShortcutUI.ShowSettingsPopup())

        ; Row 2: Target
        this.MainGui.Add("Text", "x10 y+15", "Target:")
        this.TargetEdit := this.MainGui.Add("Edit", "x+5 yp w630 r3 Multi WantReturn")

        ; Config buttons
        this.ConfigBtn := this.MainGui.Add("Button", "x+10 yp w100", "Edit Config")
        this.ConfigBtn.OnEvent("Click", (*) => ShortcutUI.OpenConfig())
        this.ReloadBtn := this.MainGui.Add("Button", "xp y+5 w100", "Hard Reload")
        this.ReloadBtn.OnEvent("Click", (*) => ShortcutUI.RestartApp())

        ; Table: [Type, Name, Hotkey, Target, RawHotkey]
        this.LV := this.MainGui.Add("ListView", "x10 y+15 r12 w800", ["Type", "Name", "Hotkey", "Target", "Raw"])
        this.LV.OnEvent("DoubleClick", (LV_Obj, RowNum) => ShortcutUI.ListViewDoubleClick(LV_Obj, RowNum))

        ; Window events
        this.MainGui.OnEvent("Close", (*) => this.MainGui.Hide())
        this.MainGui.OnEvent("Escape", (*) => this.MainGui.Hide())
        this.MainGui.OnEvent("Size", (GuiObj, MinMax, Width, Height) => this.OnSize(GuiObj, MinMax, Width, Height))

        ; Initialize
        savedAppHotkey := ConfigManager.Load(this.LV, HotkeyManager)
        if (savedAppHotkey != "") {
            this.CurrentAppHotkey := savedAppHotkey
            this.RegisterAppHotkey(savedAppHotkey)
        }

        try {
            this.LV.ModifyCol(1, "AutoHdr")
            this.LV.ModifyCol(2, "AutoHdr")
            this.LV.ModifyCol(3, 150) ; Hotkey
            this.LV.ModifyCol(4, "AutoHdr") ; Target
            this.LV.ModifyCol(5, 0) ; Hidden RawHotkey
        }
    }

    static Show() {
        if this.MainGui {
            this.MainGui.Show()
            WinActivate("ahk_id " this.MainGui.Hwnd)
        }
    }

    static ShowSettingsPopup() {
        settingsGui := Gui("+Owner" . this.MainGui.Hwnd . " +ToolWindow", "Global Settings")
        settingsGui.SetFont("s10", "Segoe UI")

        settingsGui.Add("Text", "x10 y15", "Set Global App Show Hotkey:")

        ; Pre-fill current state
        hotkeyStr := this.CurrentAppHotkey
        parsedKey := ""
        useWin := 0

        if InStr(hotkeyStr, "#") {
            useWin := 1
            parsedKey := StrReplace(hotkeyStr, "#", "")
        } else {
            parsedKey := hotkeyStr
        }

        hkCtrl := settingsGui.Add("Hotkey", "x10 y+10 w150", parsedKey)
        winChk := settingsGui.Add("Checkbox", "x+10 yp+4", "Win Key")
        winChk.Value := useWin

        btnSave := settingsGui.Add("Button", "x10 y+20 w80 Default", "Save")
        btnSave.OnEvent("Click", (*) => this.SaveAppHotkeyFromPopup(settingsGui, hkCtrl.Value, winChk.Value))

        btnCancel := settingsGui.Add("Button", "x+10 yp w80", "Cancel")
        btnCancel.OnEvent("Click", (*) => settingsGui.Destroy())

        settingsGui.Show()
    }

    static SaveAppHotkeyFromPopup(parentGui, key, useWin) {
        if (key = "") {
            if (this.CurrentAppHotkey != "") {
                Hotkey(this.CurrentAppHotkey, "Off")
                this.CurrentAppHotkey := ""
                ConfigManager.Save(this.LV, "")
                MsgBox("Global Hotkey cleared.")
            }
        } else {
            newHotkey := (useWin ? "#" : "") . key
            try {
                this.RegisterAppHotkey(newHotkey)
                this.CurrentAppHotkey := newHotkey
                ConfigManager.Save(this.LV, newHotkey)
                MsgBox("Global App Hotkey set to: " . newHotkey)
            } catch Error as e {
                MsgBox("Failed to set Global Hotkey: " . e.Message)
                return
            }
        }
        parentGui.Destroy()
    }

    ; Utility to convert AHK hotkey symbols to human readable text
    static ToHuman(hk) {
        if (hk = "")
            return ""
        
        human := ""
        workHk := hk
        
        ; Replace modifiers
        if InStr(workHk, "#") {
            human .= "Win + "
            workHk := StrReplace(workHk, "#", "")
        }
        if InStr(workHk, "!") {
            human .= "Alt + "
            workHk := StrReplace(workHk, "!", "")
        }
        if InStr(workHk, "^") {
            human .= "Ctrl + "
            workHk := StrReplace(workHk, "^", "")
        }
        if InStr(workHk, "+") {
            human .= "Shift + "
            workHk := StrReplace(workHk, "+", "")
        }
        
        ; Append the actual key
        human .= workHk
        return human
    }

    ;anchor logic
    static OnSize(GuiObj, MinMax, Width, Height) {
        if (MinMax = -1)
            return

        ; Resize Target Edit (Label starts at 10, Edit at approx 65)
        ; We want it to end before the buttons (which start at Width - 110)
        this.TargetEdit.Move(,, Width - 190) 

        ; Move Config/Reload/Gb Buttons to the right (10px margin)
        ; GbBtn width is 40 -> Width - 50
        ; Config/Reload width is 100 -> Width - 110
        this.ConfigBtn.Move(Width - 110)
        this.ReloadBtn.Move(Width - 110)
        this.GbBtn.Move(Width - 50) 

        ; Resize ListView (140 is the fixed height of top controls)
        this.LV.Move(,, Width - 20, Height - 140)
    }

    static RegisterAppHotkey(hotkeyStr) {
        if (this.CurrentAppHotkey != "") {
            try Hotkey(this.CurrentAppHotkey, "Off")
        }
        Hotkey(hotkeyStr, (*) => ShortcutUI.Show(), "On")
    }

    static AddHotkey() {
        type := this.TypeDDL.Text
        name := this.NameEdit.Value
        target := this.TargetEdit.Value
        key := this.HotkeyCtrl.Value
        useWin := this.WinCheck.Value

        if (target = "" || key = "") {
            MsgBox("Target and Hotkey cannot be empty", "Reminder")
            return
        }

        if (name = "")
            name := target

        fullHotkey := (useWin ? "#" : "") . key

        loop this.LV.GetCount() {
            ; Check against raw hotkey in col 5
            if (this.LV.GetText(A_Index, 5) = fullHotkey) {
                MsgBox("Hotkey already in use.", "Conflict")
                return
            }
        }

        HotkeyManager.Register(fullHotkey, type, target)
        ; Add to LV: [Type, Name, Hotkey(Human), Target, RawHotkey]
        this.LV.Add("", type, name, this.ToHuman(fullHotkey), target, fullHotkey)
        this.LV.ModifyCol()

        this.NameEdit.Value := ""
        this.TargetEdit.Value := ""
        this.HotkeyCtrl.Value := ""
        this.WinCheck.Value := 0
        ConfigManager.Save(this.LV, this.CurrentAppHotkey)
    }

    static DeleteSelected() {
        row := this.LV.GetNext()
        if (row > 0) {
            hotkeyStr := this.LV.GetText(row, 5) ; RawHotkey is at 5
            HotkeyManager.Unregister(hotkeyStr)
            this.LV.Delete(row)
            ConfigManager.Save(this.LV, this.CurrentAppHotkey)
        }
    }

    static EditSelected() {
        row := this.LV.GetNext()
        if (row > 0) {
            type := this.LV.GetText(row, 1)
            name := this.LV.GetText(row, 2)
            ; Hotkey human is at 3, Target is at 4, Raw is at 5
            target := this.LV.GetText(row, 4)
            fullHotkey := this.LV.GetText(row, 5)

            this.TypeDDL.Text := type
            this.NameEdit.Value := name
            this.TargetEdit.Value := target

            if InStr(fullHotkey, "#") {
                this.WinCheck.Value := 1
                this.HotkeyCtrl.Value := StrReplace(fullHotkey, "#", "")
            } else {
                this.WinCheck.Value := 0
                this.HotkeyCtrl.Value := fullHotkey
            }

            HotkeyManager.Unregister(fullHotkey)
            this.LV.Delete(row)
            ConfigManager.Save(this.LV, this.CurrentAppHotkey)
        }
    }

    static ListViewDoubleClick(LV_Obj, RowNum) {
        if (RowNum > 0) {
            type := LV_Obj.GetText(RowNum, 1)
            target := LV_Obj.GetText(RowNum, 4) ; Target is now at 4

            if (type == "send") {
                A_Clipboard := target
                ToolTip("Copied to clipboard!")
                SetTimer(() => ToolTip(), -2000)
            } else {
                RunAction(type, target)
            }
        }
    }

    static OpenConfig() {
        if FileExist(ConfigManager.FilePath) {
            try {
                Run('notepad.exe "' ConfigManager.FilePath '"')
            } catch {
                MsgBox("Cannot open settings.ini", "Error")
            }
        }
    }

    static RestartApp() {
        ConfigManager.Save(this.LV, this.CurrentAppHotkey)
        Reload()
    }
}
