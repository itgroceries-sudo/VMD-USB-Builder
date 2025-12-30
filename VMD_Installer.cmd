@ECHO OFF
chcp 65001 >nul
SetLocal EnableDelayedExpansion

:: -----------------------------------------------------------------------------
:: 1. ADMIN CHECK & RELAUNCH (Simplified & Stable)
:: -----------------------------------------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
    PowerShell -Command "Start-Process -FilePath '%~dpnx0' -Verb RunAs"
    goto :eof
)

:: -----------------------------------------------------------------------------
:: 2. CORE SETUP & COLOR SETUP
:: -----------------------------------------------------------------------------
:START_SCRIPT
cd /D "%~dp0"
title VMD Driver Installer by IT Groceries Shop
mode con:cols=80 lines=32

:: -----------------------------------------------------------------------------
:: X. ANSI COLOR GENERATION (MUST BE IN ANSI OR UTF-8 WITHOUT BOM)
:: -----------------------------------------------------------------------------
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "Green=!ESC![32m"
set "White=!ESC![37m"
set "Cyan=!ESC![36m"
set "Magenta=!ESC![35m"
set "Red=!ESC![31m"
set "Yellow=!ESC![33m"
set "Reset=!ESC![0m"
set "Bold=!ESC![1m"

:: -----------------------------------------------------------------------------
:: 3. VERSION
:: -----------------------------------------------------------------------------
set "VER=V17.0.0"
set "DATE_VAL=2025-11-28"
set "CURRENT_VER=!VER! (!DATE_VAL!)"

goto :MAIN_MENU

:: -----------------------------------------------------------------------------
:: 5. MAIN MENU
:: -----------------------------------------------------------------------------
:MAIN_MENU
cls

:: -----------------------------------------------------------------------------
:: 4. REAL-TIME WINDOWS SEARCH
:: -----------------------------------------------------------------------------
set "WIN_FOUND=0"
set "TARGET_OS_DRIVE="
set "SOURCE_DRIVE=%~d0"

for %%d in (C D E F G H I J K L M N O P Q R S T U V W Y) do (
    if /i not "%%d:"=="X:" (
        if exist "%%d:\Windows\System32\Shutdown.exe" (
            set "WIN_FOUND=1"
            set "TARGET_OS_DRIVE=%%d:"
        )
    )
)

:: -----------------------------------------------------------------------------
:: 4.1 HARDWARE ID SCANNING
:: -----------------------------------------------------------------------------
CALL :SCAN_VMD_HARDWARE

:: -----------------------------------------------------------------------------
:: MENU DISPLAY
:: -----------------------------------------------------------------------------
echo.
echo !Bold!!White!================================================================================!Reset!
echo    !Magenta!!Bold!IRST Universal Driver Installer !CURRENT_VER! Stable!Reset!
echo                 !Cyan!VMD Driver Installer by IT Groceries Shop!Reset!
echo !Bold!!White!================================================================================!Reset!
echo.
Call :PREPARE_DISK_INFO
if defined TARGET_OS_DRIVE (
    echo   !Bold!!Yellow!Detected Storage:!Green! OS: !Red!!TARGET_OS_DRIVE!\Windows!Reset!
) else (
    echo   !Bold!!Yellow!Detected Storage:!Red! No Windows OS Found!Reset!
)
echo    !White!!DISK_LINE_1!!Reset!
echo    !White!!DISK_LINE_2!!Reset!
echo    !White!!DISK_LINE_3!!Reset!
echo.
if defined DETECTED_GEN (
    echo.        !White!^*^*^*^* !Green!HARDWARE DETECTED ^=^: !Magenta!^(!White!!Bold!!DETECTED_GEN!!Magenta!^) !White!^*^*^*^*!Reset!!Reset!
) ELSE (
    echo.        !White!^*^*^*^* !Green!HARDWARE DETECTED ^=^: !Magenta!^(!White!!Bold!Unknown / Non-VMD Controller!Magenta!^) !White!^*^*^*^*!Reset!
)
echo !White!--------------------------------------------------------------------------------!Reset!

:: Check and display boot mode
if Exist X:\Windows\ (
    Call :UEFICHECK_WINPE
) ELSE (
    Call :UEFICHECK_FULL_OS
)
echo !White!--------------------------------------------------------------------------------!Reset!
 
echo    !Bold![ 18 ]  !Yellow!For Intel 11th Gen      (Folder: VMD_v18)!Reset!
echo    !Bold![ 19 ]  !Yellow!For Intel 12th Gen      (Folder: VMD_v19)!Reset!
echo    !Bold![ 20 ]  !Yellow!For Intel 13th-14th Gen (Folder: VMD_v20)!Reset!

echo !White!--------------------------------------------------------------------------------!Reset!

echo    !Bold![ R  ]  !Cyan!Restart!Reset!
echo    !Bold![ S  ]  !Cyan!Shutdown!Reset!
echo    !Bold![ X  ]  !Green!Exit Script!Reset!

if "!WIN_FOUND!"=="1" echo    !Bold![ B  ]  !Red!Go to Firmware/BIOS !White!(GO2BIOS)!Reset!
if "!WIN_FOUND!"=="1" (
    if not defined ALREADY_ASKED (
        set "ALREADY_ASKED=1"
        ping 127.0.0.1 -n 5 >nul
        echo Set WshShell = CreateObject^("WScript.Shell"^) > "%TEMP%\AskExit.vbs"
        echo Res = MsgBox^("Windows Found^! (!TARGET_OS_DRIVE!\Windows) Install Complete." ^& vbCrLf ^& "Do you want to EXIT?", 36, "IT Groceries Shop"^) >> "%TEMP%\AskExit.vbs"
        echo WScript.Quit Res >> "%TEMP%\AskExit.vbs"
        cscript //nologo "%TEMP%\AskExit.vbs"
        set "USER_CHOICE=!ERRORLEVEL!"
        del "%TEMP%\AskExit.vbs" >nul
        if "!USER_CHOICE!"=="6" (
            cls
            echo. & echo    Exiting...
            ping 127.0.0.1 -n 2 >nul
            exit
        )
    )
)

echo.
echo !Bold!!White!================================================================================!Reset!

set "CHOICE="
if "!WIN_FOUND!"=="1" (
    set "WIN_STATUS=!Red!(!TARGET_OS_DRIVE!\Windows)!Reset!"
) else (
    set "WIN_STATUS=!Red!(Win_Not_Found)!Reset!"
)

echo !Bold!!Yellow!Enter choice (18, 19, 20, 21, R/S/B/X): !Reset!
set /p CHOICE=

:: Input Check
if "!CHOICE!"=="18" GOTO :LOAD_V18
if "!CHOICE!"=="19" GOTO :LOAD_V19
if "!CHOICE!"=="20" GOTO :LOAD_V20
if /i "!CHOICE!"=="R" GOTO :DO_REBOOT
if /i "!CHOICE!"=="S" GOTO :DO_SHUTDOWN
if /i "!CHOICE!"=="X" GOTO :DO_EXIT

if "!WIN_FOUND!"=="1" (
    if /i "!CHOICE!"=="B" GOTO :DO_FW_REBOOT
)

:: Input Validation Loop
echo.
echo !Red!Invalid input. Please enter 18, 19, 20, 21, R, S, X!Reset!
if "!WIN_FOUND!"=="1" echo !Red!or B (for BIOS/Firmware)!Reset!
echo.
echo Press any key to return to menu...
pause >nul
GOTO :MAIN_MENU

:: -----------------------------------------------------------------------------
:: 6. INSTALLATION HANDLERS
:: -----------------------------------------------------------------------------
:LOAD_V18
    call :InstallDriver "VMD_v18"
    GOTO :MAIN_MENU

:LOAD_V19
    call :InstallDriver "VMD_v19"
    GOTO :MAIN_MENU

:LOAD_V20
    call :InstallDriver "VMD_v20"
    GOTO :MAIN_MENU

:: -----------------------------------------------------------------------------
:: SUBROUTINE: InstallDriver
:: -----------------------------------------------------------------------------
:InstallDriver
set "TARGET_DIR=%~dp0%~1"

echo.
echo !White!--------------------------------------------------------------------------------!Reset!
echo Processing: %~1
echo !White!--------------------------------------------------------------------------------!Reset!

if not exist "!TARGET_DIR!\" (
    echo !Red![ERROR] Folder not found: "!TARGET_DIR!"!Reset!
    pause
    EXIT /B
)

pushd "!TARGET_DIR!"
if errorlevel 1 (
    echo !Red![ERROR] Cannot access directory.!Reset!
    pause
    EXIT /B
)

:: Install Driver
for /R %%f in (*.inf) do (
    echo Loading: %%~nf.inf ...
    drvload "%%f" >nul 2>&1
    if !errorlevel! equ 0 (
        echo    !Green![OK] Success!Reset!
    ) else (
        echo    !Red![FAIL] Error Code: !errorlevel!!Reset!
    )
)
popd

:: Check Disk 
echo.
echo !Yellow![CHECK] Listing Disks (wmic/PowerShell)!Reset!
if Exist X:\Windows\ (
    wmic diskdrive get deviceid,model,size
) ELSE (
    powershell -Command "$diskinfo = Get-PhysicalDisk | Select-Object DeviceId, Model, @{Name='Size (GB)'; Expression={[math]::Round($_.Size / 1GB)}} | Format-Table -AutoSize | Out-String -Width 78; $diskinfo.Trim().Split([System.Environment]::NewLine) | Where-Object { $_ -ne '' }"
)
echo.
echo Press any key to return to menu...
ping 127.0.0.1 -n 4 >nul
EXIT /B
 
:: -----------------------------------------------------------------------------
:: 7. POWER ACTIONS
:: -----------------------------------------------------------------------------
:DO_REBOOT
    if exist "!TARGET_OS_DRIVE!\Windows\System32\shutdown.exe" (
        CALL "!TARGET_OS_DRIVE!\Windows\System32\shutdown.exe" /r /t 0 >NUL 2>&1
    ) else (
        wpeutil reboot
    )
    GOTO :eof

:DO_SHUTDOWN
    if exist "!TARGET_OS_DRIVE!\Windows\System32\shutdown.exe" (
        CALL "!TARGET_OS_DRIVE!\Windows\System32\shutdown.exe" /s /t 0 >NUL 2>&1
    ) else (
        wpeutil Shutdown
    )
    GOTO :eof
	
:DO_FW_REBOOT
    if exist "!TARGET_OS_DRIVE!\Windows\System32\shutdown.exe" (
        CALL "!TARGET_OS_DRIVE!\Windows\System32\shutdown.exe" /r /fw /t 0 >NUL 2>&1
    ) else (
        wpeutil reboot
    )
    GOTO :eof

:DO_EXIT
    echo.
    echo !Green!Script Finished!Reset!
    ping 127.0.0.1 -n 4 >nul
    exit /b

:: -----------------------------------------------------------------------------
:: 8. BOOT MODE CHECK SUBROUTINES
:: -----------------------------------------------------------------------------

:UEFICHECK_WINPE
set "BOOT_MODE_FINAL=BIOS" 
set "UEFI=0"
wpeutil UpdateBootInfo >nul
for /f "tokens=2* delims=	 " %%A in ('reg query HKLM\System\CurrentControlSet\Control /v PEFirmwareType') DO set Firmware=%%B
if "%Firmware%"=="0x2" set "UEFI=1"
if "%UEFI%"=="1" (  
   set "BOOT_MODE_FINAL=UEFI"
   echo.        !White!^*^*^*^* !Green!PEFirmwareType ^=^: !Magenta!^(!White!UEFI!Magenta!-Booting Detected^) !White!^*^*^*^*
) ELSE (
   echo.        !White!^*^*^*^* !Green!PEFirmwareType ^=^: !Magenta!^(!White!BIOS!Magenta!-Legacy Detected^) !White!^*^*^*^*
)
goto :eof

:UEFICHECK_FULL_OS
set "BOOT_MODE_FINAL=BIOS" 

bcdedit /enum {current} | findstr /i /c:".efi" >nul
if not errorlevel 1 (
    set "BOOT_MODE_FINAL=UEFI"
)

echo.
if "!BOOT_MODE_FINAL!"=="UEFI" (
   echo.        !White!^*^*^*^* !Green!Boot Mode ^=^: !Magenta!^(!White!UEFI!Magenta!-BCD .efi Path Found^) !White!^*^*^*^*
) ELSE (
   echo.        !White!^*^*^*^* !Green!Boot Mode ^=^: !Magenta!^(!White!BIOS!Magenta!-BCD .exe Path Found^) !White!^*^*^*^*
)
goto :eof

:: -----------------------------------------------------------------------------
:: 9. HARDWARE ID SCANNING SUBROUTINE
:: -----------------------------------------------------------------------------
:SCAN_VMD_HARDWARE
    set "DETECTED_GEN="
    
    :: 11th Gen VMD (DEV_9A0B)
    reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI" /s /f "VEN_8086&DEV_9A0B" >nul 2>&1
    if !errorlevel! equ 0 set "DETECTED_GEN=Intel 11th Gen (Tiger Lake)"

    :: 12th Gen VMD (DEV_467F)
    if not defined DETECTED_GEN (
        reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI" /s /f "VEN_8086&DEV_467F" >nul 2>&1
        if !errorlevel! equ 0 set "DETECTED_GEN=Intel 12th Gen (Alder Lake)"
    )

    :: 13th/14th Gen VMD (DEV_A77F)
    if not defined DETECTED_GEN (
        reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI" /s /f "VEN_8086&DEV_A77F" >nul 2>&1
        if !errorlevel! equ 0 set "DETECTED_GEN=Intel 13th/14th Gen (Raptor Lake)"
    )
    
    goto :eof
	
:PREPARE_DISK_INFO
set "DISK_LINE_1=!Red!No Disk Found!Reset!"
set "DISK_LINE_2="
set "DISK_LINE_3="
set "DISK_COUNT=0"

if exist "X:\Windows\" ( 
    for /f "tokens=2,3,4 delims=," %%A in ('wmic diskdrive get Index^,Model^,Size /format:csv') do (
        if /i "%%A" neq "Index" if "%%A" neq "" (
            set /a DISK_COUNT+=1
            set "IDX=%%A"
            set "MODEL=%%B"
            set "RSIZE=%%C"
            
            for /f "delims=" %%D in ("!RSIZE!") do set "RSIZE=%%D"
            
            if defined RSIZE (
                if "!RSIZE:~9!"=="" ( set "SIZE_GB=0" ) else ( set "SIZE_GB=!RSIZE:~0,-9!" )
            ) else ( set "SIZE_GB=0" )
            
            set "LINE_CONTENT=!Bold!!Yellow![Disk !IDX!]!Reset!  !White!!MODEL!!Reset!  !Green!(!SIZE_GB! GB)!Reset!"
            
            if "!DISK_COUNT!"=="1" set "DISK_LINE_1=!LINE_CONTENT!"
            if "!DISK_COUNT!"=="2" set "DISK_LINE_2=!LINE_CONTENT!"
            if "!DISK_COUNT!"=="3" set "DISK_LINE_3=!LINE_CONTENT!"
        )
    )
) else (
    for /f "tokens=1,2,3 delims=|" %%A in ('powershell -NoProfile -Command "Get-CimInstance Win32_DiskDrive | Sort-Object Index | ForEach-Object { $_.Index.ToString() + '|' + $_.Model + '|' + [math]::Round($_.Size/1GB) }"') do (
        set /a DISK_COUNT+=1
        set "IDX=%%A"
        set "MODEL=%%B"
        set "SIZE_GB=%%C"
        set "LINE_CONTENT=!Bold!!Yellow![Disk !IDX!]!Reset!  !White!!MODEL!!Reset!  !Green!(!SIZE_GB! GB)!Reset!"
        if "!DISK_COUNT!"=="1" set "DISK_LINE_1=!LINE_CONTENT!"
        if "!DISK_COUNT!"=="2" set "DISK_LINE_2=!LINE_CONTENT!"
        if "!DISK_COUNT!"=="3" set "DISK_LINE_3=!LINE_CONTENT!"
    )
)

if !DISK_COUNT! GTR 3 (
    set /a REST_DISK=!DISK_COUNT!-2
    set "DISK_LINE_3=!Red!...and !REST_DISK! more disks found.!Reset!"
)

goto :EOF
)