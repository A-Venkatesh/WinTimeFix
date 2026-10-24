@echo off
setlocal enabledelayedexpansion
title Push WinTimeFix to GitHub

echo ========================================================
echo   Pushing WinTimeFix to https://github.com/A-Venkatesh/WinTimeFix
echo ========================================================
echo.

cd /d "%~dp0"

:: 1. Check if git is installed
where git >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Git is not detected on your system.
    echo [*] Installing Git using winget...
    winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements
    if !errorLevel! neq 0 (
        echo [ERROR] Failed to automatically install Git.
        echo Please download and install Git from: https://git-scm.com/download/win
        pause
        exit /b 1
    )
    :: Refresh PATH for current session
    set "PATH=%PATH%;C:\Program Files\Git\cmd;C:\Program Files\Git\bin"
)

:: 2. Initialize repository if not already initialized
if not exist ".git" (
    echo [*] Initializing Git repository...
    git init -b main
)

:: 3. Configure remote origin
git remote remove origin >nul 2>&1
echo [*] Adding remote origin...
git remote add origin https://github.com/A-Venkatesh/WinTimeFix.git

:: 4. Stage and commit files
echo [*] Staging all files...
git add -A

git status

echo [*] Committing changes...
git commit -m "Initial release of WinTimeFix: Automated Windows Time Sync Repair Tool"

:: 5. Push to GitHub
echo.
echo [*] Pushing to main branch...
echo (If prompted by Git Credential Manager, click 'Sign in with your browser' to authorize)
echo.

git push -u origin main

if %errorLevel% equ 0 (
    echo.
    echo ========================================================
    echo [SUCCESS] Code successfully pushed to GitHub!
    echo View your repository: https://github.com/A-Venkatesh/WinTimeFix
    echo ========================================================
) else (
    echo.
    echo [!] Push encountered an issue. If the remote repository already contains files,
    echo     trying to reconcile with: git push -u origin main --force
    set /p RETRY="Force push to overwrite empty remote? (Y/N): "
    if /i "!RETRY!"=="Y" (
        git push -u origin main --force
    )
)

echo.
pause

