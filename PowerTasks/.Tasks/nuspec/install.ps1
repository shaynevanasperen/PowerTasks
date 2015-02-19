# Runs every time a package is installed in a project

param($installPath, $toolsPath, $package, $project)

# $installPath is the path to the folder where the package is installed.
# $toolsPath is the path to the tools directory in the folder where the package is installed.
# $package is a reference to the package object.
# $project is a reference to the project the package was installed to.

# Install the scripts file(s)
$tasksFolder = $project.ProjectItems.Item(".Tasks");
if ($tasksFolder -eq $null) {
	$tasksFolder = $project.ProjectItems.AddFolder(".Tasks");
}
Get-ChildItem $installPath\scripts\* | % {
	$projectItem = $tasksFolder.ProjectItems.AddFromFile($_);
	# Make sure that the project item is set to build action "None"
	$projectItem.Properties.Item("BuildAction").Value = [int]0
}
$project.Save();