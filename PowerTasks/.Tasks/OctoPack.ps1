$script:artifactsPath = (property artifactsPath $basePath\artifacts)
$script:prereleaseVersion = (property prereleaseVersion "pre{date}")

task OctoPack {
	$octopusToolsPath = Get-RequiredPackagePath OctopusTools $basePath\$projectName
	if([string]::IsNullOrWhiteSpace($version)){
		$version = (Get-Date).ToString("yyyy.MM.dd.HHmmss")
	}
	$packageVersion = $version | Resolve-PackageVersion $prereleaseVersion
	exec { & $octopusToolsPath\Octo.exe pack --basePath=$outputPath --outFolder=$artifactsPath --id=$projectName --version=$packageVersion }
}