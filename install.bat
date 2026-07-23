@echo off
:: ─── TaskFlow Smart One-Shot Installer for Windows (Rainmeter) ─────────────────
title TaskFlow Windows Installer
cls
echo ===================================================
echo     TaskFlow One-Shot Windows / Rainmeter Setup
echo ===================================================
echo.

set SKINS_DIR=%USERPROFILE%\Documents\Rainmeter\Skins\TaskFlow
set REPO_DIR=%USERPROFILE%\TaskFlow-Sync

echo [*] Creating Rainmeter skin directory...
if not exist "%SKINS_DIR%" mkdir "%SKINS_DIR%"
if not exist "%REPO_DIR%" mkdir "%REPO_DIR%"

echo [*] Copying skin files...
if exist "windows\Rainmeter\TaskFlow\*" (
    xcopy /E /Y "windows\Rainmeter\TaskFlow\*" "%SKINS_DIR%\"
)

echo [*] Setting up Git Repository in %REPO_DIR%...
cd /d "%REPO_DIR%"
if not exist ".git" (
    git init
    git branch -M main
)

if not exist "todo.json" (
    echo {"lists":[],"currentListId":"","tasks":{}} > todo.json
)

echo [*] Installing PowerShell backup script...
(
echo $repo = "$env:USERPROFILE\TaskFlow-Sync"
echo Set-Location $repo
echo if (Test-Path "todo.json"^) {
echo     $status = git status --porcelain todo.json
echo     if ($status^) {
echo         git add todo.json
echo         $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
echo         git commit -m "Auto-backup $date"
echo         git push origin main
echo     }
echo }
) > "%REPO_DIR%\backup.ps1"

echo.
set /p CLEAN_LINUX="Do you want to clean up Linux-specific files (install.sh, linux/)? [Y/N]: "
if /i "%CLEAN_LINUX%"=="Y" (
    del /f /q install.sh 2>nul
    rmdir /s /q linux 2>nul
    echo [*] Cleaned up Linux files.
)

echo.
echo ===================================================
echo     TaskFlow Setup Complete!
echo  Rainmeter skin installed to: %SKINS_DIR%
echo ===================================================
pause
