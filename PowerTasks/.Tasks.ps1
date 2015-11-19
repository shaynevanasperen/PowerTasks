param(
	$artifactsPath = (property artifactsPath $basePath\artifacts),
	$prereleaseVersion = (property prereleaseVersion "")
)

. .\.Tasks\Clean.ps1
. .\.Tasks\Version.ps1
. .\.Tasks\Push.ps1

task CopyReadme {
	Get-Content $basePath\README.md | Set-Content README.txt
}

task Pack Clean, Version, CopyReadme, {
	New-Item $artifactsPath -Type directory -Force | Out-Null
	$packageVersion = $version | Resolve-PackageVersion $prereleaseVersion
	exec { & NuGet pack $basePath\$projectName\$projectName.nuspec -OutputDirectory $artifactsPath -Properties Version=$packageVersion -NoPackageAnalysis }
	Get-ChildItem $basePath\$projectName\.Tasks\*.nuspec -Recurse | %{ exec { & NuGet pack $_.FullName -OutputDirectory $artifactsPath -NoPackageAnalysis } }
}

task . Pack, Push