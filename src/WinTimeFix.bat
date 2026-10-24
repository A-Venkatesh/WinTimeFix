@echo off
:: WinTimeFix - Double-clickable Batch Launcher
:: Automatically requests Administrator privileges and runs WinTimeFix.ps1

setlocal
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%WinTimeFix.ps1"

:: Check for administrative permissions
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [WinTimeFix] Requesting Administrator privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd -ArgumentList '/k \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

if exist "%PS_SCRIPT%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
) else (
    echo [ERROR] Could not find WinTimeFix.ps1 in %SCRIPT_DIR%
    pause
)

