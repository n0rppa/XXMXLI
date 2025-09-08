@echo off
REM XXMXLI Incident Reporter Installer - Windows
REM This batch file installs and configures the incident reporting system

echo ================================================================
echo XXMXLI Incident Reporter Installer
echo ================================================================
echo.

REM Get script directory
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"
echo Installing from: %SCRIPT_DIR%
echo.

REM Check Python installation
echo Checking Python installation...
where python3 >nul 2>nul
if %errorlevel% == 0 (
    set "PYTHON_CMD=python3"
    echo [32m✓ Python 3 found[0m
    python3 --version
) else (
    where python >nul 2>nul
    if %errorlevel% == 0 (
        set "PYTHON_CMD=python"
        echo [32m✓ Python found[0m
        python --version
    ) else (
        echo [31m✗ Python not found. Please install Python 3.[0m
        pause
        exit /b 1
    )
)

REM Check tkinter for GUI applications
echo.
echo Checking GUI support...
%PYTHON_CMD% -c "import tkinter" >nul 2>nul
if %errorlevel% == 0 (
    echo [32m✓ GUI support available (tkinter found)[0m
) else (
    echo [33m⚠ GUI support limited - tkinter not available[0m
    echo Please ensure you have a complete Python installation
)

REM Create necessary directories
echo.
echo Creating directories...
if not exist "%SCRIPT_DIR%reports" mkdir "%SCRIPT_DIR%reports"
if not exist "%SCRIPT_DIR%logs" mkdir "%SCRIPT_DIR%logs"
echo [32m✓ Directories created[0m

REM Test the incident reporter
echo.
echo Testing incident reporter...
%PYTHON_CMD% "%SCRIPT_DIR%automated_incident_reporter.py" setup
if %errorlevel% == 0 (
    echo [32m✓ Incident reporter installed successfully[0m
) else (
    echo [31m✗ Installation test failed[0m
    pause
    exit /b 1
)

REM Create desktop shortcut (optional)
echo.
echo Creating shortcuts...
echo Set objShell = CreateObject("WScript.Shell") > "%TEMP%\create_shortcut.vbs"
echo Set objShortcut = objShell.CreateShortcut("%USERPROFILE%\Desktop\XXMXLI Incident Reporter.lnk") >> "%TEMP%\create_shortcut.vbs"
echo objShortcut.TargetPath = "%PYTHON_CMD%" >> "%TEMP%\create_shortcut.vbs"
echo objShortcut.Arguments = """%SCRIPT_DIR%EASY_LAUNCHER.py""" >> "%TEMP%\create_shortcut.vbs"
echo objShortcut.WorkingDirectory = "%SCRIPT_DIR%" >> "%TEMP%\create_shortcut.vbs"
echo objShortcut.Description = "XXMXLI Security Incident Reporter" >> "%TEMP%\create_shortcut.vbs"
echo objShortcut.Save >> "%TEMP%\create_shortcut.vbs"
cscript //nologo "%TEMP%\create_shortcut.vbs"
del "%TEMP%\create_shortcut.vbs"
echo [32m✓ Desktop shortcut created[0m

echo.
echo [32m================================================================[0m
echo [32mINSTALLATION COMPLETE[0m
echo [32m================================================================[0m
echo.
echo [33mAvailable launchers:[0m
echo   • Double-click: DOUBLE_CLICK_LAUNCHER.bat
echo   • GUI Launcher: %PYTHON_CMD% "%SCRIPT_DIR%EASY_LAUNCHER.py"
echo   • Main Control: %PYTHON_CMD% "%SCRIPT_DIR%XXMXLI_LAUNCHER.py"
echo   • Direct CLI:   %PYTHON_CMD% "%SCRIPT_DIR%automated_incident_reporter.py"
echo.
echo [34mThe system is now ready for security incident reporting![0m
echo.
pause