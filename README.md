# <img src="icon.png" width="30"> AHK Shortcut

[![HitCount](https://hits.dwyl.com/cornradio/ahkshortcut.svg?style=flat-square)](https://hits.dwyl.com/cornradio/ahkshortcut) （ seeyoufarm hits 没有了现在重新计数了）


AHK Shortcut 是快捷键管理工具，通过图形界面，轻松设置和管理各种快捷键操作，如打开网页、运行程序、打开文件夹、发送文本等。

![alt text](image.png)


## 功能特点

- 🚀 支持多种操作类型：
  - `link`: 打开网页链接
  - `run`: 运行程序或命令
  - `open`: 打开文件夹
  - `send`: 发送文本
  - `ahk`: 执行 AHK v2 代码 (例如 `Send(FormatTime(, "yyyy-MM-dd HH:mm:ss"))`)
- 💡 直观的图形界面
- 🔄 支持自行备份配置文件、可以快速的迁移快捷键到其他电脑
- 📄 提供 `settings-demo.example` 作为配置参考例子

## 安装

1. 前提
   - 下载并安装 [AutoHotkey v2.0](https://www.autohotkey.com/download/ahk-v2.exe)

2. 下载本项目
   - 下载并解压本项目文件到任何文件夹

3. 运行程序
   - 双击运行 `ahkshortcut.ahk` ,会在托盘中出现一个新图标 <img src="icon.png" width="10">

## 使用

1. 添加快捷键
   - 选择操作类型Type
   - 输入名称Name（可选）
   - 设置快捷键组合Hotkey (由于系统限制，不支持录制win,可手动勾选WinKey)
   - 输入Target（网址link/程序路径run/文件夹open/文本send）
   - 点击"Add"按钮 添加快捷键

2. 管理快捷键
   - 编辑：选中项目后点击"Edit"编辑快捷键,编辑后需要点击"Add"按钮保存
     - tip : 可以直接选中列表中的某个快捷键,按Enter键编辑快捷键
     - 如果你要输的内容是一个多行文本可以点击左侧的Full按钮.使用大窗输入。
   - 删除：选中项目后点击"Delete"删除快捷键

3. 设置 
   - 点击右上角设置按钮打开设置窗口
   - 设置全局快捷键(展示/隐藏快捷键管理器)
   - 设置是否启动时隐藏（Hide on Launch）
   - 设置切换配置文件

4. 过滤 filter
   - 可以通过左下角filter输入框输入名称来过滤快捷键，在你拥有很多快捷键的时候这个是很有用的。

5. Hard Reload
   - 点击Hard Reload按钮可以强制保存并重启，热键失效时候可以使用这个。
   - 右键Hard Reload按钮会直接重新从磁盘中读取配置文件，并重启，如果你直接在外部修改了配置文件settings.ini，使用这个。


## 相关推荐

如果你喜欢这个工具，你肯定是一个快捷键大师，也可以看看这些工具：

- [Alt-Drag](https://github.com/cornradio/alt-drag-mac) - 使用 Alt+鼠标调整窗口位置和大小
- [lightspeed-UI](https://github.com/cornradio/lightspeed-UI) - 管理程序、使用快捷键启动程序和文件夹

## 许可证

[MIT License](LICENSE)

## 更新日志
- 2026-01-11 增加了AHK v2.0支持，以及超多新功能。[notion update](https://www.notion.so/2e465c515f2a8002947ec21f6ca128ca)
- 2025-01-13 增加了多行文本send支持
