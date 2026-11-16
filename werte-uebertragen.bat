@echo off
rem Beste Werte aus pid-tuning.csv in meilenstein.nxc eintragen und auf den NXT uebertragen
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0werte-uebertragen.ps1"
echo.
pause
