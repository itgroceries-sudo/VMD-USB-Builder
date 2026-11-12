<# : hybrid batch + powershell script
@powershell -noprofile -Window Hidden -c "$param='\%*';$ScriptPath='%~f0';iex((Get-Content('%~f0') -Raw))"&exit/b
#>

# =========================================================
#  VMD USB Builder by IT Groceries Shop
#  Version: 2.1 (Build 17.0 Smart-Copy + VMD v21)
# =========================================================

$ErrorActionPreference = 'SilentlyContinue';
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;

# --- [VERSION CONTROL] ---
$AppVer   = "2.1";
$AppBuild = "17.0 Smart";
$AppDate  = "12-11-2026";

# [DATE CONFIG] Get Current Date
$DateStr = Get-Date -Format "dd-MM-yyyy";

$WindowTitle  = "IT GROCERIES GUI [Date: $DateStr]";
$ConsoleTitle = "IT GROCERIES CONSOLE [Date: $DateStr]";

# --- [SELF-DOWNLOAD & ADMIN CHECK] ---
$CurrentScript =$PSCommandPath;
if (-not $CurrentScript) {
    # Web-Launch Mode
    $WebSource = "https://raw.githubusercontent.com/itgroceries-sudo/VMD-USB-Builder/main/USB_Builder.ps1";
    $TempScript = "$env:TEMP\USB_Builder.ps1";
    Write-Host "Downloading script..." -ForegroundColor Cyan;
    try { Invoke-WebRequest -Uri $WebSource -OutFile$TempScript -UserAgent "Mozilla/5.0" -UseBasicParsing -ErrorAction Stop; } 
    catch { Write-Host "Download Error." -ForegroundColor Red; Start-Sleep 3; exit; }
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$TempScript`"" -Verb RunAs;
    exit;
}

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$CurrentScript`"" -Verb RunAs;
    exit;
}

# --- [WIN32 API] ---
$Win32Def = '
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern IntPtr LoadImage(IntPtr hinst, string lpszName, uint uType, int cxDesired, int cyDesired, uint fuLoad);
    [DllImport("user32.dll")] public static extern IntPtr GetSystemMenu(IntPtr hWnd, bool bRevert);
    [DllImport("user32.dll")] public static extern bool DeleteMenu(IntPtr hMenu, uint uPosition, uint uFlags);
';
$Win32 = Add-Type -MemberDefinition$Win32Def -Name "Win32Utils" -Namespace Win32 -PassThru;

# --- [CONFIG] ---
$GitHubRaw   = "https://raw.githubusercontent.com/itgroceries-sudo/VMD-USB-Builder/main";
$WorkDir     = "$env:TEMP\ITG_VMD_Build";
$SupportDir  = "$WorkDir\Support";
$script:Running =$true;

# [ICONS]
$IconGoogle  = "$env:TEMP\Google.ico";
$IconITG     = "$env:TEMP\ITG.ico";
$UrlGoogle   = "https://www.google.com/favicon.ico";
$UrlITG      = "https://itgroceries.blogspot.com/favicon.ico";

# [INTEL DRIVERS - VMD v18 ถึง v21]
$URL_V18 = "https://downloadmirror.intel.com/773229/SetupRST.exe";
$URL_V19 = "https://downloadmirror.intel.com/849934/SetupRST.exe";
$URL_V20 = "https://downloadmirror.intel.com/865363/SetupRST.exe";
$URL_V21 = "https://downloadmirror.intel.com/920457/SetupRST.exe";

# --- [SETUP] ---
Add-Type -AssemblyName System.Windows.Forms;
Add-Type -AssemblyName System.Drawing;

try {
    Invoke-WebRequest -Uri $UrlGoogle -OutFile$IconGoogle -UserAgent "Mozilla/5.0" -UseBasicParsing;
    Invoke-WebRequest -Uri $UrlITG -OutFile$IconITG -UserAgent "Mozilla/5.0" -UseBasicParsing;
} catch {}

# Console Setup
$ConsoleHandle =$Win32::GetConsoleWindow();
$Host.UI.RawUI.WindowTitle = "$ConsoleTitle";

$ScreenWidth  = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width;
$ScreenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height;
$WinWidth     = 650;
$WinHeight    = 760;
$LeftX        = ($ScreenWidth / 2) -$WinWidth;
$RightX       = ($ScreenWidth / 2);$CenterY      = ($ScreenHeight / 2) - ($WinHeight / 2);

if (Test-Path $IconGoogle) {$hIcon = $Win32::LoadImage([IntPtr]::Zero,$IconGoogle, 1, 0, 0, 0x10);
    if ($hIcon -ne [IntPtr]::Zero) { 
        [void]$Win32::SendMessage($ConsoleHandle, 0x80, [IntPtr]0,$hIcon); 
        [void]$Win32::SendMessage($ConsoleHandle, 0x80, [IntPtr]1,$hIcon); 
    }
}

[void]$Win32::SetWindowPos($ConsoleHandle, [IntPtr]::Zero, $LeftX,$CenterY, $WinWidth,$WinHeight, 0x0040);

$hMenu =$Win32::GetSystemMenu($ConsoleHandle,$false);
if ($hMenu -ne [IntPtr]::Zero) {
    [void]$Win32::DeleteMenu($hMenu, 0xF010, 0x0000);
    [void]$Win32::DeleteMenu($hMenu, 0xF060, 0x0000);
    [void]$Win32::DeleteMenu($hMenu, 0xF030, 0x0000);
    [void]$Win32::DeleteMenu($hMenu, 0xF000, 0x0000);
}

Clear-Host;
$Host.UI.RawUI.BackgroundColor = "Black"; 
$Host.UI.RawUI.ForegroundColor = "Green"; 
Clear-Host;
Write-Host "`n`n`n      ==================================================" -ForegroundColor Cyan;
Write-Host "             $ConsoleTitle             " -ForegroundColor White;
Write-Host "      ==================================================" -ForegroundColor Cyan;
Write-Host "`n      [ SYSTEM STATUS ]" -ForegroundColor Yellow;
Write-Host "      > Initializing...";
Write-Host "      > Waiting for user input..." -ForegroundColor Gray;

# WinForm Setup
$form = New-Object Windows.Forms.Form;
$form.Text = "$WindowTitle";
$form.Size = New-Object Drawing.Size($WinWidth, $WinHeight);$form.BackColor = [Drawing.Color]::Black;
$form.Padding = New-Object Windows.Forms.Padding(3);$form.FormBorderStyle = [Windows.Forms.FormBorderStyle]::None;
$form.StartPosition = [Windows.Forms.FormStartPosition]::Manual;
$form.Location = New-Object Drawing.Point($RightX,$CenterY);
$form.KeyPreview =$true;

$form.Add_Paint({
    param($sender, $e);$borderColor = [Drawing.Color]::Cyan;
    $borderWidth = 2;
    $pen = New-Object Drawing.Pen($borderColor, $borderWidth);$pen.Alignment = [Drawing.Drawing2D.PenAlignment]::Inset;
    $rect =$form.ClientRectangle;
    $e.Graphics.DrawRectangle($pen,$rect);
});

if (Test-Path $IconITG) { $form.Icon = New-Object Drawing.Icon($IconITG); }

$global:TargetUSB =$null;
$rnd = New-Object System.Random;

# --- [UI HEADER] ---
$lblHeader = New-Object Windows.Forms.Label;
$lblHeader.Text = "--- VMD USB BUILDER v$AppVer Build$AppBuild ---";
$lblHeader.ForeColor = [Drawing.Color]::Cyan;
$lblHeader.Font = New-Object Drawing.Font("Consolas", 12, [Drawing.FontStyle]::Bold);
$lblHeader.TextAlign = [Drawing.ContentAlignment]::MiddleCenter;
$lblHeader.Dock = [Windows.Forms.DockStyle]::Top;
$lblHeader.Height = 40;
$lblHeader.Add_MouseDown({ $form.Capture =$false; });
$form.Controls.Add($lblHeader);

$cmbUSB = New-Object Windows.Forms.ComboBox;
$cmbUSB.Width = 450; 
$cmbUSB.Height = 40; 
$cmbUSB.Location = New-Object Drawing.Point(90, 50);$cmbUSB.Font = New-Object Drawing.Font("Consolas", 12, [Drawing.FontStyle]::Bold);
$cmbUSB.BackColor = [Drawing.Color]::DimGray; 
$cmbUSB.ForeColor = [Drawing.Color]::White;
$cmbUSB.DropDownStyle = [Windows.Forms.ComboBoxStyle]::DropDownList;
$form.Controls.Add($cmbUSB);

# [FIX] Checkbox
$cbShowAll = New-Object Windows.Forms.CheckBox;
$cbShowAll.Text = "Show All Drives";
$cbShowAll.Font = New-Object Drawing.Font("Consolas", 9);
$cbShowAll.ForeColor = [Drawing.Color]::Gray;
$cbShowAll.Location = New-Object Drawing.Point(90, 92);$cbShowAll.Size = New-Object Drawing.Size(200, 20);
$form.Controls.Add($cbShowAll);

$script:cbShowAll =$cbShowAll;

# Copy to Drive
$btnCopy = New-Object Windows.Forms.Button;
$btnCopy.Text = "Copy to Drive >";
$btnCopy.Font = New-Object Drawing.Font("Consolas", 9, [Drawing.FontStyle]::Bold);
$btnCopy.ForeColor = [Drawing.Color]::White; $
