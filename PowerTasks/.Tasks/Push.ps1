$script:buildsPath = (property buildsPath $basePath\builds)
$script:nugetPackageSource = (property nugetPackageSource "")
$script:nugetPackageSourceApiKey = (property nugetPackageSourceApiKey "LoadFromNuGetConfig")
$script:nugetPackageSourceBackupPath = (property nugetPackageSourceBackupPath "")
$script:nugetSymbolsPackageSource = (property nugetSymbolsPackageSource "")
$script:nugetSymbolsPackageSourceApiKey = (property nugetSymbolsPackageSourceApiKey "LoadFromNuGetConfig")

task Push {	
	$packages = @(Get-ChildItem $buildsPath\*.nupkg)
	if ($packages.Count -eq 0) {
		"No packages were found in $buildsPath. Please build some packages first."
	}
	else {
		"Found the following packages:"
		$packages | Select -ExpandProperty Name | Write-Host
		
		if (!$nugetPackageSourceBackupPath) {
			$nugetPackageSourceBackupPath = Read-Host "Please enter NuGet package source backup path"
		}
		if ($nugetPackageSourceBackupPath) {
			$pushedPackages = @(Get-ChildItem $nugetPackageSourceBackupPath\*.nupkg | Select -ExpandProperty Name)
		}
		else {
			$pushedPackages = @()
		}
		$newPackages = @($packages | Where-Object { $pushedPackages -notcontains $_.Name })
		
		if ($newPackages.Count -gt 0) {
			"Pushing the following packages:"
			$newPackages | Select -ExpandProperty Name | Write-Host
			
			if (!$nugetPackageSource) {
				$nugetPackageSource = Read-Host "Please enter NuGet package source"
			}
			$packageSourceIsHttp = $nugetPackageSource.ToLower().StartsWith("http")
			if (!$nugetPackageSourceApiKey -and $packageSourceIsHttp) {
				$nugetPackageSourceApiKey = Read-Host "Please enter NuGet package source API key"
			}
			
			# NuGet.exe automatically pushes symbols package to http://nuget.gw.symbolsource.org/Public/NuGet when pushing main package to https://www.nuget.org
			if (!$nugetPackageSource.StartsWith("https://www.nuget.org") -and @($newPackages | Where-Object { $_.Name.EndsWith("symbols.nupkg") }).Count -gt 0) {
				if (!$nugetSymbolsPackageSource) {
					$nugetSymbolsPackageSource = Read-Host "Please enter NuGet symbols package source"
				}
				if ($nugetSymbolsPackageSource) { # A symbols package source is optional
					$symbolsPackageSourceIsHttp = $nugetSymbolsPackageSource.ToLower().StartsWith("http")
					if (!$nugetSymbolsPackageSourceApiKey -and $packageSourceIsHttp) {
						$nugetSymbolsPackageSourceApiKey = Read-Host "Please enter NuGet symbols package source API key"
					}
				}
			}
			else {
				$nugetSymbolsPackageSource = $null
			}
			
			foreach($newPackage in $newPackages) {
				if ($newPackage.Name.EndsWith("symbols.nupkg") -and $nugetSymbolsPackageSource) {
					Push-Package $basePath $newPackage $nugetSymbolsPackageSource $nugetSymbolsPackageSourceApiKey
				}
				else {
					Push-Package $basePath $newPackage $nugetPackageSource $nugetPackageSourceApiKey
				}
				
				if ($nugetPackageSourceBackupPath -and $nugetPackageSourceBackupPath -ne $nugetPackageSource) {
					"Backing up $($newPackage.Name) to $nugetPackageSourceBackupPath"
					Copy-Item $newPackage $nugetPackageSourceBackupPath
				}
			}
		}
		else {
			"No new packages were found that need to be pushed"
		}
	}
}