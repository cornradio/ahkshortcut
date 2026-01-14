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
    static WheelCheck := 0
    static WheelDDL := 0
    static AltCheck := 0
    static CtrlCheck := 0
    static ShiftCheck := 0
    static ConfigBtn := 0
    static ReloadBtn := 0
    static SettingsBtn := 0
    static SearchEdit := 0
    static SearchText := 0
    static ExpandBtn := 0
    static FooterText := 0
    static GithubBtnMain := 0

    ; Data store
    static AllItems := []

    ; Global App settings/state
    static CurrentAppHotkey := ""
    static HideOnLaunch := false

    static Create() {
        this.MainGui := Gui("+LastFound +Resize +MinSize850x400", "AHK Shortcut v2")
        this.MainGui.SetFont("s10", "Segoe UI")

        ; Row 1: Type, Name, Hotkey
        this.MainGui.Add("Text", "x10 y15", "Type:")
        this.TypeDDL := this.MainGui.Add("DropDownList", "x+5 yp-4 w80 Choose1", ["link", "run", "open", "send", "ahk"])

        this.MainGui.Add("Text", "x+20 yp+4", "Name:")
        this.NameEdit := this.MainGui.Add("Edit", "x+5 yp-4 w120")

        this.MainGui.Add("Text", "x+20 yp+4", "Hotkey:")
        this.HotkeyCtrl := this.MainGui.Add("Hotkey", "x+5 yp-4 w100")
        this.WheelDDL := this.MainGui.Add("DropDownList", "xp yp w100 Hidden Choose1", ["WheelUp", "WheelDown",
            "MButton"])
        this.WinCheck := this.MainGui.Add("Checkbox", "x+10 yp+4", "Win")
        this.WheelCheck := this.MainGui.Add("Checkbox", "x+5 yp", "Wheel")
        this.WheelCheck.OnEvent("Click", (*) => this.ToggleWheelMode())

        this.AltCheck := this.MainGui.Add("Checkbox", "x+5 yp Hidden", "Alt")
        this.CtrlCheck := this.MainGui.Add("Checkbox", "x+5 yp Hidden", "Ctrl")
        this.ShiftCheck := this.MainGui.Add("Checkbox", "x+5 yp Hidden", "Shift")

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
        this.ExpandBtn := this.MainGui.Add("Button", "x10 y+5 w45 h24", "Full")
        this.ExpandBtn.OnEvent("Click", (*) => ShortcutUI.ShowExpandEditor())
        this.TargetEdit := this.MainGui.Add("Edit", "x+5 y50 w630 r3 Multi WantReturn")

        ; Config buttons
        this.ConfigBtn := this.MainGui.Add("Button", "x+10 yp w100", "Edit Config")
        this.ConfigBtn.OnEvent("Click", (*) => ShortcutUI.OpenConfig())
        this.ConfigBtn.OnEvent("ContextMenu", (*) => ShortcutUI.OpenConfigFolder())
        this.ReloadBtn := this.MainGui.Add("Button", "xp y+5 w100", "Hard Reload")
        this.ReloadBtn.OnEvent("Click", (*) => ShortcutUI.RestartApp())
        this.ReloadBtn.OnEvent("ContextMenu", (*) => ShortcutUI.RestartApp(false))

        ; Table
        this.LV := this.MainGui.Add("ListView", "x10 y+15 r12 w800", ["Type", "Name", "Hotkey", "Target", "Raw"])
        this.LV.OnEvent("DoubleClick", (LV_Obj, RowNum) => ShortcutUI.ListViewDoubleClick(LV_Obj, RowNum))

        ; Search Filter (At the very bottom)
        this.SearchText := this.MainGui.Add("Text", "x10 y+10", "Filter:")
        this.SearchEdit := this.MainGui.Add("Edit", "x+5 yp-4 w200")
        this.SearchEdit.OnEvent("Change", (*) => this.RefreshListView())

        ; Footer Info (Bottom Right)
        this.FooterText := this.MainGui.Add("Text", "Center", "@cornradio v2.0")
        this.GithubBtnMain := this.MainGui.Add("Button", "w60 h24", "GitHub")
        this.GithubBtnMain.OnEvent("Click", (*) => Run("https://github.com/cornradio/ahkshortcut"))

        ; Window events
        this.MainGui.OnEvent("Close", (*) => this.MainGui.Hide())
        this.MainGui.OnEvent("Escape", (*) => this.MainGui.Hide())
        this.MainGui.OnEvent("Size", (GuiObj, MinMax, Width, Height) => this.OnSize(GuiObj, MinMax, Width, Height))

        ; Initialize
        loaded := ConfigManager.Load(this.LV, HotkeyManager)
        loadedSettings := loaded.settings
        this.AllItems := loaded.items
        this.HideOnLaunch := loadedSettings.hideOnLaunch

        if (loadedSettings.appHotkey != "") {
            this.CurrentAppHotkey := loadedSettings.appHotkey
            this.RegisterAppHotkey(loadedSettings.appHotkey)
        }

        this.RefreshListView() ; Initial fill

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
        else if (InStr(focusedCtrl.Type, "Edit") || InStr(focusedCtrl.Type, "Hotkey") || InStr(focusedCtrl.Type,
            "ComboBox") || InStr(focusedCtrl.Type, "List")) {
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

        ; --- Separator ---
        settingsGui.Add("Text", "x10 y+15 w230 h2 0x10")

        ; --- Config File Selector ---
        settingsGui.Add("Text", "x10 y+10", "Select Active Config File:")

        iniFiles := []
        loop files, A_ScriptDir "\*.ini" {
            iniFiles.Push(A_LoopFileName)
        }

        activeFile := ConfigManager.GetActiveName()
        iniDDL := settingsGui.Add("DropDownList", "x10 y+5 w230", iniFiles)
        iniDDL.Text := activeFile

        ; --- Separator ---
        settingsGui.Add("Text", "x10 y+15 w230 h2 0x10")

        btnSave := settingsGui.Add("Button", "x10 y+10 w80 Default", "Save")
        btnSave.OnEvent("Click", (*) => this.SaveSettingsFromPopup(settingsGui, hkCtrl.Value, winChk.Value, launchChk.Value,
            iniDDL.Text))

        btnCancel := settingsGui.Add("Button", "x+10 yp w80", "Cancel")
        btnCancel.OnEvent("Click", (*) => settingsGui.Destroy())

        settingsGui.Show()
    }

    static SaveSettingsFromPopup(parentGui, key, useWin, hideLaunch, activeIni) {
        newHotkey := (key != "") ? (useWin ? "#" : "") . key : ""
        if (this.CurrentAppHotkey != newHotkey) {
            if (this.CurrentAppHotkey != "")
                try Hotkey(this.CurrentAppHotkey, "Off")
            this.CurrentAppHotkey := newHotkey
            if (newHotkey != "")
                this.RegisterAppHotkey(newHotkey)
        }
        this.HideOnLaunch := hideLaunch

        ; Handle config file change
        if (activeIni != ConfigManager.GetActiveName()) {
            ConfigManager.Save(this.AllItems, this.CurrentAppHotkey, this.HideOnLaunch)
            ConfigManager.SetActiveName(activeIni)
            this.RestartApp(false) ; Reload from NEW file
            return
        }

        ConfigManager.Save(this.AllItems, this.CurrentAppHotkey, this.HideOnLaunch)
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
        this.TargetEdit.Move(, , Width - 190)
        this.ConfigBtn.Move(Width - 110)
        this.ReloadBtn.Move(Width - 110)
        this.SettingsBtn.Move(Width - 34, 10)
        this.LV.Move(, , Width - 20, Height - 180)
        this.SearchText.Move(, Height - 30)
        this.SearchEdit.Move(, Height - 34)

        this.FooterText.Move(Width - 220, Height - 30, 150)
        this.GithubBtnMain.Move(Width - 70, Height - 34)
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

    static ToggleWheelMode() {
        if this.WheelCheck.Value {
            this.HotkeyCtrl.Visible := false
            this.WheelDDL.Visible := true
            this.AltCheck.Visible := true
            this.CtrlCheck.Visible := true
            this.ShiftCheck.Visible := true
        } else {
            this.HotkeyCtrl.Visible := true
            this.WheelDDL.Visible := false
            this.AltCheck.Visible := false
            this.CtrlCheck.Visible := false
            this.ShiftCheck.Visible := false
        }
    }

    static RegisterAppHotkey(hotkeyStr) {
        Hotkey(hotkeyStr, (*) => ShortcutUI.Toggle(), "On")
    }

    static AddHotkey() {
        type := this.TypeDDL.Text
        name := this.NameEdit.Value
        target := this.TargetEdit.Value

        key := ""
        modifiers := ""
        useWin := this.WinCheck.Value

        if (this.WheelCheck.Value) {
            key := this.WheelDDL.Text
            if (this.AltCheck.Value)
                modifiers .= "!"
            if (this.CtrlCheck.Value)
                modifiers .= "^"
            if (this.ShiftCheck.Value)
                modifiers .= "+"
        } else {
            key := this.HotkeyCtrl.Value
        }

        if (target = "" || key = "") {
            MsgBox("Target and Hotkey cannot be empty")
            return
        }

        if (name = "")
            name := target

        fullHotkey := modifiers . (useWin ? "#" : "") . key

        for item in this.AllItems {
            if (item.hotkeyStr = fullHotkey) {
                MsgBox("Hotkey already in use.")
                return
            }
        }

        HotkeyManager.Register(fullHotkey, type, target)
        this.AllItems.Push({ type: type, name: name, target: target, hotkeyStr: fullHotkey })
        this.RefreshListView()

        this.NameEdit.Value := ""
        this.TargetEdit.Value := ""
        this.HotkeyCtrl.Value := ""
        this.WheelCheck.Value := 0
        this.WinCheck.Value := 0
        this.AltCheck.Value := 0
        this.CtrlCheck.Value := 0
        this.ShiftCheck.Value := 0
        this.ToggleWheelMode() ; Reset to default state
        ConfigManager.Save(this.AllItems, this.CurrentAppHotkey, this.HideOnLaunch)
    }

    static DeleteSelected() {
        row := this.LV.GetNext()
        if (row > 0) {
            hotkeyStr := this.LV.GetText(row, 5)
            HotkeyManager.Unregister(hotkeyStr)

            ; Remove from AllItems
            for i, item in this.AllItems {
                if (item.hotkeyStr == hotkeyStr) {
                    this.AllItems.RemoveAt(i)
                    break
                }
            }

            this.RefreshListView()
            ConfigManager.Save(this.AllItems, this.CurrentAppHotkey, this.HideOnLaunch)
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

            if (fullHotkey ~= "i)(WheelUp|WheelDown|MButton)$") {
                this.WheelCheck.Value := 1

                ; Extract Modifiers
                this.WinCheck.Value := InStr(fullHotkey, "#")
                this.AltCheck.Value := InStr(fullHotkey, "!")
                this.CtrlCheck.Value := InStr(fullHotkey, "^")
                this.ShiftCheck.Value := InStr(fullHotkey, "+")

                ; Clean Key
                cleanKey := fullHotkey
                cleanKey := StrReplace(cleanKey, "#", "")
                cleanKey := StrReplace(cleanKey, "!", "")
                cleanKey := StrReplace(cleanKey, "^", "")
                cleanKey := StrReplace(cleanKey, "+", "")

                this.WheelDDL.Text := cleanKey
            } else {
                ; Standard Hotkey Logic
                this.WheelCheck.Value := 0
                this.AltCheck.Value := 0
                this.CtrlCheck.Value := 0
                this.ShiftCheck.Value := 0

                if InStr(fullHotkey, "#") {
                    this.WinCheck.Value := 1
                    this.HotkeyCtrl.Value := StrReplace(fullHotkey, "#", "")
                } else {
                    this.WinCheck.Value := 0
                    this.HotkeyCtrl.Value := fullHotkey
                }
            }
            this.ToggleWheelMode()

            HotkeyManager.Unregister(fullHotkey)

            ; Remove from AllItems so it can be re-added as "new" (or updated)
            for i, item in this.AllItems {
                if (item.hotkeyStr == fullHotkey) {
                    this.AllItems.RemoveAt(i)
                    break
                }
            }

            this.RefreshListView()
            ConfigManager.Save(this.AllItems, this.CurrentAppHotkey, this.HideOnLaunch)

            ; Focus on Name field for quick editing
            this.NameEdit.Focus()
        }
    }

    static RefreshListView() {
        this.LV.Opt("-Redraw")
        this.LV.Delete()
        filter := StrLower(this.SearchEdit.Value)

        for item in this.AllItems {
            if (filter = ""
                || InStr(StrLower(item.name), filter)
                || InStr(StrLower(item.target), filter)) {
                this.LV.Add("", item.type, item.name, this.ToHuman(item.hotkeyStr), item.target, item.hotkeyStr)
            }
        }

        this.LV.ModifyCol()
        this.LV.ModifyCol(5, 0)
        this.LV.Opt("+Redraw")
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

    static OpenConfigFolder() {
        if FileExist(ConfigManager.FilePath) {
            SplitPath(ConfigManager.FilePath, , &dir)
            try Run('explorer.exe "' dir '"')
        }
    }

    static RestartApp(save := true) {
        if (save) {
            ConfigManager.Save(this.AllItems, this.CurrentAppHotkey, this.HideOnLaunch)
        }
        Reload()
    }

    static ShowExpandEditor() {
        editorGui := Gui("+Owner" . this.MainGui.Hwnd . " +Resize", "Target Full Editor")
        editorGui.SetFont("s10", "Segoe UI")

        editCtrl := editorGui.Add("Edit", "x10 y10 w580 h340 Multi WantReturn", this.TargetEdit.Value)

        btnSave := editorGui.Add("Button", "x10 y+10 w100 h30 Default", "Save && Close")
        btnSave.OnEvent("Click", (*) => (this.TargetEdit.Value := editCtrl.Value, editorGui.Destroy()))

        btnCancel := editorGui.Add("Button", "x+10 yp w100 h30", "Cancel")
        btnCancel.OnEvent("Click", (*) => editorGui.Destroy())

        ; Make it resizable
        editorGui.OnEvent("Size", (GuiObj, MinMax, Width, Height) => (
            editCtrl.Move(, , Width - 20, Height - 60),
            btnSave.Move(, Height - 40),
            btnCancel.Move(, Height - 40)
        ))

        editorGui.Show("w600 h400")
    }
}
