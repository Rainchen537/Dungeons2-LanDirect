@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Manage-LanDirect.ps1" -Action Uninstall
set "result=%errorlevel%"
pause
exit /b %result%
