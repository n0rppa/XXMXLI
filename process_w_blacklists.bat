@echo off
REM XXMXLI IP Blacklist Processor - Windows Batch File
REM Simple IP blacklist processor using Windows built-in tools
REM Created by XXMXLI - https://xxmxli.com
REM 
REM SECURITY WARNING: This system is actively monitored and protected.
REM Any unauthorized access attempts, network scanning, intrusion, or abusive activity 
REM will be logged and reported to the appropriate authorities. IP addresses and metadata 
REM may be retained and used for legal enforcement, in compliance with applicable laws.
REM By continuing, you acknowledge that you are authorized to use this system and that 
REM any misuse may result in account suspension, firewall bans, or prosecution under 
REM national and international law. Violators may be subject to civil and/or criminal 
REM penalties. Your access is being monitored.

title XXMXLI IP Blacklist Processor
color 0A

echo.
echo ============================================
echo    XXMXLI IP Blacklist Processor
echo    Windows Batch Version
echo ============================================
echo.

REM Configuration
set "SOURCE_DIR=w"
set "OUTPUT_DIR=assets\security"
set "TEMP_FILE=%TEMP%\xxmxli_ips.tmp"
set "OUTPUT_JS=%OUTPUT_DIR%\blocked_ips.js"
set "OUTPUT_TXT=%OUTPUT_DIR%\blocked_ips.txt"
set "OUTPUT_BAT=%OUTPUT_DIR%\apply_ip_blocks.bat"

REM Check if source directory exists
if not exist "%SOURCE_DIR%" (
    echo [ERROR] Source directory '%SOURCE_DIR%' not found!
    echo Please create the directory and add your blacklist files.
    pause
    exit /b 1
)

REM Create output directory
if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%" 2>nul
    echo [INFO] Created output directory: %OUTPUT_DIR%
)

echo [INFO] Processing blacklist files from: %SOURCE_DIR%
echo.

REM Initialize counters
set /a "FILES_PROCESSED=0"
set /a "TOTAL_LINES=0"

REM Clear temporary file
if exist "%TEMP_FILE%" del "%TEMP_FILE%"

REM Process all text files in source directory
echo [INFO] Scanning for blacklist files...
for /r "%SOURCE_DIR%" %%f in (*.txt *.list *.ipset *.csv *.dat) do (
    if exist "%%f" (
        echo   Processing: %%~nxf
        set /a "FILES_PROCESSED+=1"
        
        REM Extract IP addresses from file (basic regex simulation)
        for /f "usebackq tokens=*" %%a in ("%%f") do (
            set "LINE=%%a"
            call :ProcessLine
        )
    )
)

REM Remove duplicates and sort
echo.
echo [INFO] Removing duplicates and sorting...
if exist "%TEMP_FILE%" (
    sort "%TEMP_FILE%" | findstr /v "^$" > "%TEMP_FILE%.sorted"
    type "%TEMP_FILE%.sorted" | findstr /v /c:"#" | findstr /r "^[0-9]" > "%TEMP_FILE%.clean"
)

REM Count unique IPs
set /a "UNIQUE_IPS=0"
if exist "%TEMP_FILE%.clean" (
    for /f %%a in ('type "%TEMP_FILE%.clean" ^| find /c /v ""') do set "UNIQUE_IPS=%%a"
)

echo.
echo ============================================
echo    Processing Results
echo ============================================
echo Files processed: %FILES_PROCESSED%
echo Unique IPs found: %UNIQUE_IPS%
echo.

REM Generate JavaScript file
echo [INFO] Generating JavaScript file...
echo // XXMXLI Blocked IPs - Generated %DATE% %TIME% > "%OUTPUT_JS%"
echo // Platform: Windows Batch Script >> "%OUTPUT_JS%"
echo // Total blocked IPs: %UNIQUE_IPS% >> "%OUTPUT_JS%"
echo. >> "%OUTPUT_JS%"
echo const blockedIPs = [ >> "%OUTPUT_JS%"

if exist "%TEMP_FILE%.clean" (
    for /f "tokens=*" %%a in ('%TEMP_FILE%.clean') do (
        echo     "%%a", >> "%OUTPUT_JS%"
    )
)

echo ]; >> "%OUTPUT_JS%"
echo. >> "%OUTPUT_JS%"
echo // Function to check if an IP is blocked >> "%OUTPUT_JS%"
echo function isIPBlocked(ip) { >> "%OUTPUT_JS%"
echo     return blockedIPs.includes(ip); >> "%OUTPUT_JS%"
echo } >> "%OUTPUT_JS%"
echo. >> "%OUTPUT_JS%"
echo // Function to get blocked IP count >> "%OUTPUT_JS%"
echo function getBlockedIPCount() { >> "%OUTPUT_JS%"
echo     return blockedIPs.length; >> "%OUTPUT_JS%"
echo } >> "%OUTPUT_JS%"

REM Generate plain text list
echo [INFO] Generating text file...
if exist "%TEMP_FILE%.clean" (
    copy "%TEMP_FILE%.clean" "%OUTPUT_TXT%" >nul
)

REM Generate Windows firewall batch script
echo [INFO] Generating firewall blocking script...
echo @echo off > "%OUTPUT_BAT%"
echo REM XXMXLI IP Blacklist - Windows Firewall Blocker >> "%OUTPUT_BAT%"
echo REM Generated: %DATE% %TIME% >> "%OUTPUT_BAT%"
echo REM Run as Administrator >> "%OUTPUT_BAT%"
echo. >> "%OUTPUT_BAT%"
echo title XXMXLI IP Blocker >> "%OUTPUT_BAT%"
echo color 0C >> "%OUTPUT_BAT%"
echo. >> "%OUTPUT_BAT%"
echo echo Applying XXMXLI IP blacklist to Windows Firewall... >> "%OUTPUT_BAT%"
echo echo. >> "%OUTPUT_BAT%"
echo. >> "%OUTPUT_BAT%"
echo REM Remove existing XXMXLI firewall rules >> "%OUTPUT_BAT%"
echo netsh advfirewall firewall delete rule name="XXMXLI-Block" 2^>nul >> "%OUTPUT_BAT%"
echo. >> "%OUTPUT_BAT%"
echo REM Add individual IP blocking rules >> "%OUTPUT_BAT%"

if exist "%TEMP_FILE%.clean" (
    set /a "RULE_COUNT=0"
    for /f "tokens=*" %%a in ('%TEMP_FILE%.clean') do (
        set /a "RULE_COUNT+=1"
        echo netsh advfirewall firewall add rule name="XXMXLI-Block-%%a" dir=in action=block remoteip=%%a >> "%OUTPUT_BAT%"
        echo netsh advfirewall firewall add rule name="XXMXLI-Block-Out-%%a" dir=out action=block remoteip=%%a >> "%OUTPUT_BAT%"
    )
)

echo. >> "%OUTPUT_BAT%"
echo echo. >> "%OUTPUT_BAT%"
echo echo Firewall rules applied successfully! >> "%OUTPUT_BAT%"
echo echo Total IPs blocked: %UNIQUE_IPS% >> "%OUTPUT_BAT%"
echo pause >> "%OUTPUT_BAT%"

REM Generate hosts file entries
echo [INFO] Generating hosts file entries...
set "OUTPUT_HOSTS=%OUTPUT_DIR%\hosts_entries.txt"
echo # XXMXLI IP Blacklist for Windows Hosts File > "%OUTPUT_HOSTS%"
echo # Generated: %DATE% %TIME% >> "%OUTPUT_HOSTS%"
echo # Total blocked IPs: %UNIQUE_IPS% >> "%OUTPUT_HOSTS%"
echo # >> "%OUTPUT_HOSTS%"
echo # To apply: Append these entries to C:\Windows\System32\drivers\etc\hosts >> "%OUTPUT_HOSTS%"
echo # (Run Notepad as Administrator to edit the hosts file) >> "%OUTPUT_HOSTS%"
echo. >> "%OUTPUT_HOSTS%"

if exist "%TEMP_FILE%.clean" (
    for /f "tokens=*" %%a in ('%TEMP_FILE%.clean') do (
        echo 127.0.0.1 %%a >> "%OUTPUT_HOSTS%"
    )
)

REM Clean up temporary files
if exist "%TEMP_FILE%" del "%TEMP_FILE%"
if exist "%TEMP_FILE%.sorted" del "%TEMP_FILE%.sorted"
if exist "%TEMP_FILE%.clean" del "%TEMP_FILE%.clean"

echo.
echo ============================================
echo    Generation Complete!
echo ============================================
echo.
echo Generated files:
echo   - %OUTPUT_JS% (JavaScript)
echo   - %OUTPUT_TXT% (Plain text list)
echo   - %OUTPUT_BAT% (Firewall rules)
echo   - %OUTPUT_HOSTS% (Hosts file entries)
echo.
echo [SECURITY WARNING]
echo The firewall script requires Administrator privileges.
echo Review all files before applying to your system.
echo.
echo Press any key to exit...
pause >nul
exit /b 0

REM Function to process individual lines
:ProcessLine
setlocal enabledelayedexpansion
set "LINE=!LINE!"

REM Skip comments and empty lines
if "!LINE:~0,1!"=="#" goto :eof
if "!LINE!"=="" goto :eof

REM Basic IP address extraction (simplified)
echo !LINE! | findstr /r "\<[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\>" >nul
if !errorlevel!==0 (
    REM Extract first IP-like pattern from line
    for /f "tokens=1-4 delims=. " %%a in ("!LINE!") do (
        set "PART1=%%a"
        set "PART2=%%b"
        set "PART3=%%c"
        set "PART4=%%d"
        
        REM Basic validation (check if all parts are numbers under 256)
        if !PART1! LEQ 255 if !PART2! LEQ 255 if !PART3! LEQ 255 if !PART4! LEQ 255 (
            if !PART1! GEQ 0 if !PART2! GEQ 0 if !PART3! GEQ 0 if !PART4! GEQ 0 (
                echo !PART1!.!PART2!.!PART3!.!PART4! >> "%TEMP_FILE%"
                set /a "TOTAL_LINES+=1"
            )
        )
    )
)
endlocal
goto :eof
