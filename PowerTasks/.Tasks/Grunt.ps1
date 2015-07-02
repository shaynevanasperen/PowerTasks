$script:gruntEnvironment = (property gruntEnvironment)

task Grunt {
	exec { grunt build --environment=$gruntEnvironment }
}