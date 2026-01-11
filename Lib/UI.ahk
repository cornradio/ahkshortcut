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
    static SettingsBtn := 0 

    ; Global App settings/state
    static CurrentAppHotkey := ""
    static HideOnLaunch := false

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
        this.MainGui.Add("Button", "x+10 yp-4 w60", "Add").OnEvent("Click", (*) => ShortcutUI.AddHotkey())
        this.MainGui.Add("Button", "x+10 yp w80", "Delete").OnEvent("Click", (*) => ShortcutUI.DeleteSelected())
        this.MainGui.Add("Button", "x+10 yp w80", "Edit").OnEvent("Click", (*) => ShortcutUI.EditSelected())

        ; Hidden Default Button to handle "Enter" key smartly
        this.MainGui.Add("Button", "x0 y0 w0 h0 +Default", "HiddenEnter").OnEvent("Click", (*) => ShortcutUI.OnEnterPressed())

        ; Settings Button (Strict Top Right, Small Square)
        this.SettingsBtn := this.MainGui.Add("Button", "w24 h24", "🛠")
        this.SettingsBtn.OnEvent("Click", (*) => ShortcutUI.ShowSettingsPopup())

        ; Row 2: Target
        this.MainGui.Add("Text", "x10 y+15", "Target:")
        this.TargetEdit := this.MainGui.Add("Edit", "x+5 yp w630 r3 Multi WantReturn")

        ; Config buttons
        this.ConfigBtn := this.MainGui.Add("Button", "x+10 yp w100", "Edit Config")
        this.ConfigBtn.OnEvent("Click", (*) => ShortcutUI.OpenConfig())
        this.ReloadBtn := this.MainGui.Add("Button", "xp y+5 w100", "Hard Reload")
        this.ReloadBtn.OnEvent("Click", (*) => ShortcutUI.RestartApp())

        ; Table
        this.LV := this.MainGui.Add("ListView", "x10 y+15 r12 w800", ["Type", "Name", "Hotkey", "Target", "Raw"])
        this.LV.OnEvent("DoubleClick", (LV_Obj, RowNum) => ShortcutUI.ListViewDoubleClick(LV_Obj, RowNum))

        ; Window events
        this.MainGui.OnEvent("Close", (*) => this.MainGui.Hide())
        this.MainGui.OnEvent("Escape", (*) => this.MainGui.Hide())
        this.MainGui.OnEvent("Size", (GuiObj, MinMax, Width, Height) => this.OnSize(GuiObj, MinMax, Width, Height))

        ; Initialize
        loadedSettings := ConfigManager.Load(this.LV, HotkeyManager)
        this.HideOnLaunch := loadedSettings.hideOnLaunch

        if (loadedSettings.appHotkey != "") {
            this.CurrentAppHotkey := loadedSettings.appHotkey
            this.RegisterAppHotkey(loadedSettings.appHotkey)
        }

        try {
            this.LV.ModifyCol(1, "AutoHdr")
            this.LV.ModifyCol(2, "AutoHdr")
            this.LV.ModifyCol(3, 150) ; Hotkey
            this.LV.ModifyCol(4, "AutoHdr") ; Target
            this.LV.ModifyCol(5, 0) ; Hidden RawHotkey
        }
        
        if !this.HideOnLaunch {
            this.Show()
        }
    }

    static Show() {
        if this.MainGui {
            this.MainGui.Show()
            WinActivate("ahk_id " this.MainGui.Hwnd)
        }
    }

    /**
     * Smart Enter Key Handler
     */
    static OnEnterPressed() {
        focusedCtrl := this.MainGui.FocusedCtrl
        if !focusedCtrl
            return

        ; If ListView is focused, treat as "Edit"
        if (focusedCtrl.Hwnd == this.LV.Hwnd) {
            this.EditSelected()
        } 
        ; If an Edit or Hotkey control is focused, treat as "Add"
        else if (InStr(focusedCtrl.Type, "Edit") || InStr(focusedCtrl.Type, "Hotkey") || InStr(focusedCtrl.Type, "ComboBox") || InStr(focusedCtrl.Type, "List")) {
            this.AddHotkey()
        }
    }

    static ShowSettingsPopup() {
        settingsGui := Gui("+Owner" . this.MainGui.Hwnd . " +ToolWindow", "Global Settings")
        settingsGui.SetFont("s10", "Segoe UI")

        settingsGui.Add("Text", "x10 y15", "Set Global App Show Hotkey:")

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

        launchChk := settingsGui.Add("Checkbox", "x10 y+15", "Hide on Launch")
        launchChk.Value := this.HideOnLaunch

        btnSave := settingsGui.Add("Button", "x10 y+10 w80 Default", "Save")
        btnSave.OnEvent("Click", (*) => this.SaveSettingsFromPopup(settingsGui, hkCtrl.Value, winChk.Value, launchChk.Value))

        btnCancel := settingsGui.Add("Button", "x+10 yp w80", "Cancel")
        btnCancel.OnEvent("Click", (*) => settingsGui.Destroy())

        settingsGui.Add("Text", "x10 y+10", "@cornradio v2.0 2026/01/11")
        githubBtn := settingsGui.Add("Button", "x10 y+5 w80", "GitHub")
        githubBtn.OnEvent("Click", (*) => Run("https://github.com/cornradio/ahkshortcut"))

        settingsGui.Show()
    }

    static SaveSettingsFromPopup(parentGui, key, useWin, hideLaunch) {
        newHotkey := (key != "") ? (useWin ? "#" : "") . key : ""
        if (this.CurrentAppHotkey != newHotkey) {
            if (this.CurrentAppHotkey != "")
                try Hotkey(this.CurrentAppHotkey, "Off")
            this.CurrentAppHotkey := newHotkey
            if (newHotkey != "")
                this.RegisterAppHotkey(newHotkey)
        }
        this.HideOnLaunch := hideLaunch
        ConfigManager.Save(this.LV, this.CurrentAppHotkey, this.HideOnLaunch)
        parentGui.Destroy()
        MsgBox("Settings saved.")
    }

    static ToHuman(hk) {
        if (hk = "")
            return ""
        human := ""
        workHk := hk
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
        return human . StrUpper(workHk)
    }

    static OnSize(GuiObj, MinMax, Width, Height) {
        if (MinMax = -1)
            return
        this.TargetEdit.Move(,, Width - 190) 
        this.ConfigBtn.Move(Width - 110)
        this.ReloadBtn.Move(Width - 110)
        this.SettingsBtn.Move(Width - 34, 10) 
        this.LV.Move(,, Width - 20, Height - 140)
    }

    static Toggle(*) {
        if !this.MainGui
            return
        if WinActive("ahk_id " this.MainGui.Hwnd) {
            this.MainGui.Hide()
        } else {
            this.Show()
        }
    }

    static RegisterAppHotkey(hotkeyStr) {
        Hotkey(hotkeyStr, (*) => ShortcutUI.Toggle(), "On")
    }

    static AddHotkey() {
        type := this.TypeDDL.Text
        name := this.NameEdit.Value
        target := this.TargetEdit.Value
        key := this.HotkeyCtrl.Value
        useWin := this.WinCheck.Value

        if (target = "" || key = "") {
            MsgBox("Target and Hotkey cannot be empty")
            return
        }

        if (name = "")
            name := target

        fullHotkey := (useWin ? "#" : "") . key

        loop this.LV.GetCount() {
            if (this.LV.GetText(A_Index, 5) = fullHotkey) {
                MsgBox("Hotkey already in use.")
                return
            }
        }

        HotkeyManager.Register(fullHotkey, type, target)
        this.LV.Add("", type, name, this.ToHuman(fullHotkey), target, fullHotkey)
        this.LV.ModifyCol()

        this.NameEdit.Value := ""
        this.TargetEdit.Value := ""
        this.HotkeyCtrl.Value := ""
        this.WinCheck.Value := 0
        ConfigManager.Save(this.LV, this.CurrentAppHotkey, this.HideOnLaunch)
    }

    static DeleteSelected() {
        row := this.LV.GetNext()
        if (row > 0) {
            hotkeyStr := this.LV.GetText(row, 5) 
            HotkeyManager.Unregister(hotkeyStr)
            this.LV.Delete(row)
            ConfigManager.Save(this.LV, this.CurrentAppHotkey, this.HideOnLaunch)
        }
    }

    static EditSelected() {
        row := this.LV.GetNext()
        if (row > 0) {
            type := this.LV.GetText(row, 1)
            name := this.LV.GetText(row, 2)
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
            ConfigManager.Save(this.LV, this.CurrentAppHotkey, this.HideOnLaunch)
            
            ; Focus on Name field for quick editing
            this.NameEdit.Focus()
        }
    }

    static ListViewDoubleClick(LV_Obj, RowNum) {
        if (RowNum > 0) {
            type := LV_Obj.GetText(RowNum, 1)
            target := LV_Obj.GetText(RowNum, 4)

            if (type == "send") {
                A_Clipboard := target
                ToolTip("Copied!")
                SetTimer(() => ToolTip(), -2000)
            } else {
                RunAction(type, target)
            }
        }
    }

    static OpenConfig() {
        if FileExist(ConfigManager.FilePath) {
            try Run('notepad.exe "' ConfigManager.FilePath '"')
        }
    }

    static RestartApp() {
        ConfigManager.Save(this.LV, this.CurrentAppHotkey, this.HideOnLaunch)
        Reload()
    }
}
