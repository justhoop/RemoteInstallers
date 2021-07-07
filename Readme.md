# Remote Installers

I needed a way to install certain software packages on remote computers. The scripts use Invoke-Command to remotely download and install the software silently. The scripts assume you have [psExec](https://docs.microsoft.com/en-us/sysinternals/downloads/psexec) somewhere in your path to enable psremoting if it isn't already.