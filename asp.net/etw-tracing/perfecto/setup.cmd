@echo off

setlocal

set THIS=%~dp0
if "%THIS:~-1%"=="\" set THIS=%THIS:~0,-1%

if not exist "%THIS%\Perfecto.DataCollectorSet.xml" echo Perfecto xml files not found && pause && exit /b 1
if not exist "%THIS%\Reports.Microsoft.ASPNET.xml" echo Perfecto xml files not found && pause && exit /b 1
if not exist "%THIS%\Rules.Microsoft.ASPNET.xml" echo Perfecto xml files not found && pause && exit /b 1

echo.
echo We are going to copy Xmls files to '%programfiles%\perfecto'. Ctrl+C to Cancel.
pause

echo.
echo md "%programfiles%\perfecto"
md "%programfiles%\perfecto"

echo copy "%THIS%\*.xml" "%programfiles%\perfecto"
copy "%THIS%\*.xml" "%programfiles%\perfecto"

echo logman.exe import "Service\ASPNET Perfecto" -xml "%programfiles%\perfecto\Perfecto.DataCollectorSet.xml"
logman.exe import "Service\ASPNET Perfecto" -xml "%programfiles%\perfecto\Perfecto.DataCollectorSet.xml"

echo start perfmon.msc
start perfmon.msc

echo.
echo Done!
pause

endlocal