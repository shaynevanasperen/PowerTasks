$script:artifactsPath = (property artifactsPath $basePath\artifacts)
$script:prereleaseVersion = (property prereleaseVersion "pre{date}")

task OctoPack {
	$octopusToolsPath = Get-RequiredPackagePath OctopusTools $basePath\$projectName
	$packageVersion = (Get-Date).ToString("yyyy.MM.dd.HHmmss")
	if (![string]::IsNullOrEmpty($prereleaseVersion)) {
		$packageVersion = "$packageVersion-dev"
	}
	exec { & $octopusToolsPath\Octo.exe pack --basePath=$outputPath --outFolder=$artifactsPath --id=$projectName --version=$packageVersion }
}