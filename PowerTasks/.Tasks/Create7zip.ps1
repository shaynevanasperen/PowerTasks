$script:buildsPath = (property buildsPath $basePath\builds)
$script:outputPath = (property outputPath (Get-OutputPath $basePath $buildsPath $projectName))

task Create7zip {
	"7-Zipping files in $outputPath"

	$7zipPath = Get-RequiredPackagePath "7-Zip.CommandLine" $basePath\.nuget
	$outputFile = "$outputPath.7z"
	$include = "-ir!$outputPath\*"
	exec { & $7zipPath\tools\7za.exe u -t7z $outputFile $include -mx9 }
}