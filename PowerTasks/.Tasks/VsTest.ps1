$script:artifactsPath = (property artifactsPath $basePath\artifacts)
task VsTest {
	New-Item $artifactsPath -Type directory -Force | Out-Null

	$vstestrunner = "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe"
	if(!(Test-Path $vstestrunner)){
		# Can't find vs test runner in default location, assume it's in the path
		$vstestrunner = "vstest.console.exe"
	}
	
	foreach ($projectTest in  @(Get-ProjectsWithReference("Microsoft.VisualStudio.QualityTools.UnitTestFramework"))) {
		$path = Resolve-Path "$basePath\$($projectTest.Path)\bin\$config\$($projectTest.Name).dll"

		exec { & $vstestrunner $path /logger:trx  }
		continue
	}

	# Move the files from the project dir to the output dir because trx does not support defining the outputfile
	Get-ChildItem "$basePath\$projectName\TestResults" -Filter *.trx | 
		Foreach-Object {
			Move-Item -Path $_.FullName -Destination $artifactsPath
		}
}