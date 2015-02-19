# Runs every time a package is uninstalled

param($installPath, $toolsPath, $package, $project)

# $installPath is the path to the folder where the package is installed.
# $toolsPath is the path to the tools directory in the folder where the package is installed.
# $package is a reference to the package object.
# $project is a reference to the project the package was installed to.

# Remove the scripts file(s)
$tasksFolder = $project.ProjectItems.Item(".Tasks");
if ($tasksFolder -ne $null) {
	Get-ChildItem $installPath\scripts\* | % {
			$tasksFolder.ProjectItems.Item($_.Name).Remove();
			if ($tasksFolder.ProjectItems.Count -eq 0) {
				$tasksFolder.Delete();
			}
	}
	$project.Save();
}