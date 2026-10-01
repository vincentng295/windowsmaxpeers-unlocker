@echo off
:: Check for administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0""", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%cd%"
    CD /D "%~dp0"

echo ====================================================
echo  Configuring Windows Hotspot Max Devices (WifiMaxPeers)
echo ====================================================
echo.

:: Stop the Mobile Hotspot service safely
echo [1/3] Stopping Mobile Hotspot Service (icssvc)...
net stop icssvc /y >nul 2>&1

:: Add the Registry Key for 128 max peers (Decimal 128 = Hex 80)
echo [2/3] Adding WifiMaxPeers registry key...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\icssvc\Settings" /v "WifiMaxPeers" /t REG_DWORD /d 128 /f

:: Start the service back up
echo [3/3] Restarting Mobile Hotspot Service (icssvc)...
net start icssvc

echo.
echo ====================================================
echo  SUCCESS! Your hotspot limit is now set to 128.
echo ====================================================
echo.
pause
