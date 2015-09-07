$script:artifactsPath = (property artifactsPath $basePath\artifacts)
$script:config = (property config "Release")
$script:version = (property version "")
$script:prereleaseVersion = (property prereleaseVersion "pre{date}")

task Pack {
	New-Item $artifactsPath -Type directory -Force | Out-Null
	$packageVersion = $version | Resolve-PackageVersion $prereleaseVersion
	exec { & NuGet pack $basePath\$projectName\$projectName.csproj -Properties Configuration=$config -OutputDirectory $artifactsPath -Symbols -Version $packageVersion }
}
