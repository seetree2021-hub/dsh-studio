# Auto Studio · 数据协议（note-data.json）

> 版本：1.0（2026-08-17）｜ 设计原则：数据本地、协议开放、AI 任选
> AI 运营总监（DSH 会话）每天更新此文件；便签 3 秒自动重载。

## 顶层结构

```json
{
  "title": "今日便签",
  "date": "2026-08-17 周一",
  "aiNote": "AI 留言区：处理结果回显（如'已收到临时任务，已登记'）",
  "groups": [ { "name": "...", "color": "#C0392B", "items": [...] } ],
  "inbox": [ { "text": "...", "done": false, "seen": false, "pri": "P3", "slot": "随时" } ]
}
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `title` | string | 便签标题 |
| `date` | string | 日期（含星期，如 `2026-08-17 周一`） |
| `aiNote` | string | AI 留言（底部显示，AI 写、用户读） |
| `groups` | array | 分组列表（四象限顺序：紧急重要 → 可缓） |
| `inbox` | array | 用户临时任务（便签输入框添加，AI 会话读取登记） |

## 分组（groups[]）

| 字段 | 类型 | 说明 |
|---|---|---|
| `name` | string | 组名（便签显示为区标题；四象限模式为象限名） |
| `color` | string | 组色（十六进制，如 `#C0392B`） |
| `items` | array | 任务列表 |

## 任务（groups[].items[]）

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `text` | string | ✅ | 任务文字 |
| `done` | bool | ✅ | 是否完成（用户打勾，便签写回） |
| `slot` | string | 可选 | 时段：`上午` / `下午` / `随时` |
| `topic` | string | 可选 | 主题名（对应主题色：内容/产品/项目/客户…可在配置中扩展） |
| `link` | string | 可选 | 文档路径/URL；便签显示 📄 图标，点击打开 |
| `pri` | string | 可选 | 优先级 P0-P3（四象限模式下由分组决定，可省略） |

## 临时任务（inbox[]）

| 字段 | 类型 | 说明 |
|---|---|---|
| `text` | string | 用户输入的任务文字 |
| `done` | bool | 完成状态 |
| `seen` | bool | AI 是否已读取登记 |
| `ts` | string | 添加时间（HH:mm） |

## 主题色（默认映射，可配置扩展）

> 默认四色适用于通用业务线；通过 `dsh-studio.config.json` 的 `topics` 可覆盖/新增任意主题色。

| topic | 颜色 |
|---|---|
| 内容 | #B0413E |
| 产品 | #2F6FA3 |
| 项目 | #8A6D3B |
| 客户 | #5A8A4A |

## 操作约定（AI 与便签）

- **AI 写**：更新 title/date/groups/aiNote；读 inbox（未 seen）→ 登记 → 置 seen=true → 留言
- **便签写**：用户打勾 → 写回 `done`；用户添加临时任务 → 追加 inbox；位置/尺寸/置顶 → `note.pos`（同目录，`x,y,w,h,topmost`）
- 便签每次写文件前自动备份 `note-data.json.bak`
