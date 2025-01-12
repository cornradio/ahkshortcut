#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%
; 设置GUI默认字体
Gui, Font, s10, 微软雅黑

;icon 
Menu, Tray, Icon, %A_ScriptDir%\icon.png
; 设置窗口图标为相同的图标
Gui, +LastFound +OwnDialogs
hIcon := LoadPicture(A_ScriptDir "\icon.png", "w32 h32", ErrorLevel)
SendMessage, 0x80, 1, hIcon  ; 0x80 是 WM_SETICON

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

; 目标输入框单独一行，因为通常需要较长的输入
Gui, Add, Text, x10 y+15, 目标:
Gui, Add, Edit, x+5 yp-4 w650 vProjectTarget

; 表格
Gui, Add, ListView, x10 y+20 r23 w800 vProjectList , 类型|名称|目标|快捷键

; 再开一行，配置相关按钮
; Gui, Add, Button, x10 y+10 w80 gReloadConfig, 重新加载
Gui, Add, Button, x10 y+10 w80 gOpenConfig, 打开配置
Gui, Add, Button, x+10 yp w80 gRestartAHK, 重载配置
; ui 部分结束


; 从文件加载保存的设置
LoadSettings()

; 初始化时自动调整列宽
LV_ModifyCol(1, "AutoHdr")
LV_ModifyCol(2, "AutoHdr")
LV_ModifyCol(3, "AutoHdr")
LV_ModifyCol(4, "AutoHdr")

; 显示GUI
Gui, Show, w820 h700, 脚本启动器
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
                LV_Add("", fields[1], fields[2], fields[3], fields[4])
                fn := Func("RunAction").Bind(fields[1], fields[3])
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
        FileAppend, %type%`t%name%`t%target%`t%hotkey%`n, %settingsFile%
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
        Hotkey, %hotkey%, Off  ; 禁用该热键
        LV_Delete(row)
        SaveSettings()
    }
return

; 执行动作
RunAction(type, target) {
    if (type = "link") {
        Run, %target%
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
    ; 保存当前设置
    SaveSettings()
    ; 重启脚本
    Run, %A_AHKPath% "%A_ScriptFullPath%"
    ExitApp
return