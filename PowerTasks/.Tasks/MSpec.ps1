$script:artifactsPath = (property artifactsPath $basePath\artifacts)
$script:config = (property config "Release")
task MSpec {
	New-Item $artifactsPath -Type directory -Force | Out-Null

	Foreach($project in @(Get-ProjectsWithPackage("Machine.Specifications"))){
		$mspecRunnerPath = Get-RequiredPackagePath Machine.Specifications.Runner.Console "$basePath\$($project.Path)"
		$runnerExecutable = "$mspecRunnerPath\tools\mspec-clr4.exe"
		exec { & $runnerExecutable --html $artifactsPath $basePath\$($project.Path)\bin\$config\$($project.Name).dll }
	}
}