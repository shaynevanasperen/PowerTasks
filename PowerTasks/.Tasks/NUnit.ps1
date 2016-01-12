$script:artifactsPath = (property artifactsPath $basePath\artifacts)
$script:config = (property config "Release")
task NUnit {
	New-Item $artifactsPath -Type directory -Force | Out-Null

	Foreach($project in @(Get-ProjectsWithPackage("Nunit"))){
		$nunitRunnerPath = Get-RequiredPackagePath NUnit.Runners "$basePath\$($project.Path)"
		$runnerExecutable = "$nunitRunnerPath\tools\nunit-console.exe"
		exec { & $runnerExecutable /xml:$artifactsPath\nunit.xml /nologo $basePath\$($project.Path)\bin\$config\$($project.Name).dll }
	}
}