$script:artifactsPath = (property artifactsPath $basePath\artifacts)

task TeamCityReleaseNotes {
	if([String]::IsNullOrEmpty($env:TEAMCITY_VERSION)){
		throw "This task can only be executed on TeamCity"
	}

	$buildProperties = Load-TeamCityProperties ((Resolve-Path "$env:TEAMCITY_BUILD_PROPERTIES_FILE.xml").Path)
	$configProperties = Load-TeamCityProperties ($buildProperties["teamcity.configuration.properties.file"] + ".xml")
	$latestCommitFromRun = Get-TeamCityLastSuccessfulRunCommit $configProperties["teamcity.serverUrl"] $buildProperties["teamcity.auth.userId"] $buildProperties["teamcity.auth.password"] $buildProperties["teamcity.buildType.id"]
	if(!(Test-Path $artifactsPath)){
		md $artifactsPath
	}
	Get-CommitsFromGitLog $latestCommitFromRun $configProperties["build.vcs.number"] > "$artifactsPath\releasenotes.md"
}

function Get-CommitsFromGitLog($startCommit, $endCommit){
    $gitPath = $env:TEAMCITY_GIT_PATH
	$fs = New-Object -ComObject Scripting.FileSystemObject
    $git = $fs.GetFile("$gitPath").shortPath
 
    $cmd =  "$git log --pretty=format:""- %h | %ad | %an | %s%d"" --date=short $startCommit...$endCommit"

	pushd $basePath
	$result = $(Invoke-Expression "$cmd")
	popd
	$result
}

function Load-TeamCityProperties($file)
{
	$xml = New-Object System.Xml.XmlDocument
    $xml.XmlResolver = $null;
    $xml.Load($file);
    $properties = @{};
    foreach($entry in $xml.SelectNodes("//entry")){
        $key = $entry.key;
        $value = $entry.'#text';
        $properties[$key] = $value;
    }
	$properties
}

function Get-TeamCityLastSuccessfulRunCommit($serverUrl, $username, $password, $buildTypeId)
{
	$authString = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$username`:$password"))
    $url = "$serverUrl/app/rest/buildTypes/id:$buildTypeId/builds/status:SUCCESS" 
    $content = Invoke-WebRequest "$url" -Headers @{"Authorization" = "Basic $authString"} -UseBasicParsing
	(Select-Xml -Content "$content" -Xpath "/build/revisions/revision/@version").Node.Value
}