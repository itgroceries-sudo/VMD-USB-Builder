<#
.SYNOPSIS
    Web Launcher for Win10-SetupDisk
    Downloads and runs Setup.cmd from GitHub
#>

# =========================================================
#  VMD USB Builder by IT Groceries Shop (v16.5 Stable)
# =========================================================

$ErrorActionPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# [DATE CONFIG] Get Current Date
$DateStr = Get-Date -Format "dd-MM-yyyy"

# --- [SELF-DOWNLOAD & ADMIN CHECK] ---
$CurrentScript = $PSCommandPath
if (-not $CurrentScript) {
    # Web-Launch Mode
    $WebSource = "https://raw.githubusercontent.com/itgroceries-sudo/VMD-USB-Builder/main/USB_Builder.ps1"
    $TempScript = "$env:TEMP\USB_Builder.ps1"
    Write-Host "Downloading script..." -ForegroundColor Cyan
    try { Invoke-WebRequest -Uri $WebSource -OutFile $TempScript -UserAgent "Mozilla/5.0" -UseBasicParsing -ErrorAction Stop } 
    catch { Write-Host "Download Error." -ForegroundColor Red; Start-Sleep 3; exit }
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$TempScript`"" -Verb RunAs
    exit
}

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$CurrentScript`"" -Verb RunAs
    exit
}

# --- [WIN32 API] ---
$Win32 = Add-Type -MemberDefinition @"
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern IntPtr LoadImage(IntPtr hinst, string lpszName, uint uType, int cxDesired, int cyDesired, uint fuLoad);
"@ -Name "Win32Utils" -Namespace Win32 -PassThru

# --- [CONFIG] ---
$GitLabRaw   = "https://gitlab.com/itgroceries/itg_vmd_builder/-/raw/main"
$WorkDir     = "$env:TEMP\ITG_VMD_Build"
$SupportDir  = "$WorkDir\Support"
$script:Running = $true

# [ICONS]
$IconGoogle  = "$env:TEMP\Google.ico"
$IconITG     = "$env:TEMP\ITG.ico"
$UrlGoogle   = "https://www.google.com/favicon.ico"
$UrlITG      = "https://itgroceries.blogspot.com/favicon.ico"

# [INTEL DRIVERS]
$URL_V18 = "https://downloadmirror.intel.com/773229/SetupRST.exe"
$URL_V19 = "https://downloadmirror.intel.com/849934/SetupRST.exe"
$URL_V20 = "https://downloadmirror.intel.com/865363/SetupRST.exe"

# --- [SETUP] ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

try {
    Invoke-WebRequest -Uri $UrlGoogle -OutFile $IconGoogle -UserAgent "Mozilla/5.0" -UseBasicParsing
    Invoke-WebRequest -Uri $UrlITG -OutFile $IconITG -UserAgent "Mozilla/5.0" -UseBasicParsing
} catch {}

# Console Setup
$ConsoleHandle = $Win32::GetConsoleWindow()
$ScreenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width
$ScreenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height
$WinWidth = 650
$WinHeight = 700
$LeftX = ($ScreenWidth / 2) - $WinWidth
$RightX = ($ScreenWidth / 2)
$CenterY = ($ScreenHeight / 2) - ($WinHeight / 2)

if (Test-Path $IconGoogle) {
    $hIcon = $Win32::LoadImage([IntPtr]::Zero, $IconGoogle, 1, 0, 0, 0x10)
    if ($hIcon -ne [IntPtr]::Zero) { [void]$Win32::SendMessage($ConsoleHandle, 0x80, [IntPtr]0, $hIcon); [void]$Win32::SendMessage($ConsoleHandle, 0x80, [IntPtr]1, $hIcon) }
}
[void]$Win32::SetWindowPos($ConsoleHandle, [IntPtr]::Zero, $LeftX, $CenterY, $WinWidth, $WinHeight, 0x0040)

Clear-Host
$Host.UI.RawUI.BackgroundColor = "Black"; $Host.UI.RawUI.ForegroundColor = "Green"; Clear-Host
Write-Host "`n`n`n      ==================================================" -ForegroundColor Cyan
Write-Host "          IT GROCERIES CONSOLE [$DateStr]       " -ForegroundColor White
Write-Host "      ==================================================" -ForegroundColor Cyan
Write-Host "`n      [ SYSTEM STATUS ]" -ForegroundColor Yellow
Write-Host "      > Initializing..."
Write-Host "      > Waiting for user input..." -ForegroundColor Gray

# WinForm Setup
$form = New-Object Windows.Forms.Form
$form.Text = "VMD USB Builder by IT Groceries Shop [$DateStr]"
$form.Size = New-Object Drawing.Size($WinWidth, $WinHeight)
$form.BackColor = [Drawing.Color]::Black
$form.FormBorderStyle = [Windows.Forms.FormBorderStyle]::FixedDialog
$form.StartPosition = [Windows.Forms.FormStartPosition]::Manual
$form.Location = New-Object Drawing.Point($RightX, $CenterY)
$form.KeyPreview = $true
if (Test-Path $IconITG) { $form.Icon = New-Object Drawing.Icon($IconITG) }

$global:TargetUSB = $null
$rnd = New-Object System.Random
$AntiGravity = { $this.Location = New-Object Drawing.Point(($this.Location.X + $rnd.Next(-12, 13)), ($this.Location.Y + $rnd.Next(-12, 13))) }

# --- [UI HEADER] ---
$lblHeader = New-Object Windows.Forms.Label
$lblHeader.Text = "--- VMD USB BUILDER v16.5 (Stable) ---"
$lblHeader.ForeColor = [Drawing.Color]::Cyan
$lblHeader.Font = New-Object Drawing.Font("Consolas", 12, [Drawing.FontStyle]::Bold)
$lblHeader.TextAlign = [Drawing.ContentAlignment]::MiddleCenter
$lblHeader.Dock = [Windows.Forms.DockStyle]::Top
$lblHeader.Height = 40
$form.Controls.Add($lblHeader)

$cmbUSB = New-Object Windows.Forms.ComboBox
$cmbUSB.Width = 450; $cmbUSB.Height = 40; $cmbUSB.Location = New-Object Drawing.Point(90, 50)
$cmbUSB.Font = New-Object Drawing.Font("Consolas", 12, [Drawing.FontStyle]::Bold)
$cmbUSB.BackColor = [Drawing.Color]::DimGray; $cmbUSB.ForeColor = [Drawing.Color]::White
$cmbUSB.DropDownStyle = [Windows.Forms.ComboBoxStyle]::DropDownList
$form.Controls.Add($cmbUSB)

$lblStatus = New-Object Windows.Forms.Label
$lblStatus.Text = "Scanning for USB..."
$lblStatus.ForeColor = [Drawing.Color]::Yellow
$lblStatus.Font = New-Object Drawing.Font("Consolas", 10)
$lblStatus.TextAlign = [Drawing.ContentAlignment]::MiddleCenter
$lblStatus.Location = New-Object Drawing.Point(0, 90); $lblStatus.Width = $WinWidth
$form.Controls.Add($lblStatus)

# --- [FUNCTIONS] ---

function Update-Console { param($Msg, $Color="White"); Write-Host "      > $Msg" -ForegroundColor $Color }

function Refresh-USB-List {
    $drives = Get-Volume -ErrorAction SilentlyContinue | Where-Object {$_.DriveType -eq 'Removable' -and $_.DriveLetter -ne $null} | Sort-Object DriveLetter
    if ($cmbUSB.Items.Count -ne $drives.Count -or $cmbUSB.Items.Count -eq 0) {
        $cmbUSB.Items.Clear()
        if ($drives) {
            foreach ($d in $drives) {
                $SizeGB = [math]::Round($d.SizeRemaining / 1GB, 2)
                $Label = if ($d.FriendlyName) { $d.FriendlyName } else { "USB Drive" }
                [void]$cmbUSB.Items.Add("[$($d.DriveLetter):] $Label ($SizeGB GB Free)")
            }
            if ($cmbUSB.SelectedIndex -eq -1 -and $cmbUSB.Items.Count -gt 0) { $cmbUSB.SelectedIndex = 0 }
        } else { $cmbUSB.Items.Clear(); $cmbUSB.Text = "No USB Found" }
    }
    if ($cmbUSB.SelectedIndex -ne -1) {
        $global:TargetUSB = $cmbUSB.SelectedItem.ToString().Substring(1, 2) + "\"
        $lblStatus.Text = "Target Ready: $global:TargetUSB"; $lblStatus.ForeColor = [Drawing.Color]::Lime
    } else {
        $global:TargetUSB = $null; $lblStatus.Text = "Please insert USB Drive..."; $lblStatus.ForeColor = [Drawing.Color]::Red
    }
}

function Open-Target {
    if ($global:TargetUSB -ne $null) { Invoke-Item $global:TargetUSB } elseif (Test-Path $WorkDir) { Invoke-Item $WorkDir } 
    else { [Windows.Forms.MessageBox]::Show("No target folder available.", "Info") }
}

function GoTo-BIOS {
    # [FIX] เพิ่ม Try/Catch ป้องกัน Error 203 ถ้าเข้า BIOS ไม่ได้จะ Restart ปกติแทน
    if ([Windows.Forms.MessageBox]::Show("Restart to BIOS?", "GO2BIOS", "YesNo") -eq "Yes") {
        try {
            Start-Process "shutdown.exe" -ArgumentList "/r /fw /t 0" -NoNewWindow -ErrorAction Stop
        } catch {
            Start-Process "shutdown.exe" -ArgumentList "/r /t 0" -NoNewWindow
        }
    }
}

function Close-App {
    $script:Running = $false # สั่งหยุด Loop
    try { $timer.Stop() } catch {}
    $form.Close()
    [System.Environment]::Exit(0)
}

function Get-And-Extract-IntelEXE {
    param ($Url, $DestName)
    $ExePath = "$WorkDir\$DestName.exe"; $ExtractPath = "$WorkDir\Temp_Extract_$DestName"
    Update-Console "Downloading $DestName..." "Cyan"
    try { Invoke-WebRequest -Uri $Url -OutFile $ExePath -UserAgent "Mozilla/5.0" -UseBasicParsing -ErrorAction Stop } 
    catch { Update-Console "Download Failed!" "Red"; return }
    
    if (Test-Path $ExePath) {
        Update-Console "Extracting drivers..." "Gray"
        try {
            Start-Process -FilePath $ExePath -ArgumentList "-extractdrivers `"$ExtractPath`"" -Wait -PassThru -WindowStyle Hidden
            $InfFile = Get-ChildItem -Path $ExtractPath -Recurse -Filter "iaStorVD.inf" | Select-Object -First 1
            if ($InfFile) {
                $FinalDest = "$SupportDir\$DestName"
                if (!(Test-Path $FinalDest)) { New-Item -ItemType Directory -Path $FinalDest | Out-Null }
                Copy-Item -Path "$($InfFile.Directory.FullName)\*" -Destination $FinalDest -Recurse -Force
                Update-Console "SUCCESS: $DestName Ready." "Green"
            } else { Update-Console "iaStorVD.inf NOT FOUND." "Red" }
            Remove-Item $ExePath -Force -ErrorAction SilentlyContinue
            Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
        } catch { Update-Console "Extraction Error." "Red" }
    }
}

function Build-VMD-Process {
    param($Mode)
    Update-Console "--- STARTED BUILD PROCESS ---" "Yellow"
    if (Test-Path $WorkDir) { Remove-Item $WorkDir -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $SupportDir -Force | Out-Null
    Update-Console "Syncing GitLab Files..." "White"
    try {
        Invoke-WebRequest -Uri "$GitLabRaw/Autounattend.xml" -OutFile "$WorkDir\Autounattend.xml" -UserAgent "Mozilla/5.0" -UseBasicParsing -ErrorAction Stop
        Invoke-WebRequest -Uri "$GitLabRaw/VMD_Installer.cmd" -OutFile "$SupportDir\VMD_Installer.cmd" -UserAgent "Mozilla/5.0" -UseBasicParsing -ErrorAction Stop
    } catch { [Windows.Forms.MessageBox]::Show("GitLab Sync Failed. Check Internet.", "Error"); return }

    if ($Mode -eq 1 -or $Mode -eq 2) { Get-And-Extract-IntelEXE $URL_V18 "VMD_v18" }
    if ($Mode -eq 1 -or $Mode -eq 3) { Get-And-Extract-IntelEXE $URL_V19 "VMD_v19" }
    if ($Mode -eq 1 -or $Mode -eq 4) { Get-And-Extract-IntelEXE $URL_V20 "VMD_v20" }

    if ((Get-ChildItem $SupportDir -Directory).Count -gt 0) {
        if ($global:TargetUSB -eq $null) {
            Refresh-USB-List
            if ($global:TargetUSB -eq $null) {
                 if ([Windows.Forms.MessageBox]::Show("Drivers are ready in Temp!`n`nInsert USB to copy?", "Ready", "YesNo", "Question") -eq "Yes") {
                     Update-Console "Waiting for USB insertion..." "Yellow"
                     # [FIX] ใช้ตัวแปร $script:Running เพื่อให้กด Exit แล้วออกจาก Loop ได้
                     while ($global:TargetUSB -eq $null -and $script:Running) {
                         [System.Windows.Forms.Application]::DoEvents()
                         Refresh-USB-List
                         Start-Sleep -Milliseconds 500
                         if ($form.IsDisposed) { return }
                     }
                     if (!$script:Running) { return } # ถ้ากด Exit ให้ออกเลย
                 } else {
                     Update-Console "Skipped USB Copy." "Yellow"
                     [Windows.Forms.MessageBox]::Show("Files are in Temp folder.`nClick 'Open Target' to view.", "Finished")
                     return
                 }
            }
        }
        if ($global:TargetUSB -ne $null) {
            Update-Console "Copying to $($global:TargetUSB)..." "Cyan"
            Copy-Item -Path "$WorkDir\Autounattend.xml" -Destination $global:TargetUSB -Force
            Copy-Item -Path $SupportDir -Destination $global:TargetUSB -Recurse -Force
            Remove-Item $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
            Update-Console "--- JOB COMPLETE ---" "Green"
            [Windows.Forms.MessageBox]::Show("Complete! Files saved to $($global:TargetUSB)", "Success")
        }
    } else {
        Update-Console "FAILED: No drivers found." "Red"
        [Windows.Forms.MessageBox]::Show("Extraction Failed.", "Error")
    }
}

# --- [BUTTONS] ---
function Add-Btn {
    param($Txt, $Y, $Color, $M, $IsBIOS=$false, $IsAction=$false)
    $b = New-Object Windows.Forms.Button
    $W = if ($IsAction) { 220 } else { 450 }
    $X = if ($IsAction -and $M -eq "EXIT") { 320 } else { 90 }
    
    $b.Text = $Txt; $b.Size = New-Object Drawing.Size($W, 50); $b.Location = New-Object Drawing.Point($X, $Y)
    $b.ForeColor = [Drawing.Color]::$Color; $b.FlatStyle = [Windows.Forms.FlatStyle]::Flat
    $b.Font = New-Object Drawing.Font("Consolas", 10, [Drawing.FontStyle]::Bold)
    $b.Tag = $M; $b.Add_MouseEnter($AntiGravity)
    
    if ($IsBIOS) { $b.Add_Click({ GoTo-BIOS }) }
    elseif ($M -eq "OPEN") { $b.Add_Click({ Open-Target }) }
    elseif ($M -eq "EXIT") { $b.Add_Click({ Close-App }) }
    else { $b.Add_Click({ Build-VMD-Process -Mode $this.Tag }) }
    $form.Controls.Add($b)
}

Add-Btn "[ 1 ] Build USB (All VMDs)" 130 "Magenta" 1
Add-Btn "[ 2 ] Build USB (v18 Only)" 200 "Yellow" 2
Add-Btn "[ 3 ] Build USB (v19 Only)" 270 "Yellow" 3
Add-Btn "[ 4 ] Build USB (v20 Only)" 340 "Yellow" 4
Add-Btn "[ B ] Go to Firmware/BIOS" 430 "Red" "BIOS" $true
Add-Btn "[ O ] Open Target!" 510 "Cyan" "OPEN" $false $true
Add-Btn "[ X ] Exit" 510 "Green" "EXIT" $false $true

# --- [EVENTS] ---
$form.Add_KeyDown({
    if ($_.KeyCode -eq 'D1' -or $_.KeyCode -eq 'NumPad1') { Build-VMD-Process -Mode 1 }
    if ($_.KeyCode -eq 'D2' -or $_.KeyCode -eq 'NumPad2') { Build-VMD-Process -Mode 2 }
    if ($_.KeyCode -eq 'D3' -or $_.KeyCode -eq 'NumPad3') { Build-VMD-Process -Mode 3 }
    if ($_.KeyCode -eq 'D4' -or $_.KeyCode -eq 'NumPad4') { Build-VMD-Process -Mode 4 }
    if ($_.KeyCode -eq 'B') { GoTo-BIOS }
    if ($_.KeyCode -eq 'O') { Open-Target }
    if ($_.KeyCode -eq 'X') { Close-App }
})

$form.Add_FormClosed({ Close-App })

$timer = New-Object Windows.Forms.Timer; $timer.Interval = 2000; $timer.Add_Tick({ Refresh-USB-List }); $timer.Start()
Refresh-USB-List

$footer = New-Object Windows.Forms.Label
$footer.Text = "Powered by IT Groceries Shop && my Teams ([$DateStr])"
$footer.ForeColor = [Drawing.Color]::Gray; $footer.Dock = [Windows.Forms.DockStyle]::Bottom; $footer.TextAlign = [Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($footer)

[void]$form.ShowDialog()
Close-App





