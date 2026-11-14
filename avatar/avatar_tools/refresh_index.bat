@echo off
rem Rewrites avatar\AssetIndex.qml from the art folders, once.
rem Only needed if the background watcher (install_watcher.bat) is not running.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0watch_art.ps1" -Once
pause
