$script:version = (property version "")

task Version {
	$script:version = Set-Version . $version
}

function script:Set-Version($projectPath, $version) {
	$assemblyInfoFile = "$projectPath\Properties\AssemblyInfo.cs"
	if ($version) {
		
		$year = $(Get-date -f yyyy)
		$month = $(Get-date -f %M)
		$quarter = $([Math]::ceiling((Get-date -f MM)/3))
		$date = $(Get-date -f dd)

		$version = $version.Replace("{year}", $year).Replace("{month}", $month).Replace("{quarter}", $quarter).Replace("{date}", $date)

		if ((Test-Path $assemblyInfoFile)) {
			Write-Host "Updating $assemblyInfoFile"
			$newAssemblyVersion = 'AssemblyVersion("' + $version + '")'
			$newAssemblyFileVersion = 'AssemblyFileVersion("' + $version + '")'
			$newFileContent = Get-Content $assemblyInfoFile |
				%{ $_ -replace 'AssemblyVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', $newAssemblyVersion } |
				%{ $_ -replace 'AssemblyFileVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', $newAssemblyFileVersion }
			Set-Content $assemblyInfoFile $newFileContent
		}
	}
	else {
		Write-Host "Getting version from $assemblyInfoFile"
		$version = Get-AssemblyFileVersion $assemblyInfoFile
	}
	return $version
}