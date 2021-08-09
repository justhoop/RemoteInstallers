<#
.SYNOPSIS
Install the latest version of Goto Meeting.
.DESCRIPTION
Finds the latest version of Goto Meeting available, then downloads, extracts and installs it.
.PARAMETER ComputerName
The name of the remote computer to install to.
.EXAMPLE
Install-GotoMeeting -ComputerName PC01
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
        Invoke-WebRequest "https://link.gotomeeting.com/latest-msi" -UseBasicParsing -OutFile "$env:TEMP\gtm.msi"
        Write-Host "Starting install"
        Start-Process msiexec -ArgumentList "/i $env:TEMP\gtm.msi /qn /norestart" -Wait -Verb runas
        Write-Host "Removing install file"
        Remove-Item -Path "$env:TEMP\gtm.msi"
    }
}