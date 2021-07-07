<#
.SYNOPSIS
Install the latest version of Firefox.
.DESCRIPTION
Uses a permalink to get the latest 64 bit version of Firefox and install it silently.
.PARAMETER ComputerName
The name of the remote computer to install to.
.EXAMPLE
Install-Firefox -ComputerName PC01
#>

param([Parameter(mandatory = $true)][string]$ComputerName )

$url = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"
$arguments = "/s"

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
        Invoke-WebRequest -Uri $args[0] -OutFile "c:\install\firefox.exe" -UseBasicParsing
        Write-Host "Starting install"
        Start-Process -FilePath "c:\install\firefox.exe" -ArgumentList $args[1] -Verb runas -Wait
        Write-Host "Removing installer"
        Remove-Item "c:\install\firefox.exe"
    } -ArgumentList $url, $arguments
}