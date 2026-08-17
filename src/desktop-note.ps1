# desktop-note.ps1 —— DSH Studio · 任务便签 v6（2×2 四象限网格 / 双面板入口 / 链接 / 双向交互）
# 运行：powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File desktop-note.ps1
# 数据：note-data.json（+ .bak 自动备份）｜ 位置：note.pos
# 说明：四象限（艾森豪威尔矩阵参照）网格布局；底部「运营面板」「商业模式」两个面板入口
# 日志：%TEMP%\desktop-note.log

$ErrorActionPreference = 'Stop'
$log = Join-Path $env:TEMP 'desktop-note.log'

try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class DW {
    [DllImport("user32.dll")] public static extern bool ReleaseCapture();
    [DllImport("user32.dll")] public static extern int SendMessage(IntPtr h, int m, int w, int l);
    [DllImport("user32.dll")] public static extern bool SetCapture(IntPtr h);
}
'@
    [System.Windows.Forms.Application]::EnableVisualStyles()

    # 数据文件（开源版可按需改路径）
    $jsonPath = 'F:\战略规划室\AI商业模式规划\今日便签数据.json'
    $posFile  = 'F:\战略规划室\AI商业模式规划\今日便签.pos'
    $opsPanel = 'F:\战略规划室\AI商业模式规划\工作室工作台.html'
    $bizPanel = 'F:\战略规划室\AI商业模式规划\01-方案-个人工作室版.html'

    $script:lastWrite = [datetime]::MinValue
    $script:tbx = $null
    $script:userH = 0
    $script:inboxDraft = ''
    $script:resizing = $false
    $script:tip = New-Object System.Windows.Forms.ToolTip

    $form = New-Object System.Windows.Forms.Form
    $form.Text = '任务便签'
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.BackColor = [System.Drawing.Color]::FromArgb(255, 253, 242)
    $form.TopMost = $false
    $form.ShowInTaskbar = $false
    $form.Width = 820

    $F = 'Microsoft YaHei'
    $INK   = [System.Drawing.Color]::FromArgb(59, 59, 59)
    $SOFT  = [System.Drawing.Color]::FromArgb(110, 110, 110)
    $MUT   = [System.Drawing.Color]::FromArgb(160, 156, 145)
    $FILL  = [System.Drawing.Color]::FromArgb(246, 243, 233)
    $HOVER = [System.Drawing.Color]::FromArgb(248, 245, 236)
    $RED   = [System.Drawing.Color]::FromArgb(196, 78, 62)
    $BLUE  = [System.Drawing.Color]::FromArgb(60, 110, 160)
    $GREEN = [System.Drawing.Color]::FromArgb(100, 140, 100)
    $TOPIC_COLORS = @{ '陶瓷' = [System.Drawing.Color]::FromArgb(176, 65, 62); '养猪' = [System.Drawing.Color]::FromArgb(47, 111, 163); '灭火器' = [System.Drawing.Color]::FromArgb(138, 109, 59); '自媒体' = [System.Drawing.Color]::FromArgb(90, 138, 74) }

    # ---------- 位置记忆 ----------
    function Load-Pos {
        if (Test-Path $posFile) {
            $parts = ((Get-Content $posFile -Raw).Trim() -split ',')
            if ($parts.Count -ge 5) {
                try {
                    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
                    $form.Location = New-Object System.Drawing.Point([int]$parts[0], [int]$parts[1])
                    $form.Width  = [Math]::Max(680, [Math]::Min(1280, [int]$parts[2]))
                    $form.Height = [Math]::Max(480, [Math]::Min(1000, [int]$parts[3]))
                    if ($parts[4] -eq '1') { $form.TopMost = $true }
                    $script:userH = $form.Height
                    return $true
                } catch { return $false }
            }
        }
        return $false
    }

    function Save-Pos {
        $txt = "$($form.Location.X),$($form.Location.Y),$($form.Width),$($form.Height),$(if ($form.TopMost) { 1 } else { 0 })"
        $txt | Set-Content $posFile -Encoding UTF8
    }

    # ---------- 数据 ----------
    function Read-Data {
        if (Test-Path $jsonPath) {
            $d = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($d.inbox -and $d.inbox -isnot [System.Array]) { $d.inbox = @($d.inbox) }
            if (-not $d.inbox) { $d.inbox = @() }
            if (-not $d.aiNote) { $d.aiNote = '在上方输入框添加临时任务，AI 会自动读取并登记。' }
            return $d
        }
        return $null
    }

    function Write-Data($data) {
        if (Test-Path $jsonPath) { Copy-Item $jsonPath ($jsonPath + '.bak') -Force }
        $data | ConvertTo-Json -Depth 6 | Set-Content $jsonPath -Encoding UTF8
        $script:lastWrite = (Get-Item $jsonPath).LastWriteTimeUtc
    }

    function Save-State {
        $data = Read-Data
        if (-not $data) { return }
        $form.Controls | Where-Object { $_ -is [System.Windows.Forms.CheckBox] } | ForEach-Object {
            $cb = $_
            if ($cb.Tag -match '^(\d+),(\d+)$') {
                $g = [int]$Matches[1]; $i = [int]$Matches[2]
                if ($data.groups[$g].items[$i]) { $data.groups[$g].items[$i].done = $cb.Checked }
            }
            elseif ($cb.Tag -match '^inbox,(\d+)$') {
                $i = [int]$Matches[1]
                if ($i -lt $data.inbox.Count) { $data.inbox[$i].done = $cb.Checked }
            }
        }
        Write-Data $data
    }

    function Add-InboxItem {
        $txt = $script:tbx.Text.Trim()
        $ph = '输入临时任务，回车添加'
        if ($txt -eq '' -or $txt -eq $ph) { return }
        $data = Read-Data
        if (-not $data) { return }
        $data.inbox += [pscustomobject]@{ text = $txt; done = $false; seen = $false; slot = '随时'; ts = (Get-Date -Format 'HH:mm') }
        Write-Data $data
        $script:inboxDraft = ''
        Build-UI
        Set-Rounded $form
        if ($script:tbx) { $script:tbx.Focus() }
    }

    function Del-InboxItem {
        param($idx)
        $data = Read-Data
        if (-not $data) { return }
        if ($idx -ge 0 -and $idx -lt $data.inbox.Count) {
            $al = New-Object System.Collections.ArrayList
            $data.inbox | ForEach-Object { [void]$al.Add($_) }
            $al.RemoveAt($idx)
            $data.inbox = @($al)
            Write-Data $data
            Build-UI
            Set-Rounded $form
        }
    }

    # ---------- 通用控件 ----------
    function Add-Drag($ctl) {
        $ctl.Add_MouseDown({
            if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
                [DW]::ReleaseCapture() | Out-Null
                [DW]::SendMessage($form.Handle, 0x00A1, 0x0002, 0) | Out-Null
            }
        })
    }

    # 任务项（x0=象限区左坐标，qw=区宽）
    function Add-CheckItem($x0, $y, $text, $checked, $tag, $qw, $showDel, $link, $slot, $topic) {
        $sl = New-Object System.Windows.Forms.Label
        $sl.Name = 'slot-' + ($tag -replace ',', '-')
        $sl.Text = $(if ($slot) { $slot } else { '随时' })
        $sl.Location = New-Object System.Drawing.Point(($x0 + 6), ($y + 5))
        $sl.Size = New-Object System.Drawing.Size(34, 18)
        $sl.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
        $sl.Font = New-Object System.Drawing.Font($F, 8)
        $sl.ForeColor = [System.Drawing.Color]::FromArgb(150, 145, 133)
        $form.Controls.Add($sl)

        if ($topic -and $TOPIC_COLORS[$topic]) {
            $dot = New-Object System.Windows.Forms.Panel
            $dot.BackColor = $TOPIC_COLORS[$topic]
            $dot.Location = New-Object System.Drawing.Point(($x0 + 46), ($y + 10))
            $dot.Size = New-Object System.Drawing.Size(10, 10)
            $dp = New-Object System.Drawing.Drawing2D.GraphicsPath
            $dp.AddEllipse(0, 0, 10, 10)
            $dot.Region = New-Object System.Drawing.Region($dp)
            $dp.Dispose()
            $form.Controls.Add($dot)
        }

        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Name = 'cb-' + ($tag -replace ',', '-')
        $cb.Text = $text
        $cb.Location = New-Object System.Drawing.Point(($x0 + 62), $y)
        $cb.Size = New-Object System.Drawing.Size(($qw - 108), 30)
        $cb.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $cb.Font = New-Object System.Drawing.Font($F, 10)
        $cb.ForeColor = $INK
        $cb.BackColor = $form.BackColor
        $cb.Checked = [bool]$checked
        $cb.Tag = $tag
        if ($checked) {
            $cb.Font = New-Object System.Drawing.Font($F, 10, [System.Drawing.FontStyle]::Strikeout)
            $cb.ForeColor = $MUT
        }
        $cb.Add_MouseEnter({ $this.BackColor = $HOVER })
        $cb.Add_MouseLeave({ $this.BackColor = $form.BackColor })
        $cb.Add_CheckedChanged({
            $c = $this
            if ($c.Checked) {
                $c.Font = New-Object System.Drawing.Font($F, 10, [System.Drawing.FontStyle]::Strikeout)
                $c.ForeColor = $MUT
            } else {
                $c.Font = New-Object System.Drawing.Font($F, 10, [System.Drawing.FontStyle]::Regular)
                $c.ForeColor = $INK
            }
            Save-State
            Refresh-Progress
        })
        $form.Controls.Add($cb)

        if ($showDel) {
            $del = New-Object System.Windows.Forms.Label
            $del.Name = 'del-' + ($tag -replace '^inbox,', '')
            $del.Text = '×'
            $del.Tag = 'del,' + ($tag -replace '^inbox,', '')
            $del.Location = New-Object System.Drawing.Point(($x0 + $qw - 30), ($y + 3))
            $del.Size = New-Object System.Drawing.Size(22, 22)
            $del.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
            $del.Font = New-Object System.Drawing.Font($F, 11)
            $del.ForeColor = [System.Drawing.Color]::FromArgb(200, 185, 170)
            $del.Cursor = [System.Windows.Forms.Cursors]::Hand
            $del.Add_MouseEnter({ $this.ForeColor = $RED })
            $del.Add_MouseLeave({ $this.ForeColor = [System.Drawing.Color]::FromArgb(200, 185, 170) })
            $del.Add_Click({
                if ($this.Tag -match '^del,(\d+)$') { Del-InboxItem ([int]$Matches[1]) }
            })
            $form.Controls.Add($del)
        }

        if ($link) {
            $lnk = New-Object System.Windows.Forms.Label
            $lnk.Name = 'lnk-' + ($tag -replace ',', '-')
            $lnk.Text = ''
            $lnk.Tag = $link
            $lnk.Location = New-Object System.Drawing.Point(($x0 + $qw - $(if ($showDel) { 64 } else { 36 })), ($y + 4))
            $lnk.Size = New-Object System.Drawing.Size(22, 22)
            $lnk.Cursor = [System.Windows.Forms.Cursors]::Hand
            $script:tip.SetToolTip($lnk, ('打开文档：' + $link))
            $lnk.Add_Paint({
                $g = $_.Graphics
                $hover = ($this.Tag2 -eq 1)
                $cMain = if ($hover) { [System.Drawing.Color]::FromArgb(60, 110, 160) } else { [System.Drawing.Color]::FromArgb(165, 160, 148) }
                $pen = New-Object System.Drawing.Pen($cMain, 1.3)
                $g.DrawRectangle($pen, 2, 2, 13, 17)
                $g.DrawLines($pen, @((New-Object System.Drawing.Point(15, 2)), (New-Object System.Drawing.Point(15, 9)), (New-Object System.Drawing.Point(8, 9))))
                $lpen = New-Object System.Drawing.Pen($cMain, 1)
                $g.DrawLine($lpen, 5, 13, 12, 13)
                $g.DrawLine($lpen, 5, 16, 12, 16)
                $pen.Dispose(); $lpen.Dispose()
            })
            $lnk.Add_MouseEnter({ $this.Tag2 = 1; $this.Invalidate() })
            $lnk.Add_MouseLeave({ $this.Tag2 = 0; $this.Invalidate() })
            $lnk.Add_Click({
                $p = $this.Tag
                if ($p) {
                    $ext = [System.IO.Path]::GetExtension($p).ToLower()
                    if ($ext -in '.md', '.txt', '.html', '.htm') { Start-Process ([System.Uri]::new($p)).AbsoluteUri }
                    else { Start-Process $p }
                }
            })
            $form.Controls.Add($lnk)
        }
    }

    # 面板入口按钮（底部：运营面板 / 商业模式）
    function Add-PanelButton($x, $y, $text, $target, $tint) {
        $btn = New-Object System.Windows.Forms.Label
        $btn.Text = $text
        $btn.Tag = $target
        $btn.Location = New-Object System.Drawing.Point($x, $y)
        $btn.Size = New-Object System.Drawing.Size(130, 34)
        $btn.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $btn.Font = New-Object System.Drawing.Font($F, 10, [System.Drawing.FontStyle]::Bold)
        $btn.ForeColor = [System.Drawing.Color]::White
        $btn.BackColor = $tint
        $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
        $btn.Add_MouseEnter({
            $c = $this.BackColor
            $this.BackColor = [System.Drawing.Color]::FromArgb([Math]::Max(0, ($c.R - 25)), [Math]::Max(0, ($c.G - 25)), [Math]::Max(0, ($c.B - 25)))
        })
        $btn.Add_MouseLeave({ $this.BackColor = $tint })
        $btn.Add_Click({ Start-Process $this.Tag })
        $bp = New-Object System.Drawing.Drawing2D.GraphicsPath
        $bp.AddArc(0, 0, 10, 10, 180, 90); $bp.AddArc(120, 0, 10, 10, 270, 90)
        $bp.AddArc(120, 24, 10, 10, 0, 90); $bp.AddArc(0, 24, 10, 10, 90, 90)
        $bp.CloseFigure()
        $btn.Region = New-Object System.Drawing.Region($bp)
        $bp.Dispose()
        $form.Controls.Add($btn)
    }

    function Build-UI {
        $form.SuspendLayout()
        $form.Controls.Clear()
        $W = $form.Width

        $data = Read-Data
        if (-not $data) {
            $lbl = New-Object System.Windows.Forms.Label
            $lbl.Text = '未找到便签数据'
            $lbl.Location = New-Object System.Drawing.Point(24, 60)
            $lbl.Font = New-Object System.Drawing.Font($F, 11)
            $form.Controls.Add($lbl)
            $form.Height = 140
            $form.ResumeLayout()
            return
        }

        # ---------- 标题 ----------
        $ttl = New-Object System.Windows.Forms.Label
        $ttl.Name = 'ttl'
        $ttl.Text = ($data.date + ' · ' + $data.title)
        $ttl.Location = New-Object System.Drawing.Point(20, 12)
        $ttl.AutoSize = $true
        $ttl.Font = New-Object System.Drawing.Font($F, 13, [System.Drawing.FontStyle]::Bold)
        $ttl.ForeColor = $INK
        $form.Controls.Add($ttl)
        Add-Drag $ttl

        # ---------- 右上：置顶 + 关闭 ----------
        $btnPin = New-Object System.Windows.Forms.Label
        $btnPin.Name = 'btnPin'
        $btnPin.Text = '置顶'
        $btnPin.Location = New-Object System.Drawing.Point(($W - 88), 13)
        $btnPin.Size = New-Object System.Drawing.Size(44, 24)
        $btnPin.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $btnPin.Font = New-Object System.Drawing.Font($F, 9)
        $btnPin.ForeColor = $MUT
        $btnPin.BackColor = $FILL
        $btnPin.Cursor = [System.Windows.Forms.Cursors]::Hand
        $btnPin.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(238, 234, 222) })
        $btnPin.Add_MouseLeave({ if (-not $form.TopMost) { $this.BackColor = $FILL } })
        $btnPin.Add_Click({
            $form.TopMost = -not $form.TopMost
            if ($form.TopMost) { $this.Text = '已置顶'; $this.ForeColor = $BLUE; $this.BackColor = [System.Drawing.Color]::FromArgb(232, 240, 248) }
            else { $this.Text = '置顶'; $this.ForeColor = $MUT; $this.BackColor = $FILL }
            Save-Pos
        })
        $form.Controls.Add($btnPin)

        $btnClose = New-Object System.Windows.Forms.Label
        $btnClose.Name = 'btnClose'
        $btnClose.Text = '×'
        $btnClose.Location = New-Object System.Drawing.Point(($W - 42), 9)
        $btnClose.Size = New-Object System.Drawing.Size(28, 28)
        $btnClose.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $btnClose.Font = New-Object System.Drawing.Font($F, 13)
        $btnClose.ForeColor = $MUT
        $btnClose.Cursor = [System.Windows.Forms.Cursors]::Hand
        $btnClose.Add_MouseEnter({ $this.ForeColor = $RED })
        $btnClose.Add_MouseLeave({ $this.ForeColor = $MUT })
        $btnClose.Add_Click({ $form.Close() })
        $form.Controls.Add($btnClose)

        # ---------- 输入区 ----------
        $ph = '输入临时任务，回车添加'
        $y = 52
        $tbx = New-Object System.Windows.Forms.TextBox
        $tbx.Name = 'tbxInbox'
        $tbx.Location = New-Object System.Drawing.Point(20, $y)
        $tbx.Size = New-Object System.Drawing.Size(($W - 104), 30)
        $tbx.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $tbx.Font = New-Object System.Drawing.Font($F, 10)
        $tbx.ForeColor = $MUT
        $tbx.BackColor = [System.Drawing.Color]::White
        if ($script:inboxDraft) { $tbx.Text = $script:inboxDraft; $tbx.ForeColor = $INK }
        else { $tbx.Text = $ph }
        $tbx.Add_GotFocus({ if ($this.Text -eq $ph) { $this.Text = ''; $this.ForeColor = $INK } })
        $tbx.Add_LostFocus({ if ([string]::IsNullOrWhiteSpace($this.Text)) { $this.Text = $ph; $this.ForeColor = $MUT } })
        $tbx.Add_TextChanged({ if ($this.Text -ne $ph) { $script:inboxDraft = $this.Text } })
        $tbx.Add_KeyDown({ if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) { $_.SuppressKeyPress = $true; Add-InboxItem } })
        $form.Controls.Add($tbx)
        $script:tbx = $tbx

        $btnAdd = New-Object System.Windows.Forms.Button
        $btnAdd.Name = 'btnAdd'
        $btnAdd.Text = '+'
        $btnAdd.Location = New-Object System.Drawing.Point(($W - 72), $y)
        $btnAdd.Size = New-Object System.Drawing.Size(30, 30)
        $btnAdd.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnAdd.FlatAppearance.BorderSize = 0
        $btnAdd.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(234, 229, 216)
        $btnAdd.BackColor = $FILL
        $btnAdd.ForeColor = $SOFT
        $btnAdd.Font = New-Object System.Drawing.Font($F, 15)
        $btnAdd.Cursor = [System.Windows.Forms.Cursors]::Hand
        $rp = New-Object System.Drawing.Drawing2D.GraphicsPath
        $rp.AddEllipse(0, 0, 30, 30)
        $btnAdd.Region = New-Object System.Drawing.Region($rp)
        $rp.Dispose()
        $btnAdd.Add_Click({ Add-InboxItem })
        $form.Controls.Add($btnAdd)

        # ---------- 图例 ----------
        $lgd = New-Object System.Windows.Forms.Label
        $lgd.Text = '四象限（艾森豪威尔矩阵参照）｜ 每项：时段 · 主题色点 · 文档图标'
        $lgd.Location = New-Object System.Drawing.Point(20, 92)
        $lgd.Size = New-Object System.Drawing.Size(($W - 40), 18)
        $lgd.Font = New-Object System.Drawing.Font($F, 8)
        $lgd.ForeColor = [System.Drawing.Color]::FromArgb(170, 165, 152)
        $form.Controls.Add($lgd)

        # ---------- 2×2 四象限网格 ----------
        $gridTop = 116
        $qW = [Math]::Floor(($W - 60) / 2)
        $qHeights = @()
        for ($g = 0; $g -lt $data.groups.Count; $g++) {
            $qHeights += (28 + $data.groups[$g].items.Count * 32 + 8)
        }
        while ($qHeights.Count -lt 4) { $qHeights += 160 }
        $inboxH = 0
        if ($data.inbox.Count -gt 0) { $inboxH = 26 + $data.inbox.Count * 32 + 6 }
        $qHeights[3] += $inboxH
        $hMax = [Math]::Max((($qHeights | Measure-Object -Maximum).Maximum), 160)

        $qPos = @(
            @(20, $gridTop),
            @((20 + $qW + 20), $gridTop),
            @(20, ($gridTop + $hMax + 16)),
            @((20 + $qW + 20), ($gridTop + $hMax + 16))
        )

        $total = 0; $done = 0
        for ($g = 0; $g -lt $data.groups.Count; $g++) {
            $grp = $data.groups[$g]
            $gCol = [System.Drawing.ColorTranslator]::FromHtml($grp.color)
            $px = $qPos[$g][0]; $py = $qPos[$g][1]

            $bar = New-Object System.Windows.Forms.Panel
            $bar.BackColor = $gCol
            $bar.Location = New-Object System.Drawing.Point(($px + 4), ($py + 5))
            $bar.Size = New-Object System.Drawing.Size(4, 15)
            $form.Controls.Add($bar)

            $glbl = New-Object System.Windows.Forms.Label
            $glbl.Text = $grp.name
            $glbl.Location = New-Object System.Drawing.Point(($px + 14), $py)
            $glbl.AutoSize = $true
            $glbl.Font = New-Object System.Drawing.Font($F, 10, [System.Drawing.FontStyle]::Bold)
            $glbl.ForeColor = $SOFT
            $form.Controls.Add($glbl)

            $iy = $py + 26

            if ($g -eq 3 -and $data.inbox.Count -gt 0) {
                $ilbl = New-Object System.Windows.Forms.Label
                $ilbl.Text = ('临时任务 ' + $data.inbox.Count)
                $ilbl.Location = New-Object System.Drawing.Point(($px + 14), $iy)
                $ilbl.AutoSize = $true
                $ilbl.Font = New-Object System.Drawing.Font($F, 9, [System.Drawing.FontStyle]::Bold)
                $ilbl.ForeColor = $GREEN
                $form.Controls.Add($ilbl)
                $iy += 24
                for ($i = 0; $i -lt $data.inbox.Count; $i++) {
                    $item = $data.inbox[$i]
                    $total++
                    if ($item.done) { $done++ }
                    Add-CheckItem $px $iy $item.text $item.done "inbox,$i" $qW $true $null $item.slot $null
                    $iy += 32
                }
                $iy += 4
            }

            for ($i = 0; $i -lt $grp.items.Count; $i++) {
                $item = $grp.items[$i]
                $total++
                if ($item.done) { $done++ }
                Add-CheckItem $px $iy $item.text $item.done "$g,$i" $qW $false $item.link $item.slot $item.topic
                $iy += 32
            }
        }

        # ---------- 底部：进度 + 面板入口 + AI 留言 ----------
        $botY = $gridTop + 2 * $hMax + 16 + 12
        $prog = New-Object System.Windows.Forms.Panel
        $prog.Name = 'prog'
        $prog.Location = New-Object System.Drawing.Point(20, $botY)
        $prog.Size = New-Object System.Drawing.Size(($W - 76), 6)
        $prog.BackColor = [System.Drawing.Color]::FromArgb(238, 234, 222)
        $prog.Add_Paint({
            $g = $_.Graphics
            $fw = [Math]::Round($this.Width * $script:done / [Math]::Max(1, $script:total))
            if ($fw -gt 0) {
                $b = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(120, 160, 120))
                $g.FillRectangle($b, 0, 0, $fw, 6)
                $b.Dispose()
            }
        })
        $form.Controls.Add($prog)

        $pcnt = New-Object System.Windows.Forms.Label
        $pcnt.Name = 'lblPct'
        $pcnt.Text = "$done / $total"
        $pcnt.Location = New-Object System.Drawing.Point(($W - 52), ($botY - 6))
        $pcnt.Size = New-Object System.Drawing.Size(36, 18)
        $pcnt.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
        $pcnt.Font = New-Object System.Drawing.Font($F, 9)
        $pcnt.ForeColor = $MUT
        $form.Controls.Add($pcnt)

        $btnY = $botY + 14
        Add-PanelButton 20 $btnY '运营面板' $opsPanel ([System.Drawing.Color]::FromArgb(107, 142, 178))
        Add-PanelButton 162 $btnY '商业模式' $bizPanel ([System.Drawing.Color]::FromArgb(107, 150, 110))

        $note = New-Object System.Windows.Forms.Label
        $note.Name = 'lblNote'
        $note.Text = ('AI · ' + $data.aiNote)
        $note.Location = New-Object System.Drawing.Point(20, ($btnY + 40))
        $note.Size = New-Object System.Drawing.Size(($W - 56), 24)
        $note.Font = New-Object System.Drawing.Font($F, 9)
        $note.ForeColor = $MUT
        $note.BackColor = $form.BackColor
        $note.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
        $form.Controls.Add($note)

        # ---------- 右下角缩放手柄 ----------
        $hnd = New-Object System.Windows.Forms.Panel
        $hnd.Name = 'hnd'
        $hnd.Location = New-Object System.Drawing.Point(($W - 22), ($note.Location.Y + 6))
        $hnd.Size = New-Object System.Drawing.Size(18, 18)
        $hnd.BackColor = $form.BackColor
        $hnd.Cursor = [System.Windows.Forms.Cursors]::SizeNWSE
        $hnd.Add_Paint({
            $g = $_.Graphics
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(205, 198, 182), 1.4)
            for ($k = 0; $k -lt 3; $k++) {
                $g.DrawLine($pen, (3 + $k * 5), (15 - $k * 5), (15 - $k * 5), (3 + $k * 5))
            }
            $pen.Dispose()
        })
        $hnd.Add_MouseDown({
            $script:resizing = $true
            $script:resStart = $_.Location
            $script:resW = $form.Width; $script:resH = $form.Height
            [DW]::SetCapture($this.Handle) | Out-Null
            $timer.Enabled = $false
        })
        $hnd.Add_MouseMove({
            if ($script:resizing) {
                $dx = $_.Location.X - $script:resStart.X
                $dy = $_.Location.Y - $script:resStart.Y
                $form.Width = [Math]::Max(680, [Math]::Min(1280, $script:resW + $dx))
                $form.Height = [Math]::Max(480, [Math]::Min(1000, $script:resH + $dy))
            }
        })
        $hnd.Add_MouseUp({
            if ($script:resizing) {
                $script:resizing = $false
                $script:userH = $form.Height
                $timer.Enabled = $true
                Build-UI
                Set-Rounded $form
                Save-Pos
            }
        })
        $form.Controls.Add($hnd)

        $script:total = $total
        $script:done = $done
        $form.Height = [Math]::Max(($note.Location.Y + 40), $script:userH)
        $form.ResumeLayout()
    }

    function Refresh-Progress {
        $prog = $form.Controls | Where-Object { $_.Name -eq 'prog' } | Select-Object -First 1
        $pct  = $form.Controls | Where-Object { $_.Name -eq 'lblPct' } | Select-Object -First 1
        if ($prog) {
            $script:done = ($form.Controls | Where-Object { $_ -is [System.Windows.Forms.CheckBox] } | Where-Object { $_.Checked }).Count
            $prog.Invalidate()
            if ($pct) { $pct.Text = "$script:done / $script:total" }
        }
    }

    function Set-Rounded {
        param($f, [int]$r = 14)
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $w = $f.Width; $h = $f.Height
        $path.AddArc(0, 0, $r, $r, 180, 90)
        $path.AddArc($w - $r, 0, $r, $r, 270, 90)
        $path.AddArc($w - $r, $h - $r, $r, $r, 0, 90)
        $path.AddArc(0, $h - $r, $r, $r, 90, 90)
        $path.CloseFigure()
        $f.Region = New-Object System.Drawing.Region($path)
        $path.Dispose()
    }

    $form.Add_MouseDown({
        if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            [DW]::ReleaseCapture() | Out-Null
            [DW]::SendMessage($form.Handle, 0x00A1, 0x0002, 0) | Out-Null
        }
    })
    $form.Add_Paint({
        $g = $_.Graphics
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $r = 14; $w = $form.Width; $h = $form.Height
        $path.AddArc(0, 0, $r, $r, 180, 90)
        $path.AddArc($w - $r, 0, $r, $r, 270, 90)
        $path.AddArc($w - $r, $h - $r, $r, $r, 0, 90)
        $path.AddArc(0, $h - $r, $r, $r, 90, 90)
        $path.CloseFigure()
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(224, 218, 202), 1)
        $g.DrawPath($pen, $path)
        $pen.Dispose(); $path.Dispose()
    })

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 3000
    $timer.Add_Tick({
        if (Test-Path $jsonPath) {
            $w = (Get-Item $jsonPath).LastWriteTimeUtc
            if ($w -ne $script:lastWrite) {
                $script:lastWrite = $w
                Build-UI
                Set-Rounded $form
            }
        }
    })

    Load-Pos
    Build-UI
    Set-Rounded $form
    $script:lastWrite = (Get-Item $jsonPath).LastWriteTimeUtc
    $timer.Start()

    "started v6 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File $log -Append -Encoding UTF8
    [System.Windows.Forms.Application]::Run($form)
}
catch {
    "ERROR $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $($_.Exception.Message)`n$($_ | Out-String)" | Out-File $log -Append -Encoding UTF8
}
