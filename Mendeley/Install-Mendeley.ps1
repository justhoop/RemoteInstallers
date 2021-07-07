<#
.SYNOPSIS
Install the latest version of Mendeley.
.DESCRIPTION
Uses a permalink to get the latest version of Mendeley and install it silently.
.PARAMETER ComputerName
The name of the remote computer to install to.
.EXAMPLE
Install-Mendeley -ComputerName PC01
#>

param([Parameter(mandatory = $true)][string]$ComputerName )
$url = "https://www.mendeley.com/autoupdates/installer/Windows-x86/stable-incoming"

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
    if ($changetempdir) {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Write-Host "Downloading installer"
            Invoke-WebRequest -Uri $args[0] -OutFile "c:\install\Mendeley.exe"
            Write-Host "Starting install"
            Start-Process -FilePath "c:\install\Mendeley.exe" -ArgumentList "/S" -Verb RunAs -Wait
            Write-Host "Removing installer"
            Remove-Item "c:\install\Mendeley.exe"
        } -ArgumentList $url
    }
    Start-Sleep -Seconds 5
}