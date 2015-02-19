# Runs every time a package is installed in a project

param($installPath, $toolsPath, $package, $project)

# $installPath is the path to the folder where the package is installed.
# $toolsPath is the path to the tools directory in the folder where the package is installed.
# $package is a reference to the package object.
# $project is a reference to the project the package was installed to.

@"

============================================================
PowerTasks - Convention based task runner using Invoke-Build
============================================================
"@ | Write-Host

# Install the pt.bat file
Copy-Item "$installPath\pt.bat" .
Push-Location (Split-Path $project.FullName)
$packagesPath = (Split-Path $installPath | Resolve-Path -Relative)
Pop-Location
$content = Get-Content "pt.bat" |
	%{ $_ -replace "%POWERTASKS_PATH%", (Resolve-Path $installPath -Relative) } |
	%{ $_ -replace "%PROJECT_PATH%", (Split-Path $project.FullName | Resolve-Path -Relative) } |
	%{ $_ -replace "%PROJECT_NAME%", $project.Name } |
	%{ $_ -replace "%PACKAGES_PATH%", $packagesPath }
Set-Content "pt.bat" $content
Write-Host "Installed pt.bat"

# Make sure that the .Tasks file is set to build action "None"
$tasksItem = $project.ProjectItems.Item(".Tasks.ps1")
$tasksItem.Properties.Item("BuildAction").Value = [int]0

# Make sure that the packages file is set to build action "None"
$packagesItem = $project.ProjectItems.Item("packages.config")
$packagesItem.Properties.Item("BuildAction").Value = [int]0
$project.Save()