@echo off
powershell -NoProfile -ExecutionPolicy Unrestricted -Command ^
$ErrorActionPreference = 'Stop'; ^
if (!(Get-Command NuGet -ErrorAction SilentlyContinue) -and !(Test-Path '.\.nuget\NuGet.exe')) { ^
	Write-Host 'Downloading NuGet.exe'; ^
	(New-Object system.net.WebClient).DownloadFile('https://www.nuget.org/nuget.exe', '.nuget\NuGet.exe'); ^
} ^
if (Test-Path '.\.nuget\NuGet.exe') { ^
	Set-Alias NuGet (Resolve-Path .nuget\NuGet.exe); ^
} ^
Write-Host 'Restoring NuGet packages'; ^
NuGet restore; ^
. '%POWERTASKS_PATH%\Functions.ps1'; ^
$basePath = Resolve-Path .; ^
Set-Location '%PROJECT_PATH%'; ^
$basePath = Split-Path (Split-Path (Resolve-Path $basePath -Relative)); ^
$projectName = '%PROJECT_NAME%'; ^
$packagesPath = '%PACKAGES_PATH%'; ^
$invokeBuildPath = Get-RequiredPackagePath Invoke-Build $basePath\.nuget; ^
& $invokeBuildPath\tools\Invoke-Build.ps1 %* -File .Tasks.ps1;
exit /b %ERRORLEVEL%