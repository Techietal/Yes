@echo off
title Check Screen Saver Status
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check-status.ps1"
echo.
pause
