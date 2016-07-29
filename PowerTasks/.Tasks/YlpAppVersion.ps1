$script:version = (property version "")

task YlpAppVersion {
	$script:version = Set-Version . $version
}

function script:Set-Version($projectPath, $version) {
	$assemblyInfoFile = "$projectPath\Properties\AssemblyInfo.cs"
	
	if([String]::IsNullOrEmpty($env:APPVEYOR_BUILD_NUMBER )){
		$buildNumber = (Get-Date).ticks.ToString()
		$buildNumber = $buildNumber.Substring($buildNumber.Length - 10)
	}else{
		$buildNumber = $env:APPVEYOR_BUILD_NUMBER
	}

	pushd ..
	$shortCommit = $(git rev-parse HEAD).Substring(0,7)
	popd
		
	$version = "$(Get-date -f yyyy).$(Get-date -f MM).$(Get-date -f dd)-v$buildNumber-$shortCommit"
	$assemblyVersion = "$(Get-date -f yyyy).$(Get-date -f MM).$(Get-date -f dd).$($buildNumber.SubString(0, [System.Math]::Min(5, $buildNumber.Length)))"

	if ((Test-Path $assemblyInfoFile)) {
		Write-Host "Updating $assemblyInfoFile with $assemblyVersion"
		$newAssemblyVersion = 'AssemblyVersion("' + $assemblyVersion + '")'
		$newAssemblyFileVersion = 'AssemblyFileVersion("' + $assemblyVersion + '")'
		$newFileContent = Get-Content $assemblyInfoFile |
			%{ $_ -replace 'AssemblyVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', $newAssemblyVersion } |
			%{ $_ -replace 'AssemblyFileVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', $newAssemblyFileVersion }
		Set-Content $assemblyInfoFile $newFileContent
	}
	
	Write-Host "Version obtained: $version"
	return $version
}