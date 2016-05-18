@echo off
powershell -NoProfile -ExecutionPolicy Unrestricted -Command ^
$ErrorActionPreference = 'Stop'; ^
if (!(Get-Command NuGet -ErrorAction SilentlyContinue) -and !(Test-Path '%LocalAppData%\NuGet\NuGet.exe')) { ^
	Write-Host 'Downloading NuGet.exe'; ^
	(New-Object system.net.WebClient).DownloadFile('https://dist.nuget.org/win-x86-commandline/latest/nuget.exe', '%LocalAppData%\NuGet\NuGet.exe'); ^
} ^
if (Test-Path '%LocalAppData%\NuGet\NuGet.exe') { ^
	Set-Alias NuGet (Resolve-Path %LocalAppData%\NuGet\NuGet.exe); ^
} ^
Write-Host 'Restoring NuGet packages'; ^
NuGet restore; ^
. '%POWERTASKS_PATH%\Functions.ps1'; ^
$basePath = Resolve-Path .; ^
Set-Location '%PROJECT_PATH%'; ^
$basePath = Split-Path (Split-Path (Resolve-Path $basePath -Relative)); ^
$projectName = '%PROJECT_NAME%'; ^
$packagesPath = '%PACKAGES_PATH%'; ^
$invokeBuildPath = Get-RequiredPackagePath Invoke-Build $basePath\$projectName; ^
& $invokeBuildPath\tools\Invoke-Build.ps1 %* -File .Tasks.ps1;
exit /b %ERRORLEVEL%
