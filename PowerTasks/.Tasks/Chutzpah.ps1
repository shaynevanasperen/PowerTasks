$script:artifactsPath = (property artifactsPath $basePath\artifacts)

task Chutzpah {
	foreach ($project in  @(Get-ProjectsWithPackage("Chutzpah"))) {
		$chutzpahPath = Get-RequiredPackagePath Chutzpah "$basePath\$($project.Path)"
		$runnerExecutable = "$chutzpahPath\tools\chutzpah.console.exe"
		exec { & $runnerExecutable /nologo $basePath\$($project.Path)\js\runner.js }
		continue
	}
}