# =========================================================
#   IT Groceries Shop Launcher (v8.2 - Intel EXE Edition)
# =========================================================
param([switch]$IsLegacyMode)
$ErrorActionPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# [CONFIG]
$GitLabRaw = "https://gitlab.com/itgroceries/itg_vmd_builder/-/raw/main"
$SelfScriptURL = "$GitLabRaw/VMD_Installer.ps1" 
$WorkDir   = "$env:TEMP\ITG_VMD_Build"
$SupportDir = "$WorkDir\Support"
$tmpDir  = "$env:TEMP"
$RandomID = -join ((48..57) | Get-Random -Count 4 | % {[char]$_})
$IconFile = "$tmpDir\ITGBlog.ico"

# --- [STEP 0] SELF-HIDE (Local Only) ---
if ($PSCommandPath -and (Test-Path $PSCommandPath)) {
    try { (Get-Item $PSCommandPath).Attributes = 'Hidden' } catch {}
}

# --- [STEP 1] ADMIN CHECK (WEB-AWARE FIX) ---
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    if (-not $PSCommandPath) {
		$TargetFile = "$env:TEMP\ITG_VMD_WebLauncher.ps1"
        try {
            Write-Host "Requesting Admin Access..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri $SelfScriptURL -OutFile $TargetFile -UseBasicParsing -ErrorAction Stop
        } catch {
            Write-Host "Error: Cannot download self for elevation." -ForegroundColor Red
            Pause
            exit
        }
    } else {
        $TargetFile = $PSCommandPath
    }

    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$TargetFile`"" -Verb RunAs
    exit
}

# --- [STEP 2] VISUAL HELPERS ---
$Host.UI.RawUI.WindowTitle = "VMD USB Builder by IT Groceries Shop"
try { mode con: cols=90 lines=25 } catch {}

# 2.1 Window & Icon
try {
    $def = @'
    [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h,int n);
    [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr h,int n,int w);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h,IntPtr i,int x,int y,int cx,int cy,uint f);
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern IntPtr LoadImage(IntPtr hinst, string lpszName, uint uType, int cxDesired, int cyDesired, uint fuLoad);
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
'@
    $win32 = Add-Type -MemberDefinition $def -Name 'Win32Tools' -Namespace Win32 -PassThru
    $hwnd = $win32::GetConsoleWindow()
    $style = $win32::GetWindowLong($hwnd, -16)
    [void]$win32::SetWindowLong($hwnd, -16, $style -band 0xFFFAFFFF) 
    
    if (-not (Test-Path $IconFile)) { try { Invoke-WebRequest -Uri "https://itgroceries.blogspot.com/favicon.ico" -OutFile $IconFile -UseBasicParsing } catch {} }
    if (Test-Path $IconFile) {
        try { (Get-Item $IconFile).Attributes = 'Hidden' } catch {}
        $hIcon = $win32::LoadImage([IntPtr]::Zero, $IconFile, 1, 0, 0, 0x10)
        if ($hIcon -ne [IntPtr]::Zero) { [void]$win32::SendMessage($hwnd, 0x80, [IntPtr]0, $hIcon); [void]$win32::SendMessage($hwnd, 0x80, [IntPtr]1, $hIcon) }
    }
} catch {}

# --- [INTEL EXE DOWNLOAD LINKS] ---
$URL_V18 = "https://downloadmirror.intel.com/773229/SetupRST.exe"
$URL_V19 = "https://downloadmirror.intel.com/849934/SetupRST.exe"
$URL_V20 = "https://downloadmirror.intel.com/865363/SetupRST.exe"

# 2.2 Draw Center
function Draw-Center {
    param ($Text, $Color="White", $Bg="Black")
    $W = 85; $Len = $Text.Length; if ($Len -gt $W) { $Len = $W }
    $Pad = [math]::Max(0, [int](($W - $Len) / 2))
    $Line = (" " * $Pad) + $Text + (" " * ($W - $Len - $Pad))
    Write-Host $Line -ForegroundColor $Color -BackgroundColor $Bg
}

# 2.3 [EFFECT] Typewriter
function Type-Writer {
    param([string]$Text, [string]$Color="Green", [int]$Speed=15)
    $W = 85; $Len = $Text.Length; $Pad = [math]::Max(0, [int](($W - $Len) / 2))
    Write-Host (" " * $Pad) -NoNewline
    $Text.ToCharArray() | ForEach-Object { Write-Host $_ -NoNewline -ForegroundColor $Color; Start-Sleep -Milliseconds $Speed }
    Write-Host ""
}

# 2.4 [EFFECT] Spinner
function Show-Spinner {
    param([string]$Text, [int]$Loops=10, [string]$Color="Cyan")
    $Frames = @("-", "\", "|", "/")
    $Pad = " " * 25
    $OriginalPos = $host.UI.RawUI.CursorPosition
    
    # Spinner
    1..$Loops | ForEach-Object {
        foreach ($f in $Frames) {
            $host.UI.RawUI.CursorPosition = $OriginalPos
            Write-Host $Pad -NoNewline
            Write-Host "[ $f ] " -ForegroundColor Cyan -NoNewline
            Write-Host $Text -ForegroundColor $Color -NoNewline
            Start-Sleep -Milliseconds 40
        }
    }
	
    $host.UI.RawUI.CursorPosition = $OriginalPos
    Write-Host $Pad -NoNewline
    Write-Host "[ OK ] " -ForegroundColor Green -NoNewline
    Write-Host "$Text (Done)    " -ForegroundColor DarkGray
    Write-Host ""
}

# --- [STEP 3] VMD LOGIC START 

function Get-HardwareInfo {
    try {
        $CPU = Get-CimInstance Win32_Processor
        $Model = $CPU.Name
        $Rec = "Universal (All Versions)"
        # Simple detection logic
        if ($Model -match "Gen" -and $Model -match "1[0-1]\w{2}") { $Rec = "v18 (Gen 10-11)" }
        elseif ($Model -match "12\w{2}") { $Rec = "v19 (Gen 12)" }
        elseif ($Model -match "13\w{2}") { $Rec = "v19/v20 (Gen 13)" }
        elseif ($Model -match "14\w{2}") { $Rec = "v20 (Gen 14)" }
        return @{ Model=$Model; Recommend=$Rec }
    } catch { return @{ Model="Unknown"; Recommend="Universal" } }
}

function Draw-MainUI {
    $HW = Get-HardwareInfo
    Clear-Host
    Write-Host "`n"
    Draw-Center "=====================================================================================" "DarkCyan"
    Draw-Center "VMD USB Builder" "White" "DarkCyan"
    Draw-Center "Powered by IT Groceries Shop" "Cyan"
    Draw-Center "=====================================================================================" "DarkCyan"
    Write-Host "`n"
    Draw-Center "[ System Detected ]" "Green"
    Draw-Center "CPU: $($HW.Model)" "Gray"
    Draw-Center "Recommendation: $($HW.Recommend)" "Magenta"
    Write-Host "`n"
    Write-Host ("-" * 85) -ForegroundColor DarkGray
}

function Get-And-Extract {
    param ($FileName, $DestName)
    $Url = "$GitLabRaw/$FileName"
    $ExePath = "$WorkDir\$FileName"
    $ExtractPath = "$WorkDir\Extracted_$DestName"

    Show-Spinner "Downloading $FileName..." 5 "Yellow"
    try {
        Invoke-WebRequest -Uri $Url -OutFile $ExePath -UserAgent "Mozilla/5.0" -UseBasicParsing -ErrorAction Stop
    } catch { return }

    if (Test-Path $ExePath) {
        Type-Writer "   > Extracting $FileName..." "DarkGray" 5
        try {
            $Process = Start-Process -FilePath $ExePath -ArgumentList "-extractdrivers `"$ExtractPath`"" -Wait -PassThru
            $InfFile = Get-ChildItem -Path $ExtractPath -Recurse -Filter "iaStorVD.inf" | Select-Object -First 1
            if ($InfFile) {
                Move-Item -Path $InfFile.Directory.FullName -Destination "$SupportDir\$DestName" -Force
            }
        } catch {}
    }
}

function Get-And-Extract-IntelEXE {
    param ($Url, $DestName)
    $ExePath = "$WorkDir\$DestName.exe"
    $ExtractPath = "$WorkDir\Temp_Extract_$DestName"

    Show-Spinner "Downloading $DestName (SetupRST.exe) from Intel..." 5 "Yellow"
    try {
                Invoke-WebRequest -Uri $Url -OutFile $ExePath -UserAgent "Mozilla/5.0" -UseBasicParsing -ErrorAction Stop
    } catch { 
        Write-Host "    			 [!] Failed to download $DestName" -ForegroundColor Red
        return 
    }

    if (Test-Path $ExePath) {
        Type-Writer "    > Extracting Drivers from Intel EXE..." "DarkGray" 5
        try {
            $process = Start-Process -FilePath $ExePath -ArgumentList "-extractdrivers `"$ExtractPath`"" -Wait -PassThru -WindowStyle Hidden
            $InfFile = Get-ChildItem -Path $ExtractPath -Recurse -Filter "iaStorVD.inf" | Select-Object -First 1
            
            if ($InfFile) {
                $FinalDest = "$SupportDir\$DestName"
                if (!(Test-Path $FinalDest)) { New-Item -ItemType Directory -Path $FinalDest | Out-Null }
                Copy-Item -Path "$($InfFile.Directory.FullName)\*" -Destination $FinalDest -Recurse -Force
				Write-Host "`n"
                Write-Host "    			 [OK] $DestName ready." -ForegroundColor Green
				Write-Host "`n"
            } else {
				Write-Host "`n"
                Write-Host "    			 [!] iaStorVD.inf not found in extracted files." -ForegroundColor Red
            }
            Remove-Item $ExePath -Force
            Remove-Item $ExtractPath -Recurse -Force
        } catch {
			Write-Host "`n"
            Write-Host "    			 [!] Error during extraction: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# --- [STEP 4] MAIN LOOP ---
while ($true) {
    Draw-MainUI
    Write-Host " [ Actions Menu ]" -ForegroundColor Yellow
    Write-Host " [ 1 ] Build USB (All Versions: v18, v19, v20)" -ForegroundColor White
    Write-Host " [ 2 ] Build USB (v18 Only - Gen 10/11)" -ForegroundColor White
    Write-Host " [ 3 ] Build USB (v19 Only - Gen 12/13)" -ForegroundColor White
    Write-Host " [ 4 ] Build USB (v20 Only - Gen 13/14+)" -ForegroundColor White
    Write-Host " [ X ] Exit" -ForegroundColor Red
    Write-Host ""
    
    $PadInput = " " * 25
    Write-Host $PadInput -NoNewline
	
    $Choice = Read-Host "[ MENU ] Select Option"

    
	if ($Choice -notin '1','2','3','4','X','x') {
        Write-Host ""
        Draw-Center "Invalid Selection! Please try again." "Red"
        Start-Sleep -Seconds 1
        continue
    }
    
    if ($Choice -eq 'Q' -or $Choice -eq 'q') { break }
	
    # Reset Environment
    if (Test-Path $WorkDir) { Remove-Item $WorkDir -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $SupportDir | Out-Null
    
    # 1. Download Configs
    Write-Host "`n"
    Show-Spinner "Fetching Config Files..." 8 "Cyan"
    try {
        Invoke-WebRequest -Uri "$GitLabRaw/Autounattend.xml" -OutFile "$WorkDir\Autounattend.xml" -UserAgent "Mozilla/5.0" -UseBasicParsing -ErrorAction Stop
        Invoke-WebRequest -Uri "$GitLabRaw/VMD_Installer.cmd" -OutFile "$SupportDir\VMD_Installer.cmd" -UserAgent "Mozilla/5.0" -UseBasicParsing -ErrorAction Stop
    } catch { Type-Writer "Error: GitLab Connection Failed." "Red"; Pause; continue }

    # 2. Download Drivers
    Write-Host ""

    switch ($Choice) {
        '1' { 
            Get-And-Extract-IntelEXE $URL_V18 "VMD_v18"
            Get-And-Extract-IntelEXE $URL_V19 "VMD_v19"
            Get-And-Extract-IntelEXE $URL_V20 "VMD_v20"
        }
        '2' { Get-And-Extract-IntelEXE $URL_V18 "VMD_v18" }
        '3' { Get-And-Extract-IntelEXE $URL_V19 "VMD_v19" }
        '4' { Get-And-Extract-IntelEXE $URL_V20 "VMD_v20" }
    }

    # --- [NEW FEATURE: DELAY & USB SELECTION] ---
    
    # Delay 3 Seconds
    Write-Host "`n"
    Draw-Center "Extraction Complete. Preparing Drive Selection..." "Green"
    Start-Sleep -Seconds 3

    # USB Selection Loop
    $TargetRoot = $null
    
    while ($true) {
        Clear-Host
        Draw-MainUI
        Write-Host "`n"
        Draw-Center "--- SELECT DESTINATION USB ---" "Yellow"
        Write-Host "`n"

        # Filter: Removable Drives Only
        $USBs = Get-Volume | Where-Object { $_.DriveType -eq 'Removable' -and $_.DriveLetter -ne $null } | Sort-Object DriveLetter

        if ($USBs) {
            # Display Found USBs
            foreach ($u in $USBs) {
                $SizeGB = [math]::Round($u.SizeRemaining / 1GB, 2)
                $Label  = if ($u.FriendlyName) { $u.FriendlyName } else { "USB Drive" }
                
                # Styled Output
                $Line = "[$($u.DriveLetter)] $Label ($SizeGB GB Free)"
                Draw-Center $Line "Cyan"
            }
            
            Write-Host "`n"
            Write-Host $PadInput -NoNewline
            $TargetLetter = Read-Host "[ INPUT ] Enter Drive Letter (e.g. F)"

            # Validate Input
            if ($TargetLetter -match "^[a-zA-Z]$") {
                # Verify drive exists in the USB list (Prevent selecting C:)
                $Selected = $USBs | Where-Object { $_.DriveLetter -eq $TargetLetter.ToUpper() }
                
                if ($Selected) {
                    $TargetRoot = "$($Selected.DriveLetter):\"
                    break # Exit Loop and proceed to copy
                } else {
                    Draw-Center "Error: Please select a drive from the list." "Red"
                    Start-Sleep 2
                }
            }
        } else {
            # No USB Found - Prompt to Retry
            Draw-Center "NO USB DRIVE DETECTED!" "Red"
            Write-Host "`n"
            Draw-Center "Please insert a USB Flash Drive..." "Gray"
            Draw-Center "Press [ ENTER ] to Rescan" "White" "DarkRed"
            Read-Host
        }
    }

    # 3. Copy Execution
    if ($TargetRoot) {
        Write-Host "`n"
        Show-Spinner "Copying files to $TargetRoot..." 15 "Green"
        
        # Copy Config
        if (Test-Path "$WorkDir\Autounattend.xml") { 
            Copy-Item -Path "$WorkDir\Autounattend.xml" -Destination "$TargetRoot" -Force 
        }
        
        # Copy Support Folder
        if (Test-Path "$SupportDir") { 
            Copy-Item -Path "$SupportDir" -Destination "$TargetRoot" -Recurse -Force 
        }

        Write-Host "`n"
        Type-Writer ">>> SUCCESS! BUILD COMPLETE. <<<" "Green" 30
        Start-Sleep 2
        Remove-Item $WorkDir -Recurse -Force
    }
}