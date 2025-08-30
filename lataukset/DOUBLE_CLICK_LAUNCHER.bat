@echo off
REM ================================================================
REM XXMXLI INCIDENT REPORTER - DOUBLE-CLICK LAUNCHER (WINDOWS)
REM ================================================================
REM This batch file makes it super easy to run the incident reporter
REM Just double-click this file in Windows Explorer!
REM ================================================================

title XXMXLI Incident Reporter - Double-Click Launcher
color 0A

echo.
echo 🚀 XXMXLI Incident Reporter - Double-Click Launcher
echo ==================================================
echo.

REM Check if running as Administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo ✅ Running with Administrator privileges
    echo.
    goto :run_reporter
) else (
    echo ⚠️  Administrator privileges required
    echo Attempting to elevate...
    echo.
    
    REM Try to elevate to Administrator
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    if %errorLevel% == 0 (
        echo Elevation successful. Check the new window.
        pause
        exit /b
    ) else (
        echo Failed to elevate. You may need to run this manually as Administrator.
        echo.
        goto :run_anyway
    )
)

:run_reporter
echo Starting XXMXLI Incident Reporter...
echo.

REM Try to run the PowerShell script
if exist "automated_incident_reporter.ps1" (
    powershell -ExecutionPolicy Bypass -File "automated_incident_reporter.ps1"
) else (
    echo Error: automated_incident_reporter.ps1 not found in current directory
    echo Please ensure all files are in the same folder.
    echo.
    pause
    exit /b 1
)

echo.
echo Reporter finished.
pause
exit /b

:run_anyway
echo.
echo You can still try to run the reporter, but some features may not work
echo without Administrator privileges.
echo.
set /p choice="Continue anyway? (y/N): "
if /i "%choice%"=="y" (
    goto :run_reporter
) else (
    echo Operation cancelled.
    pause
    exit /b
)
