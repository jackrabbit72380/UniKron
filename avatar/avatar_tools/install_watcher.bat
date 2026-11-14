@echo off
rem Makes the art index update itself: installs watch_art.ps1 into the Windows
rem Startup folder and starts it now. Double-click once; after that, dropping a
rem PNG into avatar\assets\<category>\ is enough. Needs nothing installed.
setlocal
set "TOOLS=%~dp0"
set "TOOLS=%TOOLS:~0,-1%"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "LAUNCHER=%STARTUP%\UniKron-avatar-watch.bat"

if not exist "%TOOLS%\watch_art.ps1" (
  echo Could not find watch_art.ps1 next to this file.
  pause
  exit /b 1
)

echo Installing the art watcher for:
echo    %TOOLS%
echo.
> "%LAUNCHER%" echo @echo off
>>"%LAUNCHER%" echo start "" /min powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%TOOLS%\watch_art.ps1"
echo Startup entry: %LAUNCHER%
echo Starting it now so you do not have to log out...
start "" /min powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%TOOLS%\watch_art.ps1"
echo.
echo Done. Add art, press F5 in Pegasus, and it is there.
echo To stop it, delete %LAUNCHER% and end the powershell process.
pause
