<#
.SYNOPSIS
Install the latest long-term version of QGIS.
.DESCRIPTION
Finds the latest long-term version of QGIS available, then downloads and installs it.
.PARAMETER ComputerName
The name of the remote computer to install to.
.EXAMPLE
Install-QGIS -ComputerName PC01
#>

param([Parameter(mandatory = $true)][string]$ComputerName)

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

if(Set-WinRMState $ComputerName){
    $qgis = ((Invoke-WebRequest "https://qgis.org/en/site/forusers/download.html" -UseBasicParsing).links | Where-Object {$_.href -match ".msi"})[1].href
    # Use the follwing line instead of the above if you want the latest version.
    # $qgis = ((Invoke-WebRequest "https://qgis.org/en/site/forusers/download.html" -UseBasicParsing).links | Where-Object {$_.href -match ".msi"})[0].href
    if($qgis -match ".msi"){
        Write-Host "Checking for install directory"
        if (-not (Test-Path "\\$ComputerName\c$\install")) {
            Write-Host "Creating install directory"
            new-item -Path "\\$ComputerName\c$\install" -ItemType "Directory"
        }
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Write-Host "Downloading installer"
            Invoke-WebRequest -Uri $args[0] -OutFile "c:\install\qgis.msi"
            Write-Host "Starting install"
            Start-Process msiexec -ArgumentList "/i c:\install\qgis.msi /qn" -Verb runas -Wait
            Write-Host "Removing installer"
            Remove-Item "c:\install\qgis.msi"
        }-ArgumentList $qgis
    }
    else {
        Write-Host "Error getting download url"
    }    
}