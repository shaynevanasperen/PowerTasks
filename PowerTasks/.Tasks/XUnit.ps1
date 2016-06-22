$script:artifactsPath = (property artifactsPath $basePath\artifacts)
$script:config = (property config "Release")
task XUnit {
	New-Item $artifactsPath -Type directory -Force | Out-Null

	foreach ($project in  @(Get-ProjectsWithPackage("Xunit"))) {
		$xunitRunnerPath = Get-RequiredPackagePath XUnit.Runner.Console "$basePath\$($project.Path)"
		$runnerExecutable = "$xunitRunnerPath\tools\xunit.console.exe"
		exec { & $runnerExecutable $basePath\$($project.Path)\bin\$config\$($project.Name).dll -xml "$artifactsPath\xunit.xml" -html "$artifactsPath\xunit.html" -nologo }
		continue
	}
}