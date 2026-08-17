# dsh-studio-plugin（v0.4.0 开发中）

把 DSH Studio（任务便签 / 运营面板 / 商业模式面板）嵌入 **DeepSeek Harness Web UI** 的
DSH client 插件。数据与桌面便签共享同一份 `note-data.json`——**网页与桌面两端同步**。

## 架构

```
浏览器端（client，React）
  └─ ctx.slots.inject('settings.section') → 设置一级菜单「DSH Studio」
       └─ NotePanel：四象限任务（勾选即时写回）+ 面板入口
              │  fetch /api2/dsh-studio/*（同源）
host 端（cordis 插件）
  └─ webServer.register：
       GET  /api2/dsh-studio/data   读 note-data.json
       POST /api2/dsh-studio/data   写（勾选/临时任务，自动 .bak 备份）
       GET  /api2/dsh-studio/panels 面板配置
       GET  /api2/dsh-studio/health 健康检查
数据：note-data.json（与桌面便签同一文件，协议见 docs/data-protocol.md）
```

## 开发

```sh
cd packages/dsh-studio-plugin
pnpm install
pnpm run build        # host: tsc；client: tsc
```

## 安装（到 web profile）

```sh
# 方式一：npm 发布后
dsh plugin --profile web add dsh-studio

# 方式二：本地路径
dsh plugin --profile web add ./packages/dsh-studio-plugin
```

重启 DSH web 后，设置页出现「DSH Studio」菜单。

## 配置（cordis.patch.yml / 设置页）

| 键 | 说明 |
|---|---|
| dataPath | note-data.json 路径（空=当前目录） |
| panels | 面板列表（text/target/color，任意多个） |

## 注意

- host 必须用 **tsc** 构建（tsdown/rolldown 会保留原生装饰器语法，Node 不支持）
- client 注册模式参照 [dsh-web-plugin-manager](https://github.com/LX2000WASD/dsh-web-plugin-manager)
- `webServer.register` handler 签名以实际 DSH webServer 为准（骨架按 exact+handler 编写）
- 开发需完整 DSH 环境（pnpm + @deepseek-ai client 包 + profile 重启验证）
