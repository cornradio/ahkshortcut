#Requires AutoHotkey v2.0

/**
 * Execute defined action
 * @param type (link, run, open, send)
 * @param target Target content
 */
RunAction(type, target, *) {
    switch type {
        case "link":
            ; Add http:// if no protocol header
            if !InStr(target, "://") {
                finalTarget := "http://" . target
            } else {
                finalTarget := target
            }
            try {
                Run(finalTarget)
            } catch {
                Run(target) ; Try direct run if failed
            }

        case "run":
            try {
                Run(target)
            } catch Error as e {
                MsgBox("Run Failed: " . target . "`n`n" . e.Message, "Error", 16)
            }

        case "open":
            try {
                Run('explore "' . target . '"')
            } catch Error as e {
                MsgBox("Cannot open directory: " . target . "`n`n" . e.Message, "Error", 16)
            }

        case "send":
            SendInput(target)
    }
}
