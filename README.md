# PowerTasks

A PowerShell task runner based on [Invoke-Build](https://github.com/nightroman/Invoke-Build).
_Invoke-Build is a build and test automation tool which invokes tasks defined in PowerShell
scripts. It is similar to [psake](https://github.com/psake/psake) but arguably easier to use
and more powerful._

PowerTasks was created in order to remove the boilerplate code from your build scripts. It's
called PowerTasks instead of PowerBuild because it's a generic task runner rather than just
a build runner. The inspiration for creating a task runner based on PowerShell was born from
some of the ideas talked about in these blog posts:

* [A less terrible .NET project build with NuGet](http://haacked.com/archive/2014/04/15/nuget-build-dependencies/)
* [Creating A Sane Build Process](http://haacked.com/archive/2004/08/26/creating-a-sane-build-process.aspx/)
* [Building .NET projects is a world of pain and here’s how we should solve it](http://blog.maartenballiauw.be/post/2014/04/11/Building-NET-projects-is-a-world-of-pain-and-heres-how-we-should-solve-it.aspx)
* [Building future .NET projects is quite pleasant](http://blog.maartenballiauw.be/post/2014/12/19/Building-future-NET-projects-is-quite-pleasant.aspx)

By having your build scripts be simple shell scripts checked in with your source code, you
can execute a build on your developer machine exactly as it does on your continuous integration
server. This also means that your continuous integration server doesn't need to be very full
featured - it only needs to be able to execute a shell script - and that also allows you to
switch between different continuous integration servers easily.

PowerTasks is designed to work without needing to check your NuGet packages into source control.
To enable this, a Windows batch file is added to your solution folder when you install PowerTasks.
The purpose of this batch file (pt.bat) is to:

1. Download NuGet.exe if it isn't already in your `PATH` or in in the ".nuget" folder alongside your
solution file
2. Execute NuGet package restore for the solution
3. Dot source the provided common helper functions in "Functions.ps1" for use in your tasks
4. Set the current location to the location of your startup project (the project you should
install PowerTasks into)
5. Set a $basePath variable which is the relative path from your startup project to the solution
folder
6. Set a $projectName variable which is the name of your startup project
7. Set a $packagesPath variable which is the relative path from your startup project to the
NuGet packages folder
8. Set a $invokeBuildPath variable which is the relative path from your startup project to the
Invoke-Build package which PowerTasks depends on
9. Execute Invoke-Build on the ".Tasks.ps1" file that was added to your startup project when you
installed PowerTasks, passing all command line arguments along to Invoke-Build
10. Propagate the exit code from your task(s) back to the shell

_This batch file should not be hand-edited and will be replaced when updating PowerTasks to
a newer version._

## Installation
You can install PowerTasks from [NuGet](https://www.nuget.org/packages/PowerTasks/). The
PowerTasks package and its plugins have been defined at developer dependencies so that if you
are building a NuGet package from your project they don't get added as dependencies in your
NuGet package.

## Writing your own tasks
Upon installing PowerTasks into your startup project, a PowerShell script file named ".Tasks.ps1"
is included in the project. It has been prefixed with a dot so that it always appears as the
first file in your project. This is where you should define your tasks. By default, this file
contains a single line of script which is a function call to include "plugin" scripts, which
will be explained later in this readme. If you are not using any plugins, you can go ahead
and remove this line, but it will do no harm to leave it there.

For help defining your own tasks, refer to the documentation of
[Invoke-Build](https://github.com/nightroman/Invoke-Build).

## Plugins
To further reduce the amount of boilerplate code in your build scripts, a set of tasks have
been defined as "plugins" for PowerTasks. These are available as separate
[NuGet packages](https://www.nuget.org/packages?q=powertasks.plugins).

When you have one or more of these plugin packages installed in your project, they get loaded
via dot sourcing by invoking a function named "Include-PluginScripts" in your ".Tasks.ps1"
file. This is done by convention, where the only requirement of a "plugin" is that its package
id starts with "PowerTasks.Plugins.*" and that it deploys the script(s) that are intended
to be dot sourced as files with an extension of ".ps1" in a folder named "scripts".

If you find yourself writing the same tasks over and over again, you should consider creating
a plugin package of your own. You are free to do this as you please and if you feel that the
task is very generic and potentially useful to others, then you should consider hosting it on
NuGet for others to use.

If you do choose to host a plugin package on NuGet, then it is up to you whether you host
the code in your own source code repository, or submit a pull request to get it into this
repository. Otherwise, you can create your own plugin packages that are specific to your
use case or that contain intellectual property which you would like to keep private, in
which case you would host the packages in a private NuGet feed.