#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%
; ����GUIĬ������
Gui, Font, s10, ΢���ź�

;icon 
Menu, Tray, Icon, %A_ScriptDir%\icon.png
; ���ô���ͼ��Ϊ��ͬ��ͼ��
Gui, +LastFound +OwnDialogs
hIcon := LoadPicture(A_ScriptDir "\icon.png", "w32 h32", ErrorLevel)
SendMessage, 0x80, 1, hIcon  ; 0x80 �� WM_SETICON

; ������̲˵�
Menu, Tray, NoStandard  ; �Ƴ���׼���̲˵���
Menu, Tray, Icon  ; ��ʾ����ͼ��
Menu, Tray, Add, ��ʾ����, ShowGui  ; �����ʾ�˵���
Menu, Tray, Add, �򿪽ű�λ��, OpenScriptLocation  ; ������һ��
Menu, Tray, Add  ; �ָ���
Menu, Tray, Add, �˳�, ExitApp  ; ����˳��˵���
Menu, Tray, Default, ��ʾ����  ; ����Ĭ�ϲ˵���
Menu, Tray, Click, 1  ; ��������ͼ��ʱ��ʾ����

; ����GUI - �Ż�����
Gui, Add, Text, x10 y10, ����:
Gui, Add, DropDownList, x+5 yp-4 w80 vProjectType, link|run|open|send
Gui, Add, Text, x+20 yp+4, ����:
Gui, Add, Edit, x+5 yp-4 w120 vProjectName
Gui, Add, Text, x+20 yp+4, ��ݼ�:

; �޸��ȼ����벿�֣����Win����ѡ��
Gui, Add, Hotkey, x+5 yp-4 w100 vProjectHotkey
Gui, Add, Checkbox, x+5 yp+4 vUseWin, Win��
Gui, Add, Button, x+10 yp-4 w60 gAddHotkey, ���
Gui, Add, Button, x+10 yp w80 gDeleteSelected, ɾ����ѡ
Gui, Add, Button, x+10 yp w80 gEditSelected, �༭��ѡ

; Ŀ������򵥶�һ�У���Ϊͨ����Ҫ�ϳ�������
Gui, Add, Text, x10 y+15, Ŀ��:
Gui, Add, Edit, x+5 yp-4 w650 vProjectTarget

; ���
Gui, Add, ListView, x10 y+20 r23 w800 vProjectList , ����|����|Ŀ��|��ݼ�

; �ٿ�һ�У�������ذ�ť
Gui, Add, Button, x10 y+10 w80 gReloadConfig, ���¼���
Gui, Add, Button, x+10 yp w80 gOpenConfig, ������

; ui ���ֽ���


; ���ļ����ر��������
LoadSettings()

; ��ʼ��ʱ�Զ������п�
LV_ModifyCol(1, "AutoHdr")
LV_ModifyCol(2, "AutoHdr")
LV_ModifyCol(3, "AutoHdr")
LV_ModifyCol(4, "AutoHdr")

; ��ʾGUI
Gui, Show, w820 h700, �ű�������
return

; ��������
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

; ��������
SaveSettings() {
    FileDelete, settings.ini
    Loop % LV_GetCount()
    {
        LV_GetText(type, A_Index, 1)
        LV_GetText(name, A_Index, 2)
        LV_GetText(target, A_Index, 3)
        LV_GetText(hotkey, A_Index, 4)
        FileAppend, %type%|%name%|%target%|%hotkey%`n, settings.ini
    }
}

; ����ȼ�
AddHotkey:
    Gui, Submit, NoHide
    ; ���û���������ƣ�ʹ��Ŀ����Ϊ����
    if (ProjectTarget && ProjectHotkey) {
        if (ProjectName = "") {
            GuiControl,, ProjectName, %ProjectTarget%
            ProjectName := ProjectTarget
        }
        
        ; �����������ȼ��ַ���
        fullHotkey := (UseWin ? "#" : "") . ProjectHotkey
        
        ; ����ȼ��Ƿ��Ѵ���
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
            MsgBox, �ÿ�ݼ��ѱ�ʹ�ã���ѡ��������ݼ���
            return
        }
        
        ; ��ӵ��б���ͼ��ʹ���������ȼ��ַ���
        LV_Add("", ProjectType, ProjectName, ProjectTarget, fullHotkey)
        
        ; �����ȼ�
        fn := Func("RunAction").Bind(ProjectType, ProjectTarget)
        Hotkey, %fullHotkey%, % fn
        
        ; ��������
        GuiControl,, ProjectName,
        GuiControl,, ProjectTarget,
        GuiControl,, ProjectHotkey,
        GuiControl,, UseWin, 0
        
        ; �Զ���������
        SaveSettings()
        
        ; �����п�
        LV_ModifyCol(1, "AutoHdr")
        LV_ModifyCol(2, "AutoHdr")
        LV_ModifyCol(3, "AutoHdr")
        LV_ModifyCol(4, "AutoHdr")
    }
return

; ɾ��ѡ�е���Ŀ
DeleteSelected:
    row := LV_GetNext(0)
    if (row > 0) {
        LV_GetText(hotkey, row, 4)
        Hotkey, %hotkey%, Off  ; ���ø��ȼ�
        LV_Delete(row)
        SaveSettings()
    }
return

; ִ�ж���
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

; ��ʾGUI�ı�ǩ
ShowGui:
    Gui, Show
return

; �ر�GUIʱ��С��������
GuiClose:
GuiEscape:
    Gui, Hide  ; ���ش��ڶ������˳�
return

; �˳�Ӧ�õı�ǩ
ExitApp:
    SaveSettings()
    ExitApp
return

; �������õı�ǩ
ReloadConfig:
    ; ��������б�
    LV_Delete()
    
    ; ����������ע����ȼ�
    Loop % LV_GetCount()
    {
        LV_GetText(hotkey, A_Index, 4)
        Hotkey, %hotkey%, Off
    }
    
    ; ���¼�������
    LoadSettings()
    
    ; �����п�
    LV_ModifyCol(1, "AutoHdr")
    LV_ModifyCol(2, "AutoHdr")
    LV_ModifyCol(3, "AutoHdr")
    LV_ModifyCol(4, "AutoHdr")
    MsgBox, ���������¼��ء�

return

; ���ļ�ĩβ����µı�ǩ
OpenScriptLocation:
    Run, explore %A_ScriptDir%
return

; ���ļ�ĩβ����µı�ǩ
OpenConfig:
    Run, notepad %A_ScriptDir%\settings.ini
return

EditSelected:
    row := LV_GetNext(0)
    if (row > 0) {
        LV_GetText(type, row, 1)
        LV_GetText(name, row, 2)
        LV_GetText(target, row, 3)
        LV_GetText(fullHotkey, row, 4)
        
        ; �Ƚ���ԭ���ȼ�
        fn := Func("RunAction").Bind(type, target)
        Hotkey, %fullHotkey%, Off
        
        ; ��ѡ�����ֵ��䵽�������
        GuiControl, Choose, ProjectType, %type%
        GuiControl,, ProjectName, %name%
        GuiControl,, ProjectTarget, %target%
        
        ; �������Win�����ȼ�
        if (InStr(fullHotkey, "#")) {
            GuiControl,, UseWin, 1
            StringReplace, baseHotkey, fullHotkey, #,  ; �Ƴ� Win ����ʶ��
            GuiControl,, ProjectHotkey, %baseHotkey%
        } else {
            GuiControl,, UseWin, 0
            GuiControl,, ProjectHotkey, %fullHotkey%
        }
        
        ; ɾ��ԭ����
        LV_Delete(row)
        SaveSettings()
    }
return