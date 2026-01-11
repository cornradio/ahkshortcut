#Requires AutoHotkey v2.0

/**
 * Executes AHK code dynamically.
 * It creates a temporary file and runs it with the AHK interpreter.
 * @param {String} code The AHK v2 code to execute.
 */
RunAhkCode(code) {
    if (code = "")
        return

    try {
        ; Use a unique temp file to avoid conflicts
        tempFile := A_Temp "\ahk_shortcut_" . A_TickCount . ".ahk"

        ; Ensure the code has the required header
        if !InStr(code, "#Requires AutoHotkey v2.0") {
            code := "#Requires AutoHotkey v2.0`n" . code
        }

        FileAppend(code, tempFile, "UTF-8")

        ; Run the script and wait for it to finish?
        ; Better run it without waiting if it's a long script,
        ; but for "Send" actions we might want it to finish.
        ; However, "Send" doesn't return anything anyway.
        Run(A_AhkPath . ' "' . tempFile . '"')

        ; Clean up the temp file after a short delay
        ; (Can't delete immediately because AHK needs to read it)
        SetTimer(() => TryDelete(tempFile), -5000)
    } catch Error as e {
        MsgBox("Failed to execute AHK code:`n`n" . e.Message, "Error", 16)
    }
}

TryDelete(file) {
    try {
        if FileExist(file)
            FileDelete(file)
    }
}
