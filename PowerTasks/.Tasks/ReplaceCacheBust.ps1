$script:cacheFiles = (property cacheFiles "")

task ReplaceCacheBust {
	Update-CacheBust $basePath\$projectName $cacheFiles "cacheBuster"
}

function script:Update-CacheBust($projectPath, $cacheFiles, $cacheBusterPattern) {
	$cacheFiles.Split(";") | foreach {
		Write-Host "Replacing the cache busters in $_"
		(Get-Content $projectPath\$_) -replace $cacheBusterPattern, (Get-Date).ToFileTime() | Set-Content $projectPath\$_
	}
}