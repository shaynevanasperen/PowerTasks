param(
	$buildsPath = (property buildsPath $basePath\builds),
	$prereleaseVersion = (property prereleaseVersion "")
)

. .\.Tasks\Clean.ps1
. .\.Tasks\Version.ps1
. .\.Tasks\Push.ps1

task CopyReadme {
	Get-Content $basePath\README.md | Set-Content README.txt
}

task Pack Clean, Version, CopyReadme, {
	New-Item $buildsPath -Type directory -Force | Out-Null
	$packageVersion = $version | Resolve-PackageVersion $prereleaseVersion
	exec { & NuGet pack $basePath\$projectName\$projectName.nuspec -OutputDirectory $buildsPath -Properties Version=$packageVersion -NoPackageAnalysis }
	Get-ChildItem $basePath\$projectName\.Tasks\*.nuspec -Recurse | %{ exec { & NuGet pack $_.FullName -OutputDirectory $buildsPath -NoPackageAnalysis } }
}

task . Pack