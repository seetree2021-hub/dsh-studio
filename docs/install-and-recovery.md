# DSH Studio 插件 · 安全安装与恢复指南

> 目标：**先测后装**——在把插件装进正式 web profile 之前，用零风险的方式确认它能正常加载，
> 装坏后能一键恢复。适用于 DSH Studio（dsh-studio）及任何 DSH client 插件。

---

## 一、安装前安全测试（两步，不碰正式 profile）

### 第 1 步 · 打包校验

确认发布包内容齐全（dist 构建产物 + cordis.patch.yml + package.json）：

```bash
cd packages/dsh-studio-plugin
npm pack --dry-run
```

应看到 tarball 内含：`dist/index.js`、`dist/client.js`、`cordis.patch.yml`、`package.json`。

### 第 2 步 · 一次性隔离 profile 加载冒烟

用一次性 profile 验证「插件的 cordis.patch.yml 能被 DSH 正确解析并挂载」，不改动正式 web profile。

```powershell
# 1) 建一次性 profile（package.json 必须无 BOM，见第四节坑位）
$p = "$env:DSH_HOME\profiles\dsh-studio-test"
New-Item -ItemType Directory -Path $p -Force | Out-Null
'{"name":"dsh-profile-dsh-studio-test","private":true,"dependencies":{},"dsh":{"profile":{"bundles":["@deepseek-ai/dsh-base","@deepseek-ai/dsh-web-app"]}}}' |
  Set-Content "$p\package.json" -Encoding utf8NoBOM

# 2) 打包到「无空格」路径（路径含空格会拆断参数，见第四节）
cd packages/dsh-studio-plugin
npm pack
Copy-Item .\dsh-studio-0.4.0.tgz C:\Temp\dsh-studio-0.4.0.tgz

# 3) 装进一次性 profile 并做加载冒烟
dsh plugin --profile dsh-studio-test add C:\Temp\dsh-studio-0.4.0.tgz
dsh --profile dsh-studio-test --dump-config

# 通过标准：exit 0，且输出里出现 "id: dsh-studio"（及其 panels 配置）
# 测完删除：Remove-Item $p -Recurse -Force
```

`--dump-config` 只做「配置合成 + 解析 + 打印」后退出，**不会启动 Web 服务**，因此零风险。

---

## 二、正式安装（先备份）

```powershell
$web = "$env:DSH_HOME\profiles\web"

# 1) 备份（就两个小文件）
Copy-Item "$web\package.json"      "$web\package.json.bak"      -Force
Copy-Item "$web\cordis.patch.yml"  "$web\cordis.patch.yml.bak"  -Force

# 2) 安装（无空格 tarball 路径；或 npm 发布后直接装包名）
dsh plugin --profile web add C:\Temp\dsh-studio-0.4.0.tgz
#   或发布后： dsh plugin --profile web add dsh-studio

# 3) 重启 DSH web 后验证：设置页出现「DSH Studio」菜单 + GET /api2/dsh-studio/data 可读
```

---

## 三、恢复方法（装坏时，按顺序试）

### 方式 1 · 卸载插件（最常用）

```powershell
dsh plugin --profile web remove dsh-studio
```

### 方式 2 · 手动移除（卸载命令失效时）

1. 编辑 `$env:DSH_HOME\profiles\web\package.json`，删掉 `dependencies` 里的 `"dsh-studio"`。
2. 删除目录 `$env:DSH_HOME\profiles\web\node_modules\dsh-studio`。
3. 确认 `$env:DSH_HOME\profiles\web\cordis.patch.yml` 内容为 `[]`（插件不改它，它只是空覆盖层）。

### 方式 3 · 整体回滚（彻底还原）

```powershell
$web = "$env:DSH_HOME\profiles\web"
Copy-Item "$web\package.json.bak"     "$web\package.json"     -Force
Copy-Item "$web\cordis.patch.yml.bak" "$web\cordis.patch.yml" -Force
cd $web
pnpm install     # 按还原后的 package.json 重装依赖
# 重启 DSH web
```

---

## 四、重要坑位（踩过的记录）

- **本地路径含空格会拆断 `dsh plugin add <本地路径>`**：`dsh plugin` 把参数原样转发给 pnpm，
  `F:\...\DSH Studio\...` 会被空格拆成多个「包名」装错。解决：先 `npm pack` 出 tarball 拷到**无空格路径**
  再 add，或发布到 npm 后直接 `dsh plugin add dsh-studio`。
- **profile 的 package.json 不能带 BOM**：DSH 用 `JSON.parse` 读它，UTF-8 BOM 会报
  `Unexpected token '﻿'`。保存时用「无 BOM 的 UTF-8」。
- **桌面便签脚本 (.ps1) 必须带 BOM**：`desktop-note.ps1` / `new-project.ps1` 含中文，
  PowerShell 5.1 对无 BOM 的 .ps1 按系统 ANSI 读会乱码。这条与上一条**正好相反**，别搞混。
- **桌面便签是独立 PowerShell 脚本**：它崩了不影响 DSH Web，关掉重跑即可；数据始终在
  `note-data.json`，每次写前自动备份 `.bak`，可随时回退。
