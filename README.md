# DSH Studio · 自动工作室

> 基于 **DeepSeek Harness** 开发的开源插件：为**个人和小型团队**搭建"自动工作室"。
> Harness（AI）作为你的**运营总监**：负责工作室运营、商业模式设计与优化、每日任务发布。

**DSH Studio** 是一套"AI 运营总监"开源插件系统：

| 模块 | 作用 |
|---|---|
| 📌 **任务便签** | 每日任务发布与执行（四象限：紧急重要 → 可缓；时段；任务带文档链接，点开即执行） |
| 📊 **运营面板 / 💼 商业模式面板** | 按你的业务**自由配置**——面板数量、名称、内容均可自定义 |

**适合谁**：个人手作工作室、设计工作室、小型团队——**不局限于自媒体**。你可以根据自己
的工作性质（产品制造 / 设计服务 / 内容创作 / 电商 / 咨询……）建立自己的工作流：

- 需要的工作应用插件：**可以自己安装**，也可以让 AI 根据你的业务**按需推送**（业务线 → 推荐模块映射）
- 面板、主题色、任务分组全部可配置（`dsh-studio.config.json`，见 `src/dsh-studio.config.example.json`）

- 许可：**MIT**（随意使用、修改、商用、二次发布）
- 目标平台：Windows（桌面便签原生应用）+ DeepSeek Harness（DSH 架构平台）
- 技术：PowerShell + WinForms（零安装、免登录、纯本地）、JSON 数据协议、可配置化

---

## 🚀 新用户旅程（30 秒上手）

```
下载 → 新建项目 → 说「模式建立」→ AI 对话建商业模式 → 便签+面板运营
```

1. **下载**：`git clone https://github.com/seetree2021-hub/dsh-studio`
2. **新建项目**：`.\docs\project-template\new-project.ps1 my-studio`
3. **模式建立**：在 DSH（AI 运营总监）里说 **「模式建立」**——AI 分 4 组提问（现状/收入/成本/目标），答完自动生成商业模式画布 + 插件推荐 + 便签任务
4. **运营**：桌面便签看每日任务（四象限），点📄开文档照做，打勾即存；AI 每天更新

> 详细流程见 `docs/onboarding.md`｜问卷 `docs/questionnaire.md`｜插件映射 `docs/plugin-map.md`｜AI 执行手册 `docs/ai-sop.md`

---

## 快速开始（3 步）

1. 把 `src\desktop-note.ps1` 复制到你的工作目录（或保持原路径）
2. 编辑 `note-data.json`（数据协议见 `docs\data-protocol.md`）——任务、分组、四象限、链接都由 AI 运营总监（DSH 会话）每天更新
3. 启动便签（Windows）：

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File src\desktop-note.ps1
```

- 勾选任务即保存；任务右侧 📄 图标=对应文档，点击直接打开
- 拖动标题/空白处移动，右下角手柄缩放，右上角置顶/关闭
- 位置/尺寸/置顶状态自动记忆，开机自启（快捷方式放入启动文件夹即可）

## 便签界面

- **四象限布局**（参照艾森豪威尔矩阵）：■ 紧急重要·马上做 ｜ ■ 重要不紧急·规划做 ｜ ■ 紧急不重要·少做 ｜ ■ 不紧急不重要·可缓
- 每项任务：时段徽标（上午/下午/随时）+ 主题圆点 + 勾选框 + 文档图标链接
- 顶部输入框：随时添加临时任务（回车添加），AI 运营总监自动读取登记
- 底部 💬 AI 留言区：AI 处理结果实时回显（3 秒自动刷新）

## 与 DSH 运营总监的协作闭环

```
用户每天输入新增任务
      ↓
AI 更新 note-data.json（任务/链接/留言）
      ↓
便签 3 秒自动刷新
      ↓
用户执行 + 打勾
      ↓
AI 读取勾选状态 → 登记进度 → 更新工作计划/商业模式
```

## 项目结构

```
dsh-studio/
├── README.md
├── LICENSE                 # MIT
├── src/
│   ├── desktop-note.ps1    # 桌面任务便签（WinForms，2×2 四象限网格）
│   └── note-data.example.json
└── docs/
    └── data-protocol.md    # JSON 数据协议
```

## Roadmap

- [x] 任务便签（桌面原生，四象限 + 链接 + 勾选 + 双向交互）
- [x] 运营面板 / 商业模式面板（工作台文档体系，便签一键直达）
- [ ] DSH client-ui 插件：三面板嵌入 DeepSeek Harness Web 界面
- [ ] 跨平台（macOS/Linux 便签壳）
- [ ] 模板市场（餐饮/电商/工作室等预设运营模板）

## 贡献

欢迎 PR / Issue。设计原则：**数据本地、协议开放、AI 任选**——数据永远在你自己的磁盘上，AI 只是读写这份 JSON。
