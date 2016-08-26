$script:webJobs = (property webJobs @(@{
	Name = $projectName;
	Type = "continuous"
}))

task PrepareWebJobs {
	$webJobs | ForEach-Object {
		$webJobName = $_.Name
		$webJobType = $_.Type

		$sourcePath = "$artifactsPath\$webJobName"
		if($webJobName -eq $projectName){
			Move-Item -Path $outputPath -Destination "$artifactsPath\temp"
			$sourcePath = "$artifactsPath\temp"
		}
		$targetPath = "$artifactsPath\$projectName\App_Data\Jobs\$webJobType"
		New-Item -Path $targetPath -ItemType Directory -Force
		Copy-Item $sourcePath $targetPath -Force -Recurse
		if($webJobName -eq $projectName){
			Move-Item "$artifactsPath\$projectName\App_Data\Jobs\$webJobType\temp" "$artifactsPath\$projectName\App_Data\Jobs\$webJobType\$webJobName"
			Remove-Item "$artifactsPath\temp" -Force -Recurse
		}
	}
}