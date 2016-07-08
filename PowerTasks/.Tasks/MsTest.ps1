$script:artifactsPath = (property artifactsPath $basePath\artifacts)
task MsTest {
	New-Item $artifactsPath -Type directory -Force | Out-Null

	$mstestrunner = "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\MSTest.exe"
	if(!(Test-Path $mstestrunner)){
		# Can't find ms test runner in default location, assume it's in the path
		$mstestrunner = "mstest.exe"
	}
	
	foreach ($projectTest in  @(Get-ProjectsWithReference("Microsoft.VisualStudio.QualityTools.UnitTestFramework"))) {
		$path = Resolve-Path "$basePath\$($projectTest.Path)\bin\$config\$($projectTest.Name).dll"
		exec { & $mstestrunner /testcontainer:$path /resultsFile:$artifactsPath\result.trx }
		continue
	}
}