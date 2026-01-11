#Requires AutoHotkey v2.0

class HotkeyManager {
    static Registered := Map()

    /**
     * Register a new hotkey
     */
    static Register(hotkeyStr, type, target) {
        if (hotkeyStr = "")
            return

        try {
            ; Use Bind for preset parameters
            fn := RunAction.Bind(type, target)
            Hotkey(hotkeyStr, fn, "On")
            this.Registered[hotkeyStr] := fn
        } catch Error as e {
            MsgBox("Failed to register hotkey [" hotkeyStr "]: " e.Message, "Warning", 48)
        }
    }

    /**
     * Unregister a hotkey
     */
    static Unregister(hotkeyStr) {
        if (hotkeyStr = "")
            return

        try {
            Hotkey(hotkeyStr, "Off")
            if this.Registered.Has(hotkeyStr)
                this.Registered.Delete(hotkeyStr)
        } catch {
            ; Ignore if cannot unregister
        }
    }

    /**
     * Unregister all hotkeys
     */
    static UnregisterAll() {
        for hotkeyStr, _ in this.Registered {
            try {
                Hotkey(hotkeyStr, "Off")
            } catch {
            }
        }
        this.Registered := Map()
    }
}
