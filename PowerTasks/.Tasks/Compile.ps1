$script:buildsPath = (property buildsPath $basePath\builds)
$script:config = (property config "Release")
$script:outputPath = (property outputPath (Get-OutputPath $basePath $buildsPath $projectName))
$script:azureTargetProfile = (property azureTargetProfile "")

$script:projectTests = @(Get-TestProjectsFromSolution $basePath\$projectName.sln $basePath)

task Compile {
	use 12.0 MSBuild
	Convert-Project $config $basePath $projectName $outputPath $azureTargetProfile
	$ilMerge = Get-PackageInfo ILMerge $basePath\$projectName
	if ($ilMerge.Exists) {
		Merge-Application "$($ilMerge.Path)" $outputPath $projectName
	}
	Convert-ProjectTests $config $basePath $projectName $projectTests
}

function script:Convert-Project($config, $basePath, $projectName, $outputPath, $azureTargetProfile) {
	$projectFile = Get-ProjectFile $basePath $projectName
	$isCloudProject = $projectFile.EndsWith("ccproj")
	$isWebProject = (((Select-String -pattern "<UseIISExpress>.+</UseIISExpress>" -path $projectFile) -ne $null) -and ((Select-String -pattern "<OutputType>WinExe</OutputType>" -path $projectFile) -eq $null))
	$isWinProject = (((Select-String -pattern "<UseIISExpress>.+</UseIISExpress>" -path $projectFile) -eq $null) -and ((Select-String -pattern "<OutputType>WinExe</OutputType>" -path $projectFile) -ne $null))
	$isExeProject = (((Select-String -pattern "<UseIISExpress>.+</UseIISExpress>" -path $projectFile) -eq $null) -and ((Select-String -pattern "<OutputType>Exe</OutputType>" -path $projectFile) -ne $null))
	
	$projectName = Get-ProjectName $projectFile
	if ($isCloudProject) {
		Write-Host "Compiling $projectName to $outputPath"
		exec { MSBuild $projectFile /p:Configuration=$config /nologo /p:DebugType=None /p:Platform=AnyCpu /t:publish /p:OutputPath=$outputPath\ /p:TargetProfile=$azureTargetProfile /verbosity:quiet }
	}
	elseif ($isWebProject) {
		Write-Host "Compiling $projectName to $outputPath"
		exec { MSBuild $projectFile /p:Configuration=$config /nologo /p:DebugType=None /p:Platform=AnyCpu /p:WebProjectOutputDir=$outputPath /p:OutDir=$outputPath\bin /verbosity:quiet }
	}
	elseif ($isWinProject -or $isExeProject) {
		Write-Host "Compiling $projectName to $outputPath"
		exec { MSBuild $projectFile /p:Configuration=$config /nologo /p:DebugType=None /p:Platform=AnyCpu /p:OutDir=$outputPath /verbosity:quiet }
	}
	elseif (!$projectName.EndsWith("Tests")) {
		Write-Host "Compiling $projectName"
		exec { MSBuild $projectFile /p:Configuration=$config /nologo /p:Platform=AnyCpu /verbosity:quiet }
	}
}

function script:Convert-ProjectTests($config, $basePath, $projectName, $projectTests) {
	if ($projectTests.Length -gt 0) {
		foreach ($projectTest in $projectTests) {
			"Compiling $($projectTest.Name)"
			$projectFile = "$basePath\$($projectTest.Path)\$($projectTest.File)"
			if (Test-Path $projectFile) {
				if(@($projectTest.Types | ?{ $_.Name -eq "SpecFlow" }).Length -gt 0) {
					@(Get-SolutionConfigurations $basePath\$projectName.sln) | Where { (Get-IsLocalTest $_ $basePath\$($projectTest.Path)) -ne $true } | foreach {
						exec { MSBuild $projectFile /p:Configuration=$_ /nologo /verbosity:quiet }
					}
				}
				else {
					exec { MSBuild $projectFile /p:Configuration=$config /nologo /verbosity:quiet }
				}
			}
		}
	}
}

function script:Merge-Application($ilMergePath, $outputPath, $projectName) {
	Write-Host "Merging application executables and assemblies"
	$exeNames = Get-ChildItem -Path "$outputPath\*" -Filter *.exe | ForEach-Object { """" + $_.FullName + """" }
	$assemblyNames = Get-ChildItem -Path "$outputPath\*" -Filter *.dll | ForEach-Object { """" + $_.FullName + """" }
	
	$assemblyNamesArgument = [System.String]::Join(" ", $assemblyNames)
	$exeNamesArgument = [System.String]::Join(" ", $exeNames)
	
	$appFileName = "$outputPath\$projectName.exe"
	
	Invoke-Expression "$ilMergePath\tools\ILMerge.exe /t:exe /targetPlatform:""v4"" /out:$appFileName $exeNamesArgument $assemblyNamesArgument"
	
	Get-ChildItem -Path "$outputPath\*" -Exclude *.exe,*.config | foreach { $_.Delete() }
}