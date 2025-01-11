#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%
; ����GUIĬ������
Gui, Font, s10, ΢���ź�

;icon 
Menu, Tray, Icon, %A_ScriptDir%\icon.png
; ������̲˵�
Menu, Tray, NoStandard  ; �Ƴ���׼���̲˵���
Menu, Tray, Icon  ; ��ʾ����ͼ��
Menu, Tray, Add, ��ʾ����, ShowGui  ; �����ʾ�˵���
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
Gui, Add, Button, x+10 yp w80 gReloadConfig, ���¼���

; Ŀ������򵥶�һ�У���Ϊͨ����Ҫ�ϳ�������
Gui, Add, Text, x10 y+15, Ŀ��:
Gui, Add, Edit, x+5 yp-4 w650 vProjectTarget

; ��������ռ�
Gui, Add, ListView, x10 y+20 r40 w800 vProjectList, ����|����|Ŀ��|��ݼ�

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
        GuiControl,, ProjectName
        GuiControl,, ProjectTarget
        GuiControl,, ProjectHotkey
        GuiControl,, UseWin
        
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