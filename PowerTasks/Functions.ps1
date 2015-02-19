function Get-RequiredPackagePath($packageId, $path) {
	$package = Get-PackageInfo $packageId $path
	if (!$package.Exists) {
		throw "$packageId is required in $path, but it is not installed. Please install $packageId in $path"
	}
	return $package.Path
}

function Remove-Directory($path) {
	Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
}

function Get-AssemblyFileVersion($assemblyInfoFile) {
	$line = Get-Content $assemblyInfoFile | Where { $_.Contains("AssemblyFileVersion") }
	if (!$line) {
		$line = Get-Content $assemblyInfoFile | Where { $_.Contains("AssemblyVersion") }
		if (!$line) {
			throw "Couldn't find an AssemblyFileVersion or AssemblyVersion attribute"
		}
	}
	return $line.Split('"')[1]
}

function Resolve-PackageVersion($prereleaseVersion) {
	if (![string]::IsNullOrEmpty($prereleaseVersion)) {
		$version = ([string]$input).Split('-')[0]
		$date = Get-Date
		$parsed = $prereleaseVersion.Replace("{date}", $date.ToString("yyMMddHHmm"))
		return "$version-$parsed"
	}
	else {
		return $input
	}
}

function Include-PluginScripts([string[]] $packageIdPatterns) {
	$packageIdPatterns = @("PowerTasks.Plugins.*") + $packageIdPatterns
	$packageIdPatterns |
		% { Get-PackageNames $_ . } | Select -Unique |
		% {	(Get-PackageInfo $_ .) } | Where { $_.Exists } |
		% {	Get-ChildItem "$($_.Path)\scripts\*.ps1" } |
		% { . $_ }
}

function Get-PackageNames($pattern, $path = ".") {
	if (!(Test-Path $path\packages.config)) {
		return @()
	}
	[xml]$packagesXml = Get-Content $path\packages.config
	return $packagesXml.packages.package | Where { $_.id -like $pattern } | Select -ExpandProperty id
}

function Get-TestProjectsFromSolution($solution, $basePath) {
	$projects = @()
	if (Test-Path $solution) {
		Get-Content $solution |
		Select-String 'Project\(' |
		ForEach-Object {
			$projectParts = $_ -Split '[,=]' | ForEach-Object { $_.Trim('[ "{}]') };
			if($projectParts[2].EndsWith(".csproj") -and $projectParts[1].EndsWith("Tests")) {
				$file = $projectParts[2].Split("\")[-1]
				$path = $projectParts[2].Replace("\$file", "")
				
				$projects += New-Object PSObject -Property @{
					Name = $projectParts[1];
					File = $file;
					Path = $path;
					Types = @(Get-TestTypesForPath $path $basePath);
				}	
			}
		}
	}
	return $projects
}

function Get-TestTypesForPath($path, $basePath) {
	$types = @()
	
	$mspec = Get-PackageInfo Machine.Specifications $basePath\$path
	if($mspec.Exists) {
		$types += $mspec
	}
	
	$nunit = Get-PackageInfo NUnit $basePath\$path
	if ($nunit.Exists) {
		$specflow = Get-PackageInfo SpecFlow $basePath\$path
		if ($specflow.Exists) {
			New-Item "$($specflow.Path)\tools\specflow.exe.config" -Type file -Force -Value `
				"<?xml version=""1.0"" encoding=""utf-8"" ?> <configuration> <startup> <supportedRuntime version=""v4.0.30319"" /> </startup> </configuration>" | Out-Null
			$types += $specflow
		}
		else {
			$types += $nunit
		}
	}
	
	if (Test-Path $basePath\$path\js\runner.js) {
		$types += Get-PackageInfo Chutzpah $basePath\$path
	}
	
	return $types
}

function Get-SolutionConfigurations($solution) {
	Get-Content $solution |
	Where-Object {$_ -match "(?<config>\w+)\|"} |
	%{ $($Matches['config'])} |
	Select -uniq
}

function Get-PackageInfo($packageId, $path) {
	if (!(Test-Path "$path\packages.config")) {
		return New-Object PSObject -Property @{
			Exists = $false;
		}
	}
	
	[xml]$packagesXml = Get-Content "$path\packages.config"
	$package = $packagesXml.packages.package | Where { $_.id -eq $packageId }
	if (!$package) {
		return New-Object PSObject -Property @{
			Exists = $false;
		}
	}
	
	$versionComponents = $package.version.Split('.')
    [array]::Reverse($versionComponents)
		
	$numericalVersion = 0
	$modifier = 1
	
	foreach ($component in $versionComponents) {
		$numericalComponent = $component -as [int]
		if ($numericalComponent -eq $null) {
			continue
		}
		$numericalVersion = $numericalVersion + ([int]$numericalComponent * $modifier)
		$modifier = $modifier * 10
	}
	
	return New-Object PSObject -Property @{
		Exists = $true;
		Version = $package.version;
		Number = $numericalVersion;
		Id = $package.id;
		Path = "$packagesPath\$($package.id).$($package.version)"
	}
}

function Get-IsLocalTest($configuration, $path) {
	[xml](Get-Content "$path\app.$configuration.config") |
	Select-Xml "//configuration/appSettings/add[@key='local']" |
	%{ $_.Node.Attributes["value"].Value } |
	Select -First 1
}

function Get-ProjectName($projectFile) {
	$projectName = (Split-Path $projectFile -Leaf)
	$projectName = $projectName.Substring(0, $projectName.LastIndexOf("."))
	return $projectName
}

function Get-ProjectFile($basePath, $projectName) {
	$projectFile = "$basePath\$projectName.Cloud\$projectName.Cloud.ccproj"
	if (!(Test-Path $projectFile)) {
		$projectFile = "$basePath\$projectName\$projectName.csproj"
	}
	return $projectFile
}

function Get-OutputPath($basePath, $buildsPath, $projectName) {
	$projectFile = Get-ProjectFile $basePath $projectName
	$projectName = Get-ProjectName $projectFile
	$outputPath = "$buildsPath\$projectName"
	return $outputPath
}

function Push-Package($basePath, $package, $nugetPackageSource, $nugetPackageSourceApiKey) {
	if (![string]::IsNullOrEmpty($nugetPackageSourceApiKey) -and $nugetPackageSourceApiKey -ne "LoadFromNuGetConfig") {
		exec { & NuGet push $package -Source $nugetPackageSource -ApiKey $nugetPackageSourceApiKey }
	}
	else {
		exec { & NuGet push $package -Source $nugetPackageSource }
	}
}