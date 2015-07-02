$script:buildsPath = (property buildsPath $basePath\builds)
$script:prereleaseVersion = (property prereleaseVersion "pre{date}")
$script:octopusPackageSource = (property octopusPackageSource "")
$script:octopusPackageSourceApiKey = (property octopusPackageSourceApiKey "LoadFromNuGetConfig")

task OctoPack {
	$octopusToolsPath = Get-RequiredPackagePath OctopusTools $basePath\.nuget
	$packageVersion = (Get-Date).ToString("yyyy.MM.dd.HHmmss")
	if (![string]::IsNullOrEmpty($prereleaseVersion)) {
		$packageVersion = "$packageVersion-dev"
	}
	exec { & $octopusToolsPath\Octo.exe pack --basePath=$outputPath --outFolder=$buildsPath --id=$projectName --version=$packageVersion }
		
	$octopusPackage = Get-ChildItem $buildsPath\$projectName*.nupkg
	if (!$octopusPackageSource) {
		$octopusPackageSource = Read-Host "Please enter Octopus package source"
	}
	if (!$octopusPackageSourceApiKey) {
		$octopusPackageSourceApiKey = Read-Host "Please enter Octopus package source API key"
	}
	Push-Package $basePath $octopusPackage $octopusPackageSource $octopusPackageSourceApiKey
}