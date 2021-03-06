<#
.SYNOPSIS
Install the latest version of GIMP photo editor.
.DESCRIPTION
Finds the latest version of GIMP available, then downloads and installs it.
.PARAMETER ComputerName
The name of the remote computer to install to.
.EXAMPLE
Install-GIMP -ComputerName PC01
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
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Write-Host "Downloading latest installer"
        $g = Invoke-WebRequest 'https://www.gimp.org/downloads/' -UseBasicParsing
        $url = "https:" + ($g.links | Where-Object {$_.title -match 'Download GIMP via HTTP'}).href.tostring()
        Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile "c:\install\gimp.exe"
        Write-Host "Starting install"
        Start-Process -FilePath "c:\install\gimp.exe" -ArgumentList "/VERYSILENT /NORESTART /RESTARTEXITCODE=3010 /SUPPRESSMSGBOXES /SP-" -Wait
        Start-Sleep -Seconds 5
        Write-Host "Removing install file"
        Remove-Item -Path "c:\install\gimp.exe"
    }
}