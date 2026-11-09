@echo off
title Keep-Awake
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0keepawake.ps1"
echo.
pause
