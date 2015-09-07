$script:artifactsPath = (property artifactsPath $basePath\artifacts)

task Clean {
	if (Test-Path $artifactsPath) {
		"Cleaning artifacts folder"
		Remove-Item $artifactsPath\* -Recurse
	}
	"Cleaning bin folders"
	Remove-Directory "$basePath\*\bin"
	"Cleaning obj folders"
	Remove-Directory "$basePath\*\obj"
}