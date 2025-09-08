@echo off
REM XXMXLI Windows Double-Click Launcher
REM This batch file ensures Python scripts work from any folder

cd /d "%~dp0"
echo Starting XXMXLI Incident Reporter...
echo Current directory: %CD%

REM Try python3 first, then python
where python3 >nul 2>nul
if %errorlevel% == 0 (
    python3 "EASY_LAUNCHER.py"
) else (
    where python >nul 2>nul
    if %errorlevel% == 0 (
        python "EASY_LAUNCHER.py"
    ) else (
        echo ERROR: Python not found in PATH
        echo Please install Python 3 and add it to your PATH
        pause
        exit /b 1
    )
)

if %errorlevel% neq 0 (
    echo ERROR: Failed to run launcher
    pause
)