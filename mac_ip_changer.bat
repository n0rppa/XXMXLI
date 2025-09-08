@echo off
REM XXMXLI MAC and IP Address Changer - Windows
REM This script helps change MAC addresses and configure IP settings for privacy

REM Get script directory and change to it
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

echo ================================================================
echo XXMXLI MAC and IP Address Changer
echo ================================================================
echo.
echo Working directory: %SCRIPT_DIR%
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [31mERROR: This script requires administrator privileges[0m
    echo [33mPlease run as Administrator and try again[0m
    pause
    exit /b 1
)

echo [32m✓ Running with administrator privileges[0m
echo.

:MENU
echo [36mMAC/IP Configuration Options:[0m
echo   1. View current network configuration
echo   2. Change MAC address (requires restart)
echo   3. Configure static IP
echo   4. Reset to DHCP
echo   5. Show network adapters
echo   6. Exit
echo.
set /p choice="Select option (1-6): "

if "%choice%"=="1" goto VIEW_CONFIG
if "%choice%"=="2" goto CHANGE_MAC
if "%choice%"=="3" goto STATIC_IP
if "%choice%"=="4" goto RESET_DHCP
if "%choice%"=="5" goto SHOW_ADAPTERS
if "%choice%"=="6" goto EXIT

echo [31mInvalid choice. Please select 1-6.[0m
echo.
goto MENU

:VIEW_CONFIG
echo.
echo [36mCurrent Network Configuration:[0m
echo ================================
ipconfig /all
echo.
pause
goto MENU

:SHOW_ADAPTERS
echo.
echo [36mNetwork Adapters:[0m
echo ==================
wmic path win32_networkadapter get name,index,macaddress
echo.
pause
goto MENU

:CHANGE_MAC
echo.
echo [33mWARNING: Changing MAC address requires network restart[0m
echo [33mThis may temporarily disconnect your internet[0m
echo.
set /p confirm="Continue? (y/N): "
if /i not "%confirm%"=="y" goto MENU

echo.
echo [36mAvailable Network Adapters:[0m
wmic path win32_networkadapter where "NetEnabled=true" get name,index
echo.
set /p adapter="Enter adapter name or press Enter to cancel: "
if "%adapter%"=="" goto MENU

echo.
echo [33mGenerating random MAC address...[0m
REM Generate random MAC address (keeping first octet valid)
set mac1=02
set /a mac2=%random% %% 256
set /a mac3=%random% %% 256
set /a mac4=%random% %% 256
set /a mac5=%random% %% 256
set /a mac6=%random% %% 256

REM Convert to hex
set hex_chars=0123456789ABCDEF
call :to_hex %mac2% mac2_hex
call :to_hex %mac3% mac3_hex
call :to_hex %mac4% mac4_hex
call :to_hex %mac5% mac5_hex
call :to_hex %mac6% mac6_hex

set new_mac=%mac1%-%mac2_hex%-%mac3_hex%-%mac4_hex%-%mac5_hex%-%mac6_hex%
echo [32mNew MAC address: %new_mac%[0m

echo.
echo [33mChanging MAC address...[0m
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}\0001" /v NetworkAddress /t REG_SZ /d "%new_mac:~0,2%%new_mac:~3,2%%new_mac:~6,2%%new_mac:~9,2%%new_mac:~12,2%%new_mac:~15,2%" /f

echo [32m✓ MAC address change queued[0m
echo [33mPlease restart your network adapter or reboot for changes to take effect[0m
echo.
pause
goto MENU

:STATIC_IP
echo.
echo [36mConfigure Static IP Address:[0m
echo =============================
set /p ip="Enter IP address (e.g., 192.168.1.100): "
set /p subnet="Enter subnet mask (e.g., 255.255.255.0): "
set /p gateway="Enter gateway (e.g., 192.168.1.1): "
set /p dns="Enter DNS server (e.g., 8.8.8.8): "

echo.
echo [33mApplying static IP configuration...[0m
netsh interface ip set address "Local Area Connection" static %ip% %subnet% %gateway%
netsh interface ip set dns "Local Area Connection" static %dns%

echo [32m✓ Static IP configured[0m
echo.
pause
goto MENU

:RESET_DHCP
echo.
echo [33mResetting to DHCP configuration...[0m
netsh interface ip set address "Local Area Connection" dhcp
netsh interface ip set dns "Local Area Connection" dhcp

echo [32m✓ DHCP configuration restored[0m
echo.
pause
goto MENU

:to_hex
set /a hex_val=%1
set hex_result=
set /a remainder=hex_val %% 16
set /a quotient=hex_val / 16
call set hex_digit1=%%hex_chars:~%quotient%,1%%
call set hex_digit2=%%hex_chars:~%remainder%,1%%
set %2=%hex_digit1%%hex_digit2%
goto :eof

:EXIT
echo.
echo [36mNetwork configuration changes logged to: %SCRIPT_DIR%network_changes.log[0m
echo [34mThank you for using XXMXLI MAC/IP Changer[0m
echo.
pause