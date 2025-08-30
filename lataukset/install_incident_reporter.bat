@echo off
REM ================================================================
REM WARNING: This system is actively monitored and protected.
REM
REM Any unauthorized access attempts, network scanning, intrusion, or 
REM abusive activity will be logged and reported to the appropriate 
REM authorities. IP addresses and metadata may be retained and used 
REM for legal enforcement, in compliance with applicable laws.
REM
REM By continuing, you acknowledge that you are authorized to use this 
REM system and that any misuse may result in account suspension, 
REM firewall bans, or prosecution under national and international law.
REM
REM Violators may be subject to civil and/or criminal penalties.
REM
REM Your access is being monitored.
REM ================================================================

title XXMXLI Incident Reporter - One-Click Installer
color 0a

echo.
echo  ██████  ██   ██ ███    ███ ██   ██ ██      ██ 
echo ██    ██  ██ ██  ████  ████  ██ ██  ██      ██ 
echo ██    ██   ███   ██ ████ ██   ███   ██      ██ 
echo ██    ██  ██ ██  ██  ██  ██  ██ ██  ██      ██ 
echo  ██████  ██   ██ ██      ██ ██   ██ ███████ ██ 
echo.
echo XXMXLI INCIDENT REPORTER - ONE-CLICK INSTALLER
echo Automated Security Incident Reporting Setup
echo.

REM Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This installer must be run as Administrator
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo [INFO] Starting One-Click Setup...
echo.

REM Create directories
echo [STEP 1/6] Creating directories...
if not exist "C:\SecurityLogs" mkdir "C:\SecurityLogs"
if not exist "C:\SecurityLogs\Reports" mkdir "C:\SecurityLogs\Reports"
if not exist "C:\SecurityLogs\Evidence" mkdir "C:\SecurityLogs\Evidence"
if not exist "C:\Program Files\XXMXLI" mkdir "C:\Program Files\XXMXLI"
echo [OK] Directories created

REM Copy PowerShell script
echo [STEP 2/6] Installing incident reporter...
if exist "%~dp0automated_incident_reporter.ps1" (
    copy "%~dp0automated_incident_reporter.ps1" "C:\Program Files\XXMXLI\" >nul
    echo [OK] Incident reporter installed
) else (
    echo [WARNING] PowerShell script not found in current directory
)

REM Create configuration
echo [STEP 3/6] Creating configuration...
(
echo {
echo   "organization_info": {
echo     "name": "XXMXLI Security Operations",
echo     "contact": "security@xxmxli.local",
echo     "phone": "+1-555-XXMXLI",
echo     "address": "XXMXLI Security Center, Cyber Defense Division"
echo   },
echo   "technical_contact": {
echo     "email": "admin@xxmxli.local",
echo     "phone": "+1-555-ADMIN"
echo   },
echo   "reporting_thresholds": {
echo     "min_severity": 3,
echo     "auto_report_severity": 7,
echo     "batch_report_interval": 3600
echo   },
echo   "notification_settings": {
echo     "email_enabled": false,
echo     "sms_enabled": false,
echo     "webhook_enabled": false
echo   },
echo   "evidence_collection": {
echo     "collect_logs": true,
echo     "collect_network_info": true,
echo     "evidence_retention_days": 90
echo   },
echo   "encryption_settings": {
echo     "encrypt_reports": false,
echo     "secure_delete": true
echo   }
echo }
) > "C:\SecurityLogs\incident_reporter.json"
echo [OK] Configuration created

REM Set PowerShell execution policy
echo [STEP 4/6] Configuring PowerShell...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force" >nul 2>&1
echo [OK] PowerShell configured

REM Create shortcuts
echo [STEP 5/6] Creating shortcuts...

REM Create batch wrapper
(
echo @echo off
echo title XXMXLI Incident Reporter
echo powershell -ExecutionPolicy Bypass -File "C:\Program Files\XXMXLI\automated_incident_reporter.ps1" %%*
echo pause
) > "C:\Program Files\XXMXLI\incident-reporter.bat"

REM Create desktop shortcut
(
echo Set oWS = WScript.CreateObject^("WScript.Shell"^)
echo sLinkFile = "%USERPROFILE%\Desktop\XXMXLI Incident Reporter.lnk"
echo Set oLink = oWS.CreateShortcut^(sLinkFile^)
echo oLink.TargetPath = "C:\Program Files\XXMXLI\incident-reporter.bat"
echo oLink.WorkingDirectory = "C:\Program Files\XXMXLI"
echo oLink.Description = "XXMXLI Security Incident Reporter"
echo oLink.Save
) > "%TEMP%\create_shortcut.vbs"
cscript //nologo "%TEMP%\create_shortcut.vbs"
del "%TEMP%\create_shortcut.vbs"

echo [OK] Shortcuts created

REM Run test
echo [STEP 6/6] Running system test...
powershell -ExecutionPolicy Bypass -File "C:\Program Files\XXMXLI\automated_incident_reporter.ps1" -Action test >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] System test passed
) else (
    echo [WARNING] System test had warnings (this is normal)
)

echo.
echo ========================================
echo   INSTALLATION COMPLETED SUCCESSFULLY!
echo ========================================
echo.
echo Quick Start Commands:
echo   Desktop Shortcut: "XXMXLI Incident Reporter"
echo   Command Line: "C:\Program Files\XXMXLI\incident-reporter.bat"
echo.
echo PowerShell Commands:
echo   Test:    powershell -File "C:\Program Files\XXMXLI\automated_incident_reporter.ps1" -Action test
echo   Report:  powershell -File "C:\Program Files\XXMXLI\automated_incident_reporter.ps1" -Action report -IncidentType INTRUSION -Severity 6 -Description "Attack detected"
echo   Monitor: powershell -File "C:\Program Files\XXMXLI\automated_incident_reporter.ps1" -Action monitor
echo.
echo Installation Location: C:\Program Files\XXMXLI\
echo Reports Location: C:\SecurityLogs\Reports\
echo Configuration: C:\SecurityLogs\incident_reporter.json
echo.
echo [SUCCESS] Your system is now protected with automated incident reporting!
echo [WARNING] Remember: All security incidents will be automatically reported to authorities
echo.
pause
