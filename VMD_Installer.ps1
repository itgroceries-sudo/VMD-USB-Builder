# ============================================================
#  VMD USB Creator (Self-Hosted Edition) - IT Groceries Shop
# ============================================================
Clear-Host
Write-Host " IT Groceries Shop - VMD USB Creator" -ForegroundColor Yellow
Write-Host " ===================================" -ForegroundColor White
Write-Host ""

# 1. ตั้งค่า GitLab ของคุณ (แก้ตรงนี้ทีเดียวจบ)
$GitLabRaw = "https://gitlab.com/itgroceries/itg_vmd_builder/-/raw/main"
$WorkDir = "$env:TEMP\ITG_VMD_Builder"
$SupportDir = "$WorkDir\Support"

# 2. เตรียมพื้นที่
if (Test-Path $WorkDir) { Remove-Item $WorkDir -Recurse -Force }
New-Item -ItemType Directory -Path $SupportDir | Out-Null
Write-Host "[+] Working Directory Created." -ForegroundColor Green

# 3. ฟังก์ชันดาวน์โหลดและแตกไฟล์
function Get-And-Extract {
    param ($FileName, $DestName)
    $Url = "$GitLabRaw/$FileName"
    $ExePath = "$WorkDir\$FileName"
    $ExtractPath = "$WorkDir\Extracted_$DestName"

    # 3.1 ดาวน์โหลดจาก GitLab (ใช้ BITS เพื่อความไว)
    try {
        Write-Host "    - Downloading $FileName..." -NoNewline -ForegroundColor Gray
        Start-BitsTransfer -Source $Url -Destination $ExePath -ErrorAction Stop
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [FAILED]" -ForegroundColor Red
        Write-Host "    [Error] Check filename/URL in GitLab." -ForegroundColor Red
        return
    }

    # 3.2 แตกไฟล์ (Extract)
    Write-Host "    - Extracting..." -ForegroundColor Gray
    Start-Process -FilePath $ExePath -ArgumentList "-extract `"$ExtractPath`"" -Wait

    # 3.3 ค้นหาและย้าย Driver
    $InfFile = Get-ChildItem -Path $ExtractPath -Recurse -Filter "iaStorVD.inf" | Select-Object -First 1
    if ($InfFile) {
        Move-Item -Path $InfFile.Directory.FullName -Destination "$SupportDir\$DestName"
        Write-Host "    - Saved to Support\$DestName" -ForegroundColor Green
    } else {
        Write-Host "    [Error] Driver extraction failed." -ForegroundColor Red
    }
}

# 4. เริ่มทำงาน (โหลด Config)
Write-Host "[1/2] Fetching Config Files..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "$GitLabRaw/Autounattend.xml" -OutFile "$WorkDir\Autounattend.xml"
Invoke-WebRequest -Uri "$GitLabRaw/VMD_Installer.cmd" -OutFile "$SupportDir\VMD_Installer.cmd"

# 5. เริ่มทำงาน (โหลด Drivers)
Write-Host "[2/2] Processing Drivers..." -ForegroundColor Cyan
Get-And-Extract -FileName "VMD_v18.exe" -DestName "VMD_v18"
Get-And-Extract -FileName "VMD_v19.exe" -DestName "VMD_v19"
Get-And-Extract -FileName "VMD_v20.exe" -DestName "VMD_v20"

# 6. copy ลง USB
Write-Host ""
Write-Host "[ SELECT TARGET USB ]" -ForegroundColor Magenta
$USBList = Get-Volume | Where-Object { $_.DriveType -eq 'Removable' }

if ($USBList) {
    $USBList | Format-Table DriveLetter, FriendlyName, SizeRemaining -AutoSize
    $DriveLetter = Read-Host "Enter Drive Letter (e.g. F)"
    $Target = "$($DriveLetter):\"

    if (Test-Path $Target) {
        Write-Host "[+] Copying to USB ($Target)..." -ForegroundColor Yellow
        Copy-Item -Path "$WorkDir\*" -Destination $Target -Recurse -Force
        
        Write-Host "SUCCESS! USB Ready." -ForegroundColor Green
        # ลบไฟล์ Temp ทิ้ง
        Remove-Item $WorkDir -Recurse -Force
    }
}
Pause