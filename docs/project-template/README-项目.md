# <PROJECT_NAME>

> 由 DSH Studio（自动工作室）生成 ｜ 用 DeepSeek Harness 搭建你自己的自动工作室

## 这个项目里有什么

| 文件 | 作用 |
|---|---|
| `note-data.json` | 桌面便签数据（每日任务/四象限/链接） |
| `01-商业模式建立.md` | 你的商业模式（画布/现状/策略/插件推荐） |
| `02-运营面板.md` | 运营工位看板 |

## 下一步

1. 在 DSH 里说 **「模式建立」** → AI 对话式建立商业模式
2. 或先手动填《01-商业模式建立.md》
3. 启动便签看每日任务：

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File <dsh-studio路径>\src\desktop-note.ps1
```

## 常用指令（对 AI 说）

- 「模式建立」：建立/更新商业模式
- 「今天做什么」：生成今日任务
- 「更新看板」：刷新运营面板
- 「优化商业模式」：商业模式复盘调整
