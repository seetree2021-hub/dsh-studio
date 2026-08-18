# new-project.ps1 —— DSH Studio 项目初始化脚本
# 用法：.\new-project.ps1 my-studio
# 作用：在当前目录生成项目骨架（便签数据/商业模式/运营面板/说明），用户只跑这一条命令
param(
    [Parameter(Mandatory = $true)]
    [string]$Name
)

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$dir = Join-Path (Get-Location).Path $Name

if (Test-Path $dir) { Write-Host "目录已存在：$dir（将覆盖模板文件，确认后重跑）" -ForegroundColor Yellow }

# 1. 建目录
New-Item -ItemType Directory -Path $dir -Force | Out-Null

# 2. 复制模板
Copy-Item (Join-Path $here 'note-data.template.json') (Join-Path $dir 'note-data.json') -Force
Copy-Item (Join-Path $here '01-business-model.md')      (Join-Path $dir '01-business-model.md') -Force
Copy-Item (Join-Path $here '02-operations-panel.md')    (Join-Path $dir '02-operations-panel.md') -Force
Copy-Item (Join-Path $here 'README.md')                 (Join-Path $dir 'README.md') -Force

# 3. 替换项目名占位符 <PROJECT_NAME>
Get-ChildItem $dir -File | ForEach-Object {
    $c = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    $c = $c.Replace('<PROJECT_NAME>', $Name)
    [System.IO.File]::WriteAllText($_.FullName, $c, (New-Object System.Text.UTF8Encoding($true)))
}

Write-Host ""
Write-Host "✅ 项目已创建：$dir" -ForegroundColor Green
Write-Host "   下一步（二选一）："
Write-Host "   ① 在 DSH（AI 运营总监）里说：模式建立  → 对话式建立商业模式"
Write-Host "   ② 手动打开《01-business-model.md》填写"
Write-Host ""
Write-Host "   便签启动：powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File <dsh-studio>\src\desktop-note.ps1"
