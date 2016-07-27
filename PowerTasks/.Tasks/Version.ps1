$script:version = (property version "")

task Version {
	$script:version = Set-Version . $version
}

function script:Set-Version($projectPath, $version) {
	$assemblyInfoFile = "$projectPath\Properties\AssemblyInfo.cs"
	if ($version) {
		
		$year = $(Get-date -f yyyy)
		$month = $(Get-date -f %M)
		$fullMonth = $(Get-date -f MM)
		$quarter = $([Math]::ceiling((Get-date -f MM)/3))
		$date = $(Get-date -f dd)

		$version = $version.Replace("{year}", $year).Replace("{month}", $month).Replace("{fullMonth}", $fullMonth).Replace("{quarter}", $quarter).Replace("{date}", $date)
		$assemblyVersion = $version.Clone()
		$assemblyVersion = $assemblyVersion.Replace("{commit}", "").Replace("{shortCommit}", "").Replace("{branch}", "").Replace("-", "")
		Write-Host $assemblyVersion
		if($version.Contains("{branch}") -or $version.Contains("commit")){
			pushd ..
			
			try {
				if([String]::IsNullOrEmpty($env:APPVEYOR_REPO_BRANCH)){
					$branch = git branch | Where {$_ -match "^\*(.*)"} | Select-Object -First 1
				} else{
					$branc = $env:APPVEYOR_REPO_BRANCH
				}
				$branch = $branch.Replace("* ", "").Replace("/", "-")

				$commit = git rev-parse HEAD
				$shortCommit = $commit.Substring(0,7)

				$version = $version.Replace("{branch}", $branch).Replace("{commit}", $commit).Replace("{shortCommit}", $shortCommit)
			}
			catch{
				Write-Host "Could not determine branch and commit hash through git"
			}
			
			popd
		}
		

		if ((Test-Path $assemblyInfoFile)) {
			Write-Host "Updating $assemblyInfoFile with $assemblyVersion"
			$newAssemblyVersion = 'AssemblyVersion("' + $assemblyVersion + '")'
			$newAssemblyFileVersion = 'AssemblyFileVersion("' + $assemblyVersion + '")'
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
	Write-Host "Version obtained: $version"
	return $version
}