<#
.SYNOPSIS
Install the latest version of R.
.DESCRIPTION
Finds the latest version of R available, then downloads and installs it.
.PARAMETER ComputerName
The name of the remote computer to install to.
.EXAMPLE
Install-R -ComputerName PC01
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
        $r = Invoke-WebRequest -Uri "https://cran.r-project.org/bin/windows/base/release.htm" -UseBasicParsing
        $filename = ($r.Content.split(";")[1]).split('"')[0].split('=')[1]
        Invoke-WebRequest -Uri "https://cran.r-project.org/bin/windows/base/$filename" -OutFile "$env:TEMP\$filename"
        Write-Host "Starting install"
        Start-Process "$env:TEMP\$filename" -ArgumentList "/SILENT" -verb runas -Wait
        Start-Sleep -Seconds 5
        Write-Host "Removing install file"
        Remove-Item -Path "$env:TEMP\$filename"
    }
}