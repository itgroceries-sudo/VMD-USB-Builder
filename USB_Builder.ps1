<# : VMD USB Builder (Stable Revert)
@powershell -noprofile -Window Hidden -c "$param='%*';$ScriptPath='%~f0';iex((Get-Content('%~f0') -Raw))"&exit/b
#>

$ErrorActionPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$AppVer   = "2.0"
$AppBuild = "16.8" 
$DateStr  = Get-Date -Format "dd-MM-yyyy"
$Title    = "IT GROCERIES GUI [$DateStr]"

$CurrentScript = $PSCommandPath
if (-not $CurrentScript) {
    $WebSource = "https://raw.githubusercontent.com/itgroceries-sudo/VMD-USB-Builder/main/USB_Builder.ps1"
    $TempScript = "$env:TEMP\USB_Builder.ps1"
    try { Invoke-WebRequest $WebSource -Out $TempScript -UseBasicParsing -ErrorAction Stop } catch { exit }
    Start-Process PowerShell -Arg "-NoProfile -Exec Bypass -File `"$TempScript`"" -Verb RunAs; exit
}

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -Arg "-NoProfile -Exec Bypass -File `"$CurrentScript`"" -Verb RunAs; exit
}

$Win32 = Add-Type -MemberDefinition @"
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern IntPtr GetSystemMenu(IntPtr hWnd, bool bRevert);
    [DllImport("user32.dll")] public static extern bool DeleteMenu(IntPtr hMenu, uint uPosition, uint uFlags);
"@ -Name "Win32Utils" -Namespace Win32 -PassThru

$WorkDir    = "$env:TEMP\ITG_VMD_Build"
$SupportDir = "$WorkDir\Support"
$Running    = $true

$GH_Raw  = "https://raw.githubusercontent.com/itgroceries-sudo/VMD-USB-Builder/main"
$URL_V18 = "https://downloadmirror.intel.com/773229/SetupRST.exe"
$URL_V19 = "https://downloadmirror.intel.com/849934/SetupRST.exe"
$URL_V20 = "https://downloadmirror.intel.com/865363/SetupRST.exe"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ConsoleHandle = $Win32::GetConsoleWindow()
$Host.UI.RawUI.WindowTitle = "IT GROCERIES CONSOLE"

$ScreenWidth  = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width
$ScreenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height
$WinW = 650; $WinH = 700
$X = ($ScreenWidth - $WinW) / 2
$Y = ($ScreenHeight - $WinH) / 2

[void]$Win32::SetWindowPos($ConsoleHandle, [IntPtr]::Zero, $X, $Y, $WinW, $WinH, 0x0040)
$hMenu = $Win32::GetSystemMenu($ConsoleHandle, $false)
if ($hMenu) { 
    [void]$Win32::DeleteMenu($hMenu, 0xF010, 0); [void]$Win32::DeleteMenu($hMenu, 0xF060, 0)
    [void]$Win32::DeleteMenu($hMenu, 0xF030, 0); [void]$Win32::DeleteMenu($hMenu, 0xF000, 0)
}

Clear-Host
$Host.UI.RawUI.BackgroundColor = "Black"; $Host.UI.RawUI.ForegroundColor = "Green"; Clear-Host
Write-Host "`n`n      ==================================================" -Fore Cyan
Write-Host "             IT GROCERIES CONSOLE             " -Fore White
Write-Host "      ==================================================" -Fore Cyan
Write-Host "`n      [ SYSTEM STATUS ]" -Fore Yellow
Write-Host "      > Initializing..."

$form = New-Object Windows.Forms.Form
$form.Text = $Title
$form.Size = New-Object Drawing.Size($WinW, $WinH)
$form.BackColor = "Black"
$form.FormBorderStyle = "None"
$form.StartPosition = "Manual"
$form.Location = New-Object Drawing.Point($X, $Y)
$form.KeyPreview = $true

# [THE ORIGINAL STABLE BORDER]
$form.Add_Paint({
    param($s, $e)
    $pen = New-Object Drawing.Pen([Drawing.Color]::Cyan, 2)
    $pen.Alignment = [Drawing.Drawing2D.PenAlignment]::Inset
    $e.Graphics.DrawRectangle($pen, $form.ClientRectangle)
    $pen.Dispose()
})

$global:TargetUSB = $null

$lblHead = New-Object Windows.Forms.Label
$lblHead.Text = "--- VMD USB BUILDER v$AppVer Build$AppBuild ---"
$lblHead.ForeColor = "Cyan"
$lblHead.Font = New-Object Drawing.Font("Consolas", 12, [Drawing.FontStyle]::Bold)
$lblHead.TextAlign = "MiddleCenter"
$lblHead.Dock = "Top"
$lblHead.Height = 40
$lblHead.Add_MouseDown({ $form.Capture = $false }) 
$form.Controls.Add($lblHead)

$cmbUSB = New-Object Windows.Forms.ComboBox
$cmbUSB.Width = 450; $cmbUSB.Height = 40; $cmbUSB.Location = New-Object Drawing.Point(90, 50)
$cmbUSB.Font = New-Object Drawing.Font("Consolas", 12, [Drawing.FontStyle]::Bold)
$cmbUSB.BackColor = "DimGray"; $cmbUSB.ForeColor = "White"
$cmbUSB.DropDownStyle = "DropDownList"
$form.Controls.Add($cmbUSB)

$cbShow = New-Object Windows.Forms.CheckBox
$cbShow.Text = "Show All Drives"; $cbShow.Font = New-Object Drawing.Font("Consolas", 9)
$cbShow.ForeColor = "Gray"; $cbShow.Location = New-Object Drawing.Point(90, 92)
$cbShow.Size = New-Object Drawing.Size(200, 20)
$form.Controls.Add($cbShow)

$btnCopy = New-Object Windows.Forms.Button
$btnCopy.Text = "Copy to Drive >"; $btnCopy.Font = New-Object Drawing.Font("Consolas", 9, 1)
$btnCopy.ForeColor = "White"; $btnCopy.BackColor = "RoyalBlue"; $btnCopy.FlatStyle = "Flat"
$btnCopy.Location = New-Object Drawing.Point(390, 90); $btnCopy.Size = New-Object Drawing.Size(150, 24)
$form.Controls.Add($btnCopy)

$lblStatus = New-Object Windows.Forms.Label
$lblStatus.Text = "Scanning..."; $lblStatus.ForeColor = "Yellow"
$lblStatus.Font = New-Object Drawing.Font("Consolas", 10); $lblStatus.TextAlign = "MiddleCenter"
$lblStatus.Location = New-Object Drawing.Point(4, 118); $lblStatus.Size = New-Object Drawing.Size(($WinW - 8), 20) 
$form.Controls.Add($lblStatus)

function Log { param($M, $C="White"); Write-Host "      > $M" -Fore $C }

function Refresh-USB {
    $Sys = $env:SystemDrive.Substring(0,1)
    $drives = Get-Volume -ErrorAction 0 | Where {
        if ($cbShow.Checked) { ($_.DriveType -eq 'Removable' -or $_.DriveType -eq 'Fixed') -and $_.DriveLetter -ne $null -and $_.DriveLetter -ne $Sys }
        else { $_.DriveType -eq 'Removable' -and $_.DriveLetter -ne $null }
    } | Sort DriveLetter

    if ($cmbUSB.Items.Count -ne $drives.Count -or $cmbUSB.Items.Count -eq 0) {
        $cmbUSB.Items.Clear()
        if ($drives) {
            foreach ($d in $drives) {
                $GB = [math]::Round($d.SizeRemaining/1GB, 2)
                $L = if ($d.FileSystemLabel) { $d.FileSystemLabel } else { "USB" }
                [void]$cmbUSB.Items.Add("[$($d.DriveLetter):] $L ($GB GB Free)")
            }
            if ($cmbUSB.SelectedIndex -eq -1) { $cmbUSB.SelectedIndex = 0 }
        } else { $cmbUSB.Items.Clear(); $cmbUSB.Text = "No USB" }
    }
    if ($cmbUSB.SelectedIndex -ne -1) {
        $global:TargetUSB = $cmbUSB.SelectedItem.ToString().Substring(1, 2) + "\"
        $lblStatus.Text = "Target: $global:TargetUSB"; $lblStatus.ForeColor = "Lime"
    } else {
        $global:TargetUSB = $null; $lblStatus.Text = "Select Drive..."; $lblStatus.ForeColor = "Red"
    }
}

function Manual-Copy {
    if (!$global:TargetUSB) { [Windows.Forms.MessageBox]::Show("Select Target First!", "Error"); return }
    if (!(Test-Path "$SupportDir\VMD_Installer.cmd")) { [Windows.Forms.MessageBox]::Show("Build Files First!", "Error"); return }
    
    if ([Windows.Forms.MessageBox]::Show("Copy to $global:TargetUSB ?", "Confirm", "YesNo") -eq "Yes") {
        Log "Copying to $global:TargetUSB..." "Cyan"
        Copy-Item "$WorkDir\Autounattend.xml" $global:TargetUSB -Force
        Copy-Item $SupportDir $global:TargetUSB -Recurse -Force
        Log "DONE" "Green"
        [Windows.Forms.MessageBox]::Show("Success!", "Done")
    }
}

function Get-Intel {
    param ($Url, $Name)
    $Exe = "$WorkDir\$Name.exe"; $Ext = "$WorkDir\Tmp_$Name"
    Log "Downloading $Name..." "Cyan"
    try { Invoke-WebRequest $Url -Out $Exe -UseBasicParsing -ErrorAction Stop } catch { Log "DL Error" "Red"; return }
    
    if (Test-Path $Exe) {
        Log "Extracting..." "Gray"
        Start-Process $Exe -Arg "-extractdrivers `"$Ext`"" -Wait -WindowStyle Hidden
        $Inf = Get-ChildItem $Ext -Recurse -Filter "iaStorVD.inf" | Select -First 1
        if ($Inf) {
            $Dest = "$SupportDir\$Name"; New-Item -ItemType Directory $Dest -Force | Out-Null
            Copy-Item "$($Inf.Directory.FullName)\*" $Dest -Recurse -Force
            Log "OK: $Name" "Green"
        }
        Remove-Item $Exe -Force -ErrorAction 0; Remove-Item $Ext -Recurse -Force -ErrorAction 0
    }
}

function Build-Process {
    param($M)
    Log "--- BUILD STARTED ---" "Yellow"
    if (Test-Path $WorkDir) { Remove-Item $WorkDir -Recurse -Force -ErrorAction 0 }
    New-Item $SupportDir -ItemType Directory -Force | Out-Null
    Log "Syncing GitHub..."
    try {
        Invoke-WebRequest "$GH_Raw/Autounattend.xml" -Out "$WorkDir\Autounattend.xml" -UseBasicParsing -ErrorAction Stop
        Invoke-WebRequest "$GH_Raw/VMD_Installer.cmd" -Out "$SupportDir\VMD_Installer.cmd" -UseBasicParsing -ErrorAction Stop
    } catch { [Windows.Forms.MessageBox]::Show("Net Error", "Error"); return }

    if ($M -eq 1 -or $M -eq 2) { Get-Intel $URL_V18 "VMD_v18" }
    if ($M -eq 1 -or $M -eq 3) { Get-Intel $URL_V19 "VMD_v19" }
    if ($M -eq 1 -or $M -eq 4) { Get-Intel $URL_V20 "VMD_v20" }

    if ((Get-ChildItem $SupportDir -Directory).Count -gt 0) {
        if (!$global:TargetUSB) { Refresh-USB }
        if ($global:TargetUSB) {
            Log "Copying to $global:TargetUSB..." "Cyan"
            Copy-Item "$WorkDir\Autounattend.xml" $global:TargetUSB -Force
            Copy-Item $SupportDir $global:TargetUSB -Recurse -Force
            Log "COMPLETE" "Green"
            [Windows.Forms.MessageBox]::Show("Files Saved to USB!", "Success")
        } else {
            [Windows.Forms.MessageBox]::Show("Done. Files in Temp.", "Info")
        }
    } else {
        Log "FAILED" "Red"; [Windows.Forms.MessageBox]::Show("Failed", "Error")
    }
}

function Add-Btn {
    param($T, $Y, $C, $M, $IsBIOS=$false, $IsAct=$false)
    $b = New-Object Windows.Forms.Button
    $W = if ($IsAct) { 220 } else { 450 }
    $X = if ($IsAct -and $M -eq "EXIT") { 320 } else { 90 }
    $b.Text = $T; $b.Size = New-Object Drawing.Size($W, 50); $b.Location = New-Object Drawing.Point($X, $Y)
    $b.ForeColor = $C; $b.FlatStyle = "Flat"; $b.Font = New-Object Drawing.Font("Consolas", 10, 1)
    $b.Tag = $M
    
    $b.Add_MouseEnter({ $this.Location = New-Object Drawing.Point(($this.Location.X + (Get-Random -Min -1 -Max 1)), ($this.Location.Y + (Get-Random -Min -1 -Max 1))) })
    $b.Add_MouseLeave({ $this.Location = New-Object Drawing.Point($X, $Y) }) # Reset pos
    
    if ($IsBIOS) { $b.Add_Click({ 
        if ([Windows.Forms.MessageBox]::Show("Reboot to BIOS?", "?", "YesNo") -eq "Yes") { 
            Start-Process "shutdown.exe" -Arg "/r /fw /t 0" -NoNewWindow 
        } 
    }) }
    elseif ($M -eq "OPEN") { $b.Add_Click({ if ($global:TargetUSB) { Invoke-Item $global:TargetUSB } else { Invoke-Item $WorkDir } }) }
    elseif ($M -eq "EXIT") { $b.Add_Click({ $form.Close() }) }
    else { $b.Add_Click({ Build-Process -M $this.Tag }) }
    $form.Controls.Add($b)
}

Add-Btn "[ 1 ] Build USB (All VMDs)" 150 "Magenta" 1
Add-Btn "[ 2 ] Build USB (v18 Only)" 220 "Yellow" 2
Add-Btn "[ 3 ] Build USB (v19 Only)" 290 "Yellow" 3
Add-Btn "[ 4 ] Build USB (v20 Only)" 360 "Yellow" 4
Add-Btn "[ B ] Go to Firmware/BIOS" 450 "Red" "BIOS" $true
Add-Btn "[ O ] Open Target!" 530 "Cyan" "OPEN" $false $true
Add-Btn "[ X ] Exit" 530 "Green" "EXIT" $false $true

$cbShow.Add_CheckedChanged({ Refresh-USB })
$btnCopy.Add_Click({ Manual-Copy })

$form.Add_FormClosed({ $Running = $false; try { $timer.Stop() } catch {}; [Environment]::Exit(0) })
$timer = New-Object Windows.Forms.Timer; $timer.Interval = 2000; $timer.Add_Tick({ Refresh-USB }); $timer.Start()
Refresh-USB

$lnk = New-Object Windows.Forms.LinkLabel
$lnk.Text = "#GitHub"; $lnk.LinkColor = "Cyan"; $lnk.Font = New-Object Drawing.Font("Consolas", 9, 1)
$lnk.AutoSize = $true; $lnk.Location = New-Object Drawing.Point(530, 635)
$lnk.Add_LinkClicked({ Start-Process "https://github.com/itgroceries-sudo/VMD-USB-Builder" })
$form.Controls.Add($lnk)

$ft = New-Object Windows.Forms.Label
$ft.Text = "Powered by IT Groceries Shop (v$AppVer)"; $ft.ForeColor = "Gray"; $ft.Dock = "Bottom"; $ft.TextAlign = "MiddleCenter"
$form.Controls.Add($ft)

[void]$form.ShowDialog()
