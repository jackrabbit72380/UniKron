@echo off
rem Regenerates avatar\assets\AssetIndex.js from whatever is in the art folders.
rem Double-click after adding or removing art, then restart Pegasus.
cd /d "%~dp0"
python art_index.py || py art_index.py
pause
