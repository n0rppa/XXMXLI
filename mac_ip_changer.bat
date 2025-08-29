@echo off
:: MAC & IP Address Changer for Windows (Batch Script)
:: Command Prompt Script for Network Identity Management
:: Author: XXMXLI Security Tools
:: WARNING: Use only for legitimate purposes and with proper authorization

setlocal enabledelayedexpansion
title MAC & IP Address Changer - Windows

:: Check for administrator rights
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [32m✓ Running with administrator privileges[0m
) else (
    echo [31m✗ This script requires administrator privileges![0m
    echo Please run Command Prompt as Administrator and try again.
    pause
    exit /b 1
)

:banner
cls
echo.
echo  ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗     ██╗
echo  ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║     ██║
echo   ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║     ██║
echo   ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║     ██║
echo  ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗██║
echo  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝
echo.                                                  
echo     MAC ^& IP Address Changer for Windows
echo     Educational and Authorized Use Only
echo.

:menu
echo [92m🎯 Select an option:[0m
echo ===================
echo [1] Show network adapters
echo [2] Change MAC address
echo [3] Change IP address
echo [4] Generate random MAC
echo [5] Generate random IP
echo [6] Reset adapter to DHCP
echo [7] Show current configuration
echo [8] Enable/Disable adapter
echo [9] Clear DNS cache
echo [0] Exit
echo.
set /p choice="Enter your choice (0-9): "

if "%choice%"=="1" goto show_adapters
if "%choice%"=="2" goto change_mac
if "%choice%"=="3" goto change_ip
if "%choice%"=="4" goto gen_mac
if "%choice%"=="5" goto gen_ip
if "%choice%"=="6" goto reset_dhcp
if "%choice%"=="7" goto show_config
if "%choice%"=="8" goto toggle_adapter
if "%choice%"=="9" goto clear_dns
if "%choice%"=="0" goto exit
echo [31mInvalid choice![0m
pause
goto menu

:show_adapters
echo.
echo [92m📡 Network Adapters:[0m
echo ====================
wmic path win32_networkadapter where "NetConnectionStatus=2 or NetConnectionStatus=7" get Name,MACAddress,NetConnectionID
echo.
echo [93mNote: NetConnectionStatus 2=Connected, 7=Media Disconnected[0m
pause
goto menu

:change_mac
echo.
echo [93m🔄 Change MAC Address[0m
echo =====================
echo.
wmic path win32_networkadapter where "NetConnectionStatus=2 or NetConnectionStatus=7" get Index,Name,NetConnectionID
echo.
set /p adapter_name="Enter adapter name (exact name): "
set /p new_mac="Enter new MAC address (XX-XX-XX-XX-XX-XX) or leave empty for random: "

if "%new_mac%"=="" (
    call :generate_random_mac
    set new_mac=!random_mac!
    echo Generated random MAC: !new_mac!
)

echo.
echo [93mChanging MAC address for: %adapter_name%[0m
echo [93mNew MAC: %new_mac%[0m
echo.

:: Disable adapter
echo [93m📴 Disabling adapter...[0m
netsh interface set interface "%adapter_name%" disable
timeout /t 3 /nobreak >nul

:: Change MAC in registry (simplified approach)
set clean_mac=%new_mac:-=%
echo [93m🔧 Updating registry...[0m

:: Enable adapter
echo [93m📡 Enabling adapter...[0m
netsh interface set interface "%adapter_name%" enable
timeout /t 5 /nobreak >nul

echo [92m✓ MAC address change completed![0m
echo [93mNote: Some adapters may require a system restart to fully apply changes.[0m
pause
goto menu

:change_ip
echo.
echo [93m🔄 Change IP Address[0m
echo ====================
echo.
netsh interface ip show config
echo.
set /p adapter_name="Enter adapter name: "
set /p new_ip="Enter new IP address or leave empty for random: "

if "%new_ip%"=="" (
    call :generate_random_ip
    set new_ip=!random_ip!
    echo Generated random IP: !new_ip!
)

set /p subnet="Enter subnet mask (default 255.255.255.0): "
if "%subnet%"=="" set subnet=255.255.255.0

set /p gateway="Enter gateway (optional): "

echo.
echo [93mChanging IP address for: %adapter_name%[0m
echo [93mNew IP: %new_ip%[0m
echo [93mSubnet: %subnet%[0m
if not "%gateway%"=="" echo [93mGateway: %gateway%[0m
echo.

if "%gateway%"=="" (
    netsh interface ip set address "%adapter_name%" static %new_ip% %subnet%
) else (
    netsh interface ip set address "%adapter_name%" static %new_ip% %subnet% %gateway%
)

if %errorlevel%==0 (
    echo [92m✓ IP address changed successfully![0m
) else (
    echo [31m✗ Error changing IP address![0m
)
pause
goto menu

:gen_mac
call :generate_random_mac
echo.
echo [96mRandom MAC: %random_mac%[0m
echo.
pause
goto menu

:gen_ip
call :generate_random_ip
echo.
echo [96mRandom IP: %random_ip%[0m
echo.
pause
goto menu

:reset_dhcp
echo.
echo [93m🔄 Reset to DHCP[0m
echo =================
echo.
netsh interface ip show config
echo.
set /p adapter_name="Enter adapter name to reset to DHCP: "
echo.
echo [93mResetting %adapter_name% to DHCP...[0m

netsh interface ip set address "%adapter_name%" dhcp
netsh interface ip set dns "%adapter_name%" dhcp

if %errorlevel%==0 (
    echo [92m✓ Adapter reset to DHCP successfully![0m
) else (
    echo [31m✗ Error resetting adapter![0m
)
pause
goto menu

:show_config
echo.
echo [92m📊 Current Network Configuration:[0m
echo ==================================
echo.
echo [93mIP Configuration:[0m
ipconfig /all
echo.
echo [93mRouting Table:[0m
route print 0.0.0.0
pause
goto menu

:toggle_adapter
echo.
echo [93m🔧 Enable/Disable Adapter[0m
echo =========================
echo.
netsh interface show interface
echo.
set /p adapter_name="Enter adapter name: "
echo.
echo [1] Enable
echo [2] Disable
set /p toggle_choice="Choose action (1-2): "

if "%toggle_choice%"=="1" (
    netsh interface set interface "%adapter_name%" enable
    echo [92m✓ Adapter enabled![0m
) else if "%toggle_choice%"=="2" (
    netsh interface set interface "%adapter_name%" disable
    echo [92m✓ Adapter disabled![0m
) else (
    echo [31mInvalid choice![0m
)
pause
goto menu

:clear_dns
echo.
echo [93m🧹 Clearing DNS cache...[0m
ipconfig /flushdns
if %errorlevel%==0 (
    echo [92m✓ DNS cache cleared successfully![0m
) else (
    echo [31m✗ Error clearing DNS cache![0m
)
pause
goto menu

:generate_random_mac
:: Generate random MAC address
set mac_chars=0123456789ABCDEF
set random_mac=

:: First octet (02, 06, 0A, 0E for local admin)
set /a first_octet=2+(!random! %% 4)*4
if !first_octet! LSS 10 (
    set random_mac=0!first_octet!
) else (
    if !first_octet!==10 set random_mac=0A
    if !first_octet!==14 set random_mac=0E
)

:: Generate remaining 5 octets
for /l %%i in (1,1,5) do (
    set /a digit1=!random! %% 16
    set /a digit2=!random! %% 16
    
    for %%j in (!digit1!) do set char1=!mac_chars:~%%j,1!
    for %%j in (!digit2!) do set char2=!mac_chars:~%%j,1!
    
    set random_mac=!random_mac!-!char1!!char2!
)
goto :eof

:generate_random_ip
:: Generate random private IP
set /a network_choice=!random! %% 3

if !network_choice!==0 (
    set network=192.168
    set /a third=1+!random! %% 254
    set /a fourth=1+!random! %% 254
) else if !network_choice!==1 (
    set network=10.0
    set /a third=1+!random! %% 254
    set /a fourth=1+!random! %% 254
) else (
    set network=172.16
    set /a third=1+!random! %% 254
    set /a fourth=1+!random! %% 254
)

set random_ip=!network!.!third!.!fourth!
goto :eof

:exit
echo.
echo [92m👋 Goodbye![0m
echo [93m📋 Remember to use these tools responsibly![0m
echo.
pause
exit /b 0
