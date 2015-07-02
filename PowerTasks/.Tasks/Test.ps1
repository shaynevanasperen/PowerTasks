$script:buildsPath = (property buildsPath $basePath\builds)
$script:config = (property config "Release")
$script:browserStackUser = (property browserStackUser "")
$script:browserStackKey = (property browserStackKey "")
$script:browserStackProxyHost = (property browserStackProxyHost "")
$script:browserStackProxyPort = (property browserStackProxyPort 0)

task Test {
	New-Item $buildsPath -Type directory -Force | Out-Null
	foreach ($projectTest in $projectTests) {
		foreach ($type in $projectTest.Types) {
			switch ($type.Id) {
				Machine.Specifications {
					if($type.Number -ge 90) {
						$mspecRunnerPath = Get-RequiredPackagePath Machine.Specifications.Runner.Console $basePath\.nuget
					}
					else {
						$mspecRunnerPath = $type.Path
					}
					$runnerExecutable = "$mspecRunnerPath\tools\mspec-clr4.exe"
					exec { & $runnerExecutable --html $buildsPath $basePath\$($projectTest.Path)\bin\$config\$($projectTest.Name).dll }
					continue
				}
				NUnit {
					$nunitRunnerPath = Get-RequiredPackagePath NUnit.Runners $basePath\.nuget
					$runnerExecutable = "$nunitRunnerPath\tools\nunit-console.exe"
					exec { & $runnerExecutable /xml:$buildsPath\nunit.xml /nologo $basePath\$($projectTest.Path)\bin\$config\$($projectTest.Name).dll }
					continue
				}
				SpecFlow {
					$nunitRunnerPath = Get-RequiredPackagePath NUnit.Runners $basePath\.nuget
					$runnerExecutable = "$nunitRunnerPath\tools\nunit-console.exe"
					$specflowExecutable = "$($type.Path)\tools\specflow.exe"
					$configurations = @(Get-SolutionConfigurations $basePath\$projectName.sln) | Where { (Get-IsLocalTest $_ $basePath\$($projectTest.Path)) -ne $true }
					if (!$browserStackUser) {
						$browserStackUser = Read-Host "Please enter your BrowserStack user"
					}
					if (!$browserStackKey) {
						$browserStackKey = Read-Host "Please enter your BrowserStack key"
					}
					$configurations | foreach {
						Set-ConfigValue browserStackUser $browserStackUser (Resolve-Path $basePath\$($projectTest.Path)\bin\$_\$($projectTest.Name).dll.config)
						Set-ConfigValue browserStackKey $browserStackKey (Resolve-Path $basePath\$($projectTest.Path)\bin\$_\$($projectTest.Name).dll.config)
					}
					$args = $browserStackKey, "-forcelocal"
							
					if ($browserStackProxyHost -and $browserStackProxyPort) {
						$args += "-proxyHost $browserStackProxyHost"
						$args += "-proxyPort $browserStackProxyPort"
							
						$configurations | foreach {
							Set-ConfigValue proxy "$($browserStackProxyHost):$browserStackProxyPort" (Resolve-Path $basePath\$($projectTest.Path)\bin\$_\$($projectTest.Name).dll.config)
						}
					}
					try {
						Start-Process "$basePath\$($projectTest.Path)\bin\$($configurations[0])\BrowserStackLocal.exe" $args
						
						$configurations | foreach {
							Start-Job -InitializationScript {
								function exec([scriptblock]$command) {
									. $command
									if ($LastExitCode -ne 0) {
										throw "Command {$command} exited with code $LastExitCode."
									}
								}
							} -ScriptBlock {
								param($runnerExecutable, $specflowExecutable, $buildsPath, $configuration, $basePath, $projectTest)
								exec { & $runnerExecutable /labels /out=$buildsPath\nunit_$configuration.txt /xml:$buildsPath\nunit_$configuration.xml /nologo /config:$configuration $basePath\$($projectTest.Path)\bin\$configuration\$($projectTest.Name).dll }
								exec { & $specflowExecutable nunitexecutionreport $basePath\$($projectTest.Path)\$($projectTest.File) /out:$buildsPath\specresult_$configuration.html /xmlTestResult:$buildsPath\nunit_$configuration.xml /testOutput:$buildsPath\nunit_$configuration.txt }
							} -ArgumentList (Resolve-Path $runnerExecutable), (Resolve-Path $specflowExecutable), (Resolve-Path $buildsPath), $_, (Resolve-Path $basePath), $projectTest
						}
						Get-Job | Wait-Job
						Get-Job | Receive-Job
					}
					finally {
						New-SpecFlowReport $configurations $buildsPath
						Stop-Process -processname "BrowserStackLocal"
					}
					continue
				} 
				Chutzpah {
					exec { & $($type.RunnerExecutable) $basePath\$($projectTest.Path)\js\runner.js }
					continue
				}
			}
		}
	}
}

function script:New-SpecFlowReport($configurations, $buildsPath) {
	$template = [IO.File]::ReadAllText("$PSScriptRoot\specflow_report_template.html");
	
	$links = "";
	$configurations | foreach {
		$links = $links + "<li data-configuration='$_'>$_</li>"
	}
	
	$output = $template -replace "%links%", $links
	
	New-Item $buildsPath\specresult.html -Type file -Force -Value $output | Out-Null
}

function script:Set-ConfigValue($key, $value, $path) {
	$xml = [xml](Get-Content $path)
	$nodePath = "//configuration/appSettings/add[@key='$key']"
	$xml.SelectSingleNode($nodePath).value = $value
	$xml.Save($path)
}