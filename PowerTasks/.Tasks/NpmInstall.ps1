task NpmInstall {
	"Restoring node packages"
	exec { npm install }
	exec { npm install -g grunt-cli }
}