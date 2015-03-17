$script:gruntEnvironment = (property gruntEnvironment)

task Grunt NpmInstall, {
	exec { grunt build --environment=$gruntEnvironment }
}