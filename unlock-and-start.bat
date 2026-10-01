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
echo [1/4] Stopping Mobile Hotspot Service (icssvc)...
net stop icssvc /y >nul 2>&1

:: Add the Registry Key for 128 max peers
echo [2/4] Adding WifiMaxPeers registry key...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\icssvc\Settings" /v "WifiMaxPeers" /t REG_DWORD /d 128 /f

:: Start the service back up
echo [3/4] Restarting Mobile Hotspot Service (icssvc)...
net start icssvc

:: Create and run a temporary PowerShell script to set SSID/Pass and start Hotspot
echo [4/4] Configuring SSID, Password and Starting Hotspot...
set PS_SCRIPT="%temp%\starthotspot.ps1"

echo Add-Type -AssemblyName System.Runtime.WindowsRuntime > %PS_SCRIPT%
echo $profile = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::GetInternetConnectionProfile() >> %PS_SCRIPT%
echo $tetheringManager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime]::CreateFromConnectionProfile($profile) >> %PS_SCRIPT%
echo $config = $tetheringManager.GetCurrentAccessPointConfiguration() >> %PS_SCRIPT%
echo $config.Ssid = "Sebi Network" >> %PS_SCRIPT%
echo $config.Passphrase = "12345678" >> %PS_SCRIPT%
echo $setAsync = $tetheringManager.ConfigureAccessPointAsync($config) >> %PS_SCRIPT%
echo Start-Sleep -Seconds 2 >> %PS_SCRIPT%
echo $startAsync = $tetheringManager.StartTetheringAsync() >> %PS_SCRIPT%
echo Start-Sleep -Seconds 2 >> %PS_SCRIPT%

powershell -ExecutionPolicy Bypass -File %PS_SCRIPT%
del %PS_SCRIPT%

echo.
echo ====================================================
echo  SUCCESS! Your hotspot limit is now set to 128.
echo  Hotspot "Sebi Network" has been configured and started.
echo ====================================================
echo.
pause