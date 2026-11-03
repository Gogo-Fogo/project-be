@echo off
set PS=powershell
where pwsh >nul 2>nul && set PS=pwsh
rem Double-click: offline library + local AI.
%PS% -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Emergency.ps1" %*
