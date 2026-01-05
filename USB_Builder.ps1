<# : hybrid batch + powershell script
@powershell -noprofile -Window Hidden -c "$param='%*';$ScriptPath='%~f0';iex((Get-Content('%~f0') -Raw))"&exit/b
#>

# VMD USB Builder v2.0 (Clean Version)
$ErrorActionPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$AppVer   = "2.0"
$AppBuild = "16.9"
$DateStr = Get-Date -Format "dd-MM-yyyy"
$WindowTitle  = "IT GROCERIES GUI [Date: $DateStr]"
$ConsoleTitle = "IT GROCERIES CONSOLE"

$CurrentScript = $PSCommandPath
if (-not $CurrentScript) {
    $WebSource = "https://raw.githubusercontent.com/itgroceries-sudo/VMD-USB-Builder/main/USB_Builder.ps1"
    $TempScript = "$env:TEMP\USB_Builder.ps1"
    try { Invoke-WebRequest -Uri $WebSource -OutFile $TempScript -UseBasicParsing -ErrorAction Stop } 
    catch { exit }
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$TempScript`"" -Verb RunAs
    exit
}

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$CurrentScript`"" -Verb RunAs
    exit
}

$Win32 = Add-Type -MemberDefinition @"
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern IntPtr LoadImage(IntPtr hinst, string lpszName, uint uType, int cxDesired, int cyDesired, uint fuLoad);
    [DllImport("user32.dll")] public static extern IntPtr GetSystemMenu(IntPtr hWnd, bool bRevert);
    [DllImport("user32.dll")] public static extern bool DeleteMenu(IntPtr hMenu, uint uPosition, uint uFlags);
"@ -Name "Win32Utils" -Namespace Win32 -PassThru

$GitHubRaw   = "https://raw.githubusercontent.com/itgroceries-sudo/VMD-USB-Builder/main"
$WorkDir     = "$env:TEMP\ITG_VMD_Build"
$SupportDir  = "$WorkDir\Support"
$script:Running = $true

$IconGoogle  = "$env:TEMP\Google.ico"
$IconITG     = "$env:TEMP\ITG.ico"
$URL_V18 = "https://downloadmirror.intel.com/773229/SetupRST.exe"
$URL_V19 = "https://downloadmirror.intel.com/849934/SetupRST.exe"
$URL_V20 = "https://downloadmirror.intel.com/865363/SetupRST.exe"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

try {
    Invoke-WebRequest "https://www.google.com/favicon.ico" -OutFile $IconGoogle -UseBasicParsing
    Invoke-WebRequest "https://itgroceries.blogspot.com/favicon.ico" -OutFile $IconITG -UseBasicParsing
} catch {}

$ConsoleHandle = $Win32::GetConsoleWindow()
$Host.UI.RawUI.WindowTitle = "$ConsoleTitle"

$ScreenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width
$ScreenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height
$WinWidth = 650
$WinHeight = 700
$LeftX = ($ScreenWidth / 2) - $WinWidth
$RightX = ($ScreenWidth / 2)
$CenterY = ($ScreenHeight / 2) - ($WinHeight / 2)

if (Test-Path $IconGoogle) {
    $hIcon = $Win32::LoadImage([IntPtr]::Zero, $IconGoogle, 1, 0, 0, 0x10)
    if ($hIcon -ne [IntPtr]::Zero) { 
        [void]$Win32::SendMessage($ConsoleHandle, 0x80, [IntPtr]0, $hIcon)
        [void]$Win32::SendMessage($ConsoleHandle, 0x80, [IntPtr]1, $hIcon) 
    }
}

[void]$Win32::SetWindowPos($ConsoleHandle, [IntPtr]::Zero, $LeftX, $CenterY, $WinWidth, $WinHeight, 0x0040)

$hMenu = $Win32::GetSystemMenu($ConsoleHandle, $false)
if ($hMenu -ne [IntPtr]::Zero) {
    [void]$Win32::DeleteMenu($hMenu, 0xF010, 0x0000)
    [void]$Win32::DeleteMenu($hMenu, 0xF060, 0x0000)
    [void]$Win32::DeleteMenu($hMenu, 0xF030, 0x0000)
    [void]$Win32::DeleteMenu($hMenu, 0xF000, 0x0000)
}

Clear-Host
$Host.UI.RawUI.BackgroundColor = "Black"; $Host.UI.RawUI.ForegroundColor = "Green"; Clear-Host
Write-Host "`n`n`n      ==================================================" -ForegroundColor Cyan
Write-Host "             $ConsoleTitle             " -ForegroundColor White
Write-Host "      ==================================================" -ForegroundColor Cyan
Write-Host "`n      [ SYSTEM STATUS ]" -ForegroundColor Yellow
Write-Host "      > Initializing..."

$form = New-Object Windows.Forms.Form
$form.Text = "$WindowTitle"
$form.Size = New-Object Drawing.Size($WinWidth, $WinHeight)
$form.BackColor = [Drawing.Color]::Black
$form.FormBorderStyle = [Windows.Forms.FormBorderStyle]::None 
$form.StartPosition = [Windows.Forms.FormStartPosition]::Manual
$form.Location = New-Object Drawing.Point($RightX, $CenterY)
$form.KeyPreview = $true

$form.Add_Paint({
    param($sender, $e)
    $Control = $sender
    $PenColor = [System.Drawing.Color]::Cyan
    $PenWidth = 2
    
    # Create Pen
    $Pen = New-Object System.Drawing.Pen($PenColor, $PenWidth)
    
    # Calculate Rectangle (Inset by half width to ensure border is inside)
    $Rect = New-Object System.Drawing.Rectangle(
        [int]($PenWidth / 2), 
        [int]($PenWidth / 2), 
        [int]($Control.ClientSize.Width - $PenWidth), 
        [int]($Control.ClientSize.Height - $PenWidth)
    )
    
    # Draw Rectangle
    $e.Graphics.DrawRectangle($Pen, $Rect)
    
    # Dispose Pen to free resources
    $Pen.Dispose()
})

if (Test-Path $IconITG) { $form.Icon = New-Object Drawing.Icon($IconITG) }

$global:TargetUSB = $null
$rnd = New-Object System.Random

$lblHeader = New-Object Windows.Forms.Label
$lblHeader.Text = "--- VMD USB BUILDER v$AppVer Build$AppBuild ---"
$lblHeader.ForeColor = [Drawing.Color]::Cyan
$lblHeader.Font = New-Object Drawing.Font("Consolas", 12, [Drawing.FontStyle]::Bold)
$lblHeader.TextAlign = [Drawing.ContentAlignment]::MiddleCenter
$lblHeader.Dock = [Windows.Forms.DockStyle]::Top
$lblHeader.Height = 40
$lblHeader.Add_MouseDown({ $form.Capture = $false }) 
$form.Controls.Add($lblHeader)

$cmbUSB = New-Object Windows.Forms.ComboBox
$cmbUSB.Width = 450; $cmbUSB.Height = 40; $cmbUSB.Location = New-Object Drawing.Point(90, 50)
$cmbUSB.Font = New-Object Drawing.Font("Consolas", 12, [Drawing.FontStyle]::Bold)
$cmbUSB.BackColor = [Drawing.Color]::DimGray; $cmbUSB.ForeColor = [Drawing.Color]::White
$cmbUSB.DropDownStyle = [Windows.Forms.ComboBoxStyle]::DropDownList
$form.Controls.Add($cmbUSB)

$cbShowAll = New-Object Windows.Forms.CheckBox
$cbShowAll.Text = "Show All Drives"
$cbShowAll.Font = New-Object Drawing.Font("Consolas", 9)
$cbShowAll.ForeColor = [Drawing.Color]::Gray
$cbShowAll.Location = New-Object Drawing.Point(90, 92)
$cbShowAll.Size = New-Object Drawing.Size(200, 20)
$form.Controls.Add($cbShowAll)
$script:cbShowAll = $cbShowAll 

$btnCopy = New-Object Windows.Forms.Button
$btnCopy.Text = "Copy to Drive >"
$btnCopy.Font = New-Object Drawing.Font("Consolas", 9, [Drawing.FontStyle]::Bold)
$btnCopy.ForeColor = [Drawing.Color]::White
$btnCopy.BackColor = [Drawing.Color]::RoyalBlue
$btnCopy.FlatStyle = [Windows.Forms.FlatStyle]::Flat
$btnCopy.Location = New-Object Drawing.Point(390, 90)
$btnCopy.Size = New-Object Drawing.Size(150, 24)
$form.Controls.Add($btnCopy)

$lblStatus = New-Object Windows.Forms.Label
$lblStatus.Text = "Scanning for USB..."
$lblStatus.ForeColor = [Drawing.Color]::Yellow
$lblStatus.Font = New-Object Drawing.Font("Consolas", 10)
$lblStatus.TextAlign = [Drawing.ContentAlignment]::MiddleCenter
$lblStatus.Location = New-Object Drawing.Point(4, 118)
$lblStatus.Size = New-Object Drawing.Size(($WinWidth - 8), 20) 
$form.Controls.Add($lblStatus)

function Update-Console { param($Msg, $Color="White"); Write-Host "      > $Msg" -ForegroundColor $Color }

function Refresh-USB-List {
    $SysDrive = $env:SystemDrive.Substring(0,1)
    $drives = Get-Volume -ErrorAction SilentlyContinue | Where-Object {
        if ($script:cbShowAll.Checked) {
            ($_.DriveType -eq 'Removable' -or $_.DriveType -eq 'Fixed') -and $_.DriveLetter -ne $null -and $_.DriveLetter -ne $SysDrive
        } else {
            $_.DriveType -eq 'Removable' -and $_.DriveLetter -ne $null
        }
    } | Sort-Object DriveLetter

    if ($cmbUSB.Items.Count -ne $drives.Count -or $cmbUSB.Items.Count -eq 0) {
        $cmbUSB.Items.Clear()
        if ($drives) {
            foreach ($d in $drives) {
                $SizeGB = [math]::Round($d.SizeRemaining / 1GB, 2)
                $Label = if ($d.FileSystemLabel) { $d.FileSystemLabel } else { "USB Drive" }
                [void]$cmbUSB.Items.Add("[$($d.DriveLetter):] $Label ($SizeGB GB Free)")
            }
            if ($cmbUSB.SelectedIndex -eq -1 -and $cmbUSB.Items.Count -gt 0) { $cmbUSB.SelectedIndex = 0 }
        } else { 
            $cmbUSB.Items.Clear()
            if ($script:cbShowAll.Checked) { $cmbUSB.Text = "No Drives Found" } else { $cmbUSB.Text = "No USB Found" }
        }
    }
    if ($cmbUSB.SelectedIndex -ne -1) {
        $global:TargetUSB = $cmbUSB.SelectedItem.ToString().Substring(1, 2) + "\"
        $lblStatus.Text = "Target Ready: $global:TargetUSB"; $lblStatus.ForeColor = [Drawing.Color]::Lime
    } else {
        $global:TargetUSB = $null; $lblStatus.Text = "Please Select Drive..."; $lblStatus.ForeColor = [Drawing.Color]::Red
    }
}

function Start-Manual-Copy {
    if ($global:TargetUSB -eq $null) {
        [Windows.Forms.MessageBox]::Show("Please select a target drive first!", "Error")
        return
    }
    if (-not (Test-Path "$SupportDir\VMD_Installer.cmd")) {
        [Windows.Forms.MessageBox]::Show("No drivers found. Build files first.", "Files Not Ready")
        return
    }

    $ans = [Windows.Forms.MessageBox]::Show("Copy files to ALL partitions on USB?", "Confirm Smart Copy", "YesNo", "Question")
    if ($ans -eq "Yes") {
        $DriveLetter = $global:TargetUSB.Substring(0,1)
        try {
            $DiskNum = (Get-Partition -DriveLetter $DriveLetter).DiskNumber
            $Partitions = Get-Partition -DiskNumber $DiskNum | Where-Object { $_.DriveLetter -ne 0 }
            
            foreach ($P in $Partitions) {
                $Target = "$($P.DriveLetter):\"
                Update-Console "Copying .xml to $Target" "Cyan"
                Copy-Item -Path "$WorkDir\Autounattend.xml" -Destination $Target -Force
                
                $VolSize = (Get-Volume -DriveLetter $P.DriveLetter).SizeRemaining
                if ($VolSize -gt 2GB) { 
                     Update-Console "Copying VMD Drivers to Main Partition ($Target)" "Cyan"
                     Copy-Item -Path $SupportDir -Destination $Target -Recurse -Force
                }
            }
            Update-Console "--- COPY COMPLETE ---" "Green"
            [Windows.Forms.MessageBox]::Show("Files copied successfully.", "Success")
        } catch {
            Copy-Item -Path "$WorkDir\Autounattend.xml" -Destination $global:TargetUSB -Force
            Copy-Item -Path $SupportDir -Destination $global:TargetUSB -Recurse -Force
            [Windows.Forms.MessageBox]::Show("Fallback copy completed.", "Warning")
        }
    }
}

function Open-Target {
    if ($global:TargetUSB -ne $null) { Invoke-Item $global:TargetUSB } 
    elseif (Test-Path $WorkDir) { Invoke-Item $WorkDir } 
    else { [Windows.Forms.MessageBox]::Show("No target available.", "Info") }
}

function GoTo-BIOS {
    if ([Windows.Forms.MessageBox]::Show("Restart to BIOS?", "GO2BIOS", "YesNo") -eq "Yes") {
        try { Start-Process "shutdown.exe" -ArgumentList "/r /fw /t 0" -NoNewWindow -ErrorAction Stop } 
        catch { Start-Process "shutdown.exe" -ArgumentList "/r /t 0" -NoNewWindow }
    }
}

function Close-App {
    $script:Running = $false
    try { $timer.Stop() } catch {}
    $form.Close()
    [System.Environment]::Exit(0)
}

function Get-And-Extract-IntelEXE {
    param ($Url, $DestName)
    $ExePath = "$WorkDir\$DestName.exe"; $ExtractPath = "$WorkDir\Temp_Extract_$DestName"
    Update-Console "Downloading $DestName..." "Cyan"
    try { Invoke-WebRequest -Uri $Url -OutFile $ExePath -UseBasicParsing -ErrorAction Stop } 
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
            }
            Remove-Item $ExePath -Force -ErrorAction SilentlyContinue
            Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
        } catch {}
    }
}

function Build-VMD-Process {
    param($Mode)
    Update-Console "--- STARTED BUILD PROCESS ---" "Yellow"
    if (Test-Path $WorkDir) { Remove-Item $WorkDir -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $SupportDir -Force | Out-Null
    Update-Console "Syncing GitHub Files..." "White"
    try {
        Invoke-WebRequest "$GitHubRaw/Autounattend.xml" -OutFile "$WorkDir\Autounattend.xml" -UseBasicParsing -ErrorAction Stop
        Invoke-WebRequest "$GitHubRaw/VMD_Installer.cmd" -OutFile "$SupportDir\VMD_Installer.cmd" -UseBasicParsing -ErrorAction Stop
    } catch { [Windows.Forms.MessageBox]::Show("GitHub Sync Failed.", "Error"); return }

    if ($Mode -eq 1 -or $Mode -eq 2) { Get-And-Extract-IntelEXE $URL_V18 "VMD_v18" }
    if ($Mode -eq 1 -or $Mode -eq 3) { Get-And-Extract-IntelEXE $URL_V19 "VMD_v19" }
    if ($Mode -eq 1 -or $Mode -eq 4) { Get-And-Extract-IntelEXE $URL_V20 "VMD_v20" }

    if ((Get-ChildItem $SupportDir -Directory).Count -gt 0) {
        if ($global:TargetUSB -eq $null) {
            Refresh-USB-List
            if ($global:TargetUSB -eq $null) {
                 if ([Windows.Forms.MessageBox]::Show("Drivers ready. Insert USB?", "Ready", "YesNo") -eq "Yes") {
                     Update-Console "Waiting for USB..." "Yellow"
                     while ($global:TargetUSB -eq $null -and $script:Running) {
                         [System.Windows.Forms.Application]::DoEvents()
                         Refresh-USB-List
                         Start-Sleep -Milliseconds 500
                         if ($form.IsDisposed) { return }
                     }
                     if (!$script:Running) { return }
                 } else {
                     Update-Console "Skipped USB Copy." "Yellow"
                     [Windows.Forms.MessageBox]::Show("Files are in Temp folder.", "Finished")
                     return
                 }
            }
        }
        
        if ($global:TargetUSB -ne $null) {
            $DriveLetter = $global:TargetUSB.Substring(0,1)
            try {
                $DiskNum = (Get-Partition -DriveLetter $DriveLetter).DiskNumber
                $Partitions = Get-Partition -DiskNumber $DiskNum | Where-Object { $_.DriveLetter -ne 0 }
                
                foreach ($P in $Partitions) {
                    $Target = "$($P.DriveLetter):\"
                    Copy-Item -Path "$WorkDir\Autounattend.xml" -Destination $Target -Force
                    $VolSize = (Get-Volume -DriveLetter $P.DriveLetter).SizeRemaining
                    if ($VolSize -gt 2GB) {
                        Update-Console "Syncing Drivers -> $Target" "Cyan"
                        Copy-Item -Path $SupportDir -Destination $Target -Recurse -Force
                    }
                }
            } catch {
                Copy-Item -Path "$WorkDir\Autounattend.xml" -Destination $global:TargetUSB -Force
                Copy-Item -Path $SupportDir -Destination $global:TargetUSB -Recurse -Force
            }
            Update-Console "--- JOB COMPLETE ---" "Green"
            [Windows.Forms.MessageBox]::Show("Complete!", "Success")
        }
    } else {
        Update-Console "FAILED: No drivers found." "Red"
        [Windows.Forms.MessageBox]::Show("Extraction Failed.", "Error")
    }
}

function Add-Btn {
    param($Txt, $Y, $Color, $M, $IsBIOS=$false, $IsAction=$false)
    $b = New-Object Windows.Forms.Button
    $W = if ($IsAction) { 220 } else { 450 }
    $X = if ($IsAction -and $M -eq "EXIT") { 320 } else { 90 }
    $b.Text = $Txt; $b.Size = New-Object Drawing.Size($W, 50); $b.Location = New-Object Drawing.Point($X, $Y)
    $b.ForeColor = [Drawing.Color]::$Color; $b.FlatStyle = [Windows.Forms.FlatStyle]::Flat
    $b.Font = New-Object Drawing.Font("Consolas", 10, [Drawing.FontStyle]::Bold)
    $b.Tag = $M
    $b | Add-Member -MemberType NoteProperty -Name "Origin" -Value $b.Location
    $b.Add_MouseEnter({ $this.Location = New-Object Drawing.Point(($this.Origin.X + (Get-Random -Min -2 -Max 2)), ($this.Origin.Y + (Get-Random -Min -2 -Max 2))) })
    $b.Add_MouseLeave({ $this.Location = $this.Origin })
    
    if ($IsBIOS) { $b.Add_Click({ GoTo-BIOS }) }
    elseif ($M -eq "OPEN") { $b.Add_Click({ Open-Target }) }
    elseif ($M -eq "EXIT") { $b.Add_Click({ Close-App }) }
    else { $b.Add_Click({ Build-VMD-Process -Mode $this.Tag }) }
    $form.Controls.Add($b)
}

Add-Btn "[ 1 ] Build USB (All VMDs)" 150 "Magenta" 1
Add-Btn "[ 2 ] Build USB (v18 Only)" 220 "Yellow" 2
Add-Btn "[ 3 ] Build USB (v19 Only)" 290 "Yellow" 3
Add-Btn "[ 4 ] Build USB (v20 Only)" 360 "Yellow" 4
Add-Btn "[ B ] Go to Firmware/BIOS" 450 "Red" "BIOS" $true
Add-Btn "[ O ] Open Target!" 530 "Cyan" "OPEN" $false $true
Add-Btn "[ X ] Exit" 530 "Green" "EXIT" $false $true

$cbShowAll.Add_CheckedChanged({ Refresh-USB-List })
$btnCopy.Add_Click({ Start-Manual-Copy })

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

$lnkGit = New-Object Windows.Forms.LinkLabel
$lnkGit.Text = "#Link Github"
$lnkGit.LinkColor = [Drawing.Color]::Cyan
$lnkGit.Font = New-Object Drawing.Font("Consolas", 9, [Drawing.FontStyle]::Bold)
$lnkGit.AutoSize = $true
$lnkGit.Location = New-Object Drawing.Point(530, 635) 
$lnkGit.Add_LinkClicked({ Start-Process "https://github.com/itgroceries-sudo/VMD-USB-Builder/tree/main" })
$form.Controls.Add($lnkGit)

$footer = New-Object Windows.Forms.Label
$footer.Text = "Powered by IT Groceries Shop (v$AppVer Build$AppBuild)"
$footer.ForeColor = [Drawing.Color]::Gray; $footer.Dock = [Windows.Forms.DockStyle]::Bottom; $footer.TextAlign = [Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($footer)

[void]$form.ShowDialog()
Close-App



