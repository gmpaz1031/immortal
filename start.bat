@echo off
title Roblox Dev - Rojo & AI Bridge
cd /d "%~dp0"

echo ======================================================
echo   Starting Rojo & Antigravity Studio Bridge...
echo ======================================================

:: Start Python Bridge Server
start "AI Bridge Server" cmd /c "python bridge\server.py"

:: Start Rojo Server
where rojo >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    start "Rojo Server" cmd /c "rojo serve"
) else (
    start "Rojo Server" cmd /c ""%LOCALAPPDATA%\Microsoft\WinGet\Links\rojo.exe" serve"
)

echo Both servers are starting up!
echo 1. Open your place in Roblox Studio
echo 2. Click 'Connect' on the Rojo plugin
echo ======================================================
timeout /t 4
