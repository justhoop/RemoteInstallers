<#
.SYNOPSIS
Install the latest version of Python.
.DESCRIPTION
Finds the latest version of Python available, then downloads, extracts and installs it.
.PARAMETER ComputerName
The name of the remote computer to install to.
.EXAMPLE
Install-Python -ComputerName PC01
#>

param([Parameter(mandatory = $true)][string]$ComputerName )

function Set-WinRMState ([string]$computer) {
    Write-Host "Checking for PSRemoting"
    if (-not (Test-WSMan -ComputerName $computer -ErrorAction SilentlyContinue)) {
        Write-Host "Enabling PSRemoting"
        psexec \\$Computer -s winrm.cmd quickconfig -q
        if (-not (Test-WSMan -ComputerName $computer -ErrorAction SilentlyContinue)) {
            Write-Host "Not able to enable PSRemoting"
            return $false
        }
        else {
            return $true
        }
    }
    else {
        return $true
    }
}

if (Set-WinRMState $ComputerName -eq $true) {
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Write-Host "Downloading latest installer"
        $Python = Invoke-WebRequest "https://www.python.org/downloads/" -UseBasicParsing
        $downloadfile = ($Python.links | Where-Object {$_.href -match ".exe"}).href
        Invoke-WebRequest -Uri $downloadfile -OutFile "$env:TEMP\python.exe"
        Write-Host "Starting install"
        Start-Process "$env:TEMP\python.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait -Verb runas
        Write-Host "Removing install file"
        Remove-Item -Path "$env:TEMP\python.exe"
    }
}