@echo off
:: ─── TaskFlow Clean Uninstaller for Windows ──────────────────────────────────
title TaskFlow Windows Uninstaller
cls
echo ===================================================
echo           TaskFlow Windows Uninstaller
echo ===================================================
echo.

set SKINS_DIR=%USERPROFILE%\Documents\Rainmeter\Skins\TaskFlow
set REPO_DIR=%USERPROFILE%\TaskFlow-Sync

echo [*] Removing Rainmeter TaskFlow skin...
if exist "%SKINS_DIR%" rmdir /s /q "%SKINS_DIR%"

echo.
set /p REMOVE_DATA="Do you also want to remove your local TaskFlow-Sync directory (%REPO_DIR%)? [Y/N]: "
if /i "%REMOVE_DATA%"=="Y" (
    if exist "%REPO_DIR%" rmdir /s /q "%REPO_DIR%"
    echo [*] Removed %REPO_DIR%
) else (
    echo [*] Preserved %REPO_DIR% repository to protect your task history.
)

echo.
echo ===================================================
echo     TaskFlow Uninstalled Successfully!
echo ===================================================
pause
