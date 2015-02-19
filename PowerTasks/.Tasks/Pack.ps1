$script:buildsPath = (property buildsPath $basePath\builds)
$script:config = (property config "Release")
$script:version = (property version "")
$script:prereleaseVersion = (property prereleaseVersion "pre{date}")

task Pack Test, {
	New-Item $buildsPath -Type directory -Force | Out-Null
	$packageVersion = $version | Resolve-PackageVersion $prereleaseVersion
	exec { & NuGet pack $basePath\$projectName\$projectName.csproj -Properties Configuration=$config -OutputDirectory $buildsPath -Symbols -Version $packageVersion }
}
