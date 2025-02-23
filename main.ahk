#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%
; 设置GUI默认字体
Gui, Font, s10, 微软雅黑

; 设置窗口和托盘图标
; Menu, Tray, Icon, %A_ScriptDir%\icon.ico
Menu, Tray, Icon, shell32.dll, 264 ; shortcut
Gui +LastFound  ; 设置当前窗口为最后找到的窗口
hWnd := WinExist()
hIcon := DllCall("LoadImage", uint, 0, str, A_ScriptDir "\icon.ico", uint, 1, int, 0, int, 0, uint, 0x10)
SendMessage, 0x80, 0, hIcon  ; 设置大图标 (0)
SendMessage, 0x80, 1, hIcon  ; 设置小图标 (1)

; 添加托盘菜单
Menu, Tray, NoStandard  ; 移除标准托盘菜单项
Menu, Tray, Icon  ; 显示托盘图标
Menu, Tray, Add, 显示界面, ShowGui  ; 添加显示菜单项
Menu, Tray, Add, 打开脚本位置, OpenScriptLocation  ; 新增这一行
Menu, Tray, Add  ; 分隔线
Menu, Tray, Add, 退出, ExitApp  ; 添加退出菜单项
Menu, Tray, Default, 显示界面  ; 设置默认菜单项
Menu, Tray, Click, 1  ; 单击托盘图标时显示界面

; 创建GUI - 优化布局
Gui, Add, Text, x10 y10, 类型:
Gui, Add, DropDownList, x+5 yp-4 w80 vProjectType, link|run|open|send
Gui, Add, Text, x+20 yp+4, 名称:
Gui, Add, Edit, x+5 yp-4 w120 vProjectName
Gui, Add, Text, x+20 yp+4, 快捷键:

; 修改热键输入部分，添加Win键复选框
Gui, Add, Hotkey, x+5 yp-4 w100 vProjectHotkey
Gui, Add, Checkbox, x+5 yp+4 vUseWin, Win键
Gui, Add, Button, x+10 yp-4 w60 gAddHotkey, 添加
Gui, Add, Button, x+10 yp w80 gDeleteSelected, 删除所选
Gui, Add, Button, x+10 yp w80 gEditSelected, 编辑所选

; 目标输入框改为多行
Gui, Add, Text, x10 y+15, 目标:
Gui, Add, Edit, x+5 yp w650 h60 vProjectTarget Multi WantReturn

; 再开一行，配置相关按钮
; Gui, Add, Button, x10 y+10 w80 gReloadConfig, 重新加载
Gui, Add, Button, x+10 yp w80 gOpenConfig, 打开配置
Gui, Add, Button, xp y+5 w80 gRestartAHK, 重载配置
; 表格
Gui, Add, ListView, x10 y+15 r10 w800 vProjectList gListViewDoubleClick, 类型|名称|目标|快捷键

; ui 部分结束


; 从文件加载保存的设置
LoadSettings()

; 初始化时自动调整列宽
LV_ModifyCol(1, "AutoHdr")
LV_ModifyCol(2, "AutoHdr")
LV_ModifyCol(3, "AutoHdr")
LV_ModifyCol(4, "AutoHdr")

; 显示GUI
Gui, Show, w820 h400 Hide, 脚本启动器  ; 添加 Hide 参数，使窗口初始隐藏

; 在脚本开头添加（#NoEnv 之后）
settingsFile := A_ScriptDir . "\settings.ini"

return

; 加载设置
LoadSettings() {
    try {
        FileRead, settings, settings.ini
        Loop, Parse, settings, `n, `r
        {
            if (A_LoopField = "")
                continue
            fields := StrSplit(A_LoopField, "|")
            if (fields.Length() = 4) {
                ; 将 \n 转换回换行符
                name := fields[2]
                target := fields[3]
                StringReplace, name, name, \n, `n, All
                StringReplace, target, target, \n, `n, All
                
                LV_Add("", fields[1], name, target, fields[4])
                fn := Func("RunAction").Bind(fields[1], target)
                Hotkey, % fields[4], % fn
            }
        }
    }
}

; 保存设置
SaveSettings() {
    global settingsFile
    
    FileDelete, %settingsFile%
    
    GuiControl, -Redraw, ListView
    Loop % LV_GetCount() {
        LV_GetText(type, A_Index, 1)
        LV_GetText(name, A_Index, 2)
        LV_GetText(target, A_Index, 3)
        LV_GetText(hotkey, A_Index, 4)
        
        ; 将换行符替换为 \n
        StringReplace, name, name, `r`n, \n, All
        StringReplace, name, name, `n, \n, All
        StringReplace, target, target, `r`n, \n, All
        StringReplace, target, target, `n, \n, All
        
        ; 使用管道符号(|)作为分隔符
        FileAppend, %type%|%name%|%target%|%hotkey%`n, %settingsFile%
    }
    GuiControl, +Redraw, ListView
}

; 添加热键
AddHotkey:
    Gui, Submit, NoHide
    ; 如果没有输入名称，使用目标作为名称
    if (ProjectTarget && ProjectHotkey) {
        if (ProjectName = "") {
            GuiControl,, ProjectName, %ProjectTarget%
            ProjectName := ProjectTarget
        }
        
        ; 构建完整的热键字符串
        fullHotkey := (UseWin ? "#" : "") . ProjectHotkey
        
        ; 检查热键是否已存在
        hotkeyExists := false
        Loop % LV_GetCount()
        {
            LV_GetText(existingHotkey, A_Index, 4)
            if (existingHotkey = fullHotkey) {
                hotkeyExists := true
                break
            }
        }
        
        if (hotkeyExists) {
            MsgBox, 该快捷键已被使用，请选择其他快捷键。
            return
        }
        
        ; 注册新的热键
        fn := Func("RunAction").Bind(ProjectType, ProjectTarget)
        try {
            Hotkey, %fullHotkey%, %fn%
        } catch e {
            MsgBox, 16, 错误, 无法注册热键 %fullHotkey%：`n%e%
            return
        }
        
        ; 减少刷新延迟
        GuiControl, -Redraw, ListView  ; 暂时禁用ListView重绘
        LV_Add("", ProjectType, ProjectName, ProjectTarget, fullHotkey)
        GuiControl, +Redraw, ListView  ; 重新启用ListView重绘
        
        ; 清空输入框
        GuiControl,, ProjectName,
        GuiControl,, ProjectTarget,
        GuiControl,, ProjectHotkey,
        GuiControl,, UseWin, 0
        
        SaveSettings()
    }
return

; 删除选中的项目
DeleteSelected:
    row := LV_GetNext(0)
    if (row > 0) {
        LV_GetText(hotkey, row, 4)
        ; 简单地禁用热键
        try {
            Hotkey, %hotkey%, Off
        }
        LV_Delete(row)
        SaveSettings()
    }
return



; 执行动作
RunAction(type, target) {
    if (type = "link") {
        Run, %target%
        ;增加http:// 如果不包含
        if (InStr(target, "http://") = 0 && InStr(target, "https://") = 0) {
            target := "http://" target
            Run, %target%
        }
    } else if (type = "run") {
        Run, %target%
    } else if (type = "open") {
        Run, explore %target%
    } else if (type = "send") {
        SendInput, %target%
    }
}

; 显示GUI的标签
ShowGui:
    Gui, Show
return

; 关闭GUI时最小化到托盘
GuiClose:
GuiEscape:
    Gui, Hide  ; 隐藏窗口而不是退出
return

; 退出应用的标签
ExitApp:
    SaveSettings()
    ExitApp
return

; 重载配置的标签
ReloadConfig:
    ; 清空现有列表
    LV_Delete()
    
    ; 禁用所有已注册的热键
    Loop % LV_GetCount()
    {
        LV_GetText(hotkey, A_Index, 4)
        Hotkey, %hotkey%, Off
    }
    
    ; 重新加载设置
    LoadSettings()
    
    ; 调整列宽
    LV_ModifyCol(1, "AutoHdr")
    LV_ModifyCol(2, "AutoHdr")
    LV_ModifyCol(3, "AutoHdr")
    LV_ModifyCol(4, "AutoHdr")
    MsgBox, 配置已重新加载。

return

; 在文件末尾添加新的标签
OpenScriptLocation:
    Run, explore %A_ScriptDir%
return

; 在文件末尾添加新的标签
OpenConfig:
    try {
        Run, "C:\Users\kasus\AppData\Local\Programs\Microsoft VS Code\Code.exe" "%A_ScriptDir%\settings.ini"  ; 使用系统默认编辑器打开
    } catch e {
        Run, notepad "%A_ScriptDir%\settings.ini"  ; 如果失败则使用记事本作为后备选项
    }
return

EditSelected:
    row := LV_GetNext(0)
    if (row > 0) {
        LV_GetText(type, row, 1)
        LV_GetText(name, row, 2)
        LV_GetText(target, row, 3)
        LV_GetText(fullHotkey, row, 4)
        
        ; 先禁用原有热键
        fn := Func("RunAction").Bind(type, target)
        Hotkey, %fullHotkey%, Off
        
        ; 将选中项的值填充到输入框中
        GuiControl, Choose, ProjectType, %type%
        GuiControl,, ProjectName, %name%
        GuiControl,, ProjectTarget, %target%
        
        ; 处理包含Win键的热键
        if (InStr(fullHotkey, "#")) {
            GuiControl,, UseWin, 1
            StringReplace, baseHotkey, fullHotkey, #,  ; 移除 Win 键标识符
            GuiControl,, ProjectHotkey, %baseHotkey%
        } else {
            GuiControl,, UseWin, 0
            GuiControl,, ProjectHotkey, %fullHotkey%
        }
        
        ; 删除原有项
        LV_Delete(row)
        SaveSettings()
    }
return

; 在文件末尾添加新的标签
RestartAHK:
    ; 重启脚本
    Run, %A_AHKPath% "%A_ScriptFullPath%"
    ExitApp
return

; 处理ListView双击事件
ListViewDoubleClick:
    if (A_GuiEvent = "DoubleClick") {
        row := A_EventInfo
        if (row > 0) {
            LV_GetText(type, row, 1)
            LV_GetText(target, row, 3)
            RunAction(type, target)
        }
    }
return