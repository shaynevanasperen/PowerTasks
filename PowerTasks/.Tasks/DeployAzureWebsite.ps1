$script:azurePublishProfile = (property azurePublishProfile "$basePath\$projectName\Properties\PublishProfiles\$projectName.pubxml")
$script:azurePassword = (property azurePassword "")

task DeployAzureWebsite {
	use 12.0 MSBuild

	$projectFile = "$basePath\$projectName\$projectName.csproj"

	if (!$azurePassword) {
		$azurePassword = Read-Host "Password"
	}

	exec { MSBuild $projectFile /p:DeployOnBuild=true /p:PublishProfile=$azurePublishProfile /p:VisualStudioVersion=12.0 /p:Password=$azurePassword /p:AllowUntrustedCertificate=true }
}