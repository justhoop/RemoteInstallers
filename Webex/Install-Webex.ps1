<#
.SYNOPSIS
Install the latest version of Cisco Webex.
.DESCRIPTION
Uses a permalink to get the latest 64 bit version of Webex and install it silently.
.PARAMETER ComputerName
The name of the remote computer to install to.
.EXAMPLE
Install-Webex -ComputerName PC01
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
    Write-Host "Checking for install directory"
    if (-not (Test-Path "\\$ComputerName\c$\install")) {
        Write-Host "Creating install directory"
        new-item -Path "\\$ComputerName\c$\install" -ItemType "Directory"
    }
    Write-Host "Starting install"
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Write-Host "Downloading installer"
        Invoke-WebRequest -Uri "https://binaries.webex.com/WebexTeamsDesktop-Windows-Gold/Webex.msi" -OutFile "c:\install\Webex.msi" -UseBasicParsing
        Write-Host "Starting install"
        Start-Process -FilePath msiexec -ArgumentList "/i c:\install\Webex.msi /qn ACCEPT_EULA=TRUE ALLUSERS=1" -Wait
        Write-Host "Removing installer"
        Remove-Item "c:\install\Webex.msi"
    }
}