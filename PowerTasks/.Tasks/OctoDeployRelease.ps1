$script:artifactsPath = (property artifactsPath $basePath\artifacts)
$script:octopusDeployServer = (property octopusDeployServer "")
$script:octopusDeployApiKey = (property octopusDeployApiKey "")
$script:octopusDeployProjectName = (property octopusDeployProjectName $projectName)
$script:environment = (property environment "")

task OctoDeployRelease {
	if([String]::IsNullOrEmpty($octopusDeployServer)){
		throw "Please specify the octopusDeployServer"
	}
	if([String]::IsNullOrEmpty($octopusDeployApiKey)){
		throw "Please specify the octopusDeployApiKey"
	}

	$assemblyInfoFile = Get-Content ".\Properties\AssemblyInfo.cs"
	if(!$version){
		$version = $assemblyInfoFile | 
					where { $_ -match "AssemblyVersion\(`"(?<version>.*)`"\)" } |
					foreach { $matches["version"] }
	}

	$octopusToolsPath = Get-RequiredPackagePath OctopusTools $basePath\$projectName
	$cmd = "$octopusToolsPath\tools\Octo.exe deploy-release --server=""$octopusDeployServer"" --apiKey=""$octopusDeployApiKey"" --project=""$octopusDeployProjectName"" --version=""$version"" --deployto=""$environment"""

	exec { & Invoke-Expression $cmd }
}