<#
.SYNOPSIS
Install the latest version of Git source control.
.DESCRIPTION
Finds the latest version of Git available, then downloads and installs it.
.PARAMETER ComputerName
The name of the remote computer to install to.
.EXAMPLE
Install-Git -ComputerName PC01
#>

param(
    [Parameter(mandatory = $true)][string]$ComputerName
    )

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
    $git = Invoke-WebRequest -Uri 'https://git-scm.com/download/win' -UseBasicParsing
    if($git.StatusCode -eq 200){
        $download = ($git.Links | Where-Object {$_ -match "64-bit.exe"}).href
        Write-Host "Checking for install directory"
        if (-not (Test-Path "\\$ComputerName\c$\install")) {
            Write-Host "Creating install directory"
            new-item -Path "\\$ComputerName\c$\install" -ItemType "Directory"
        }
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Write-Host "Downloading installer"
            Invoke-WebRequest -Uri $args[0] -OutFile "c:\install\Git.exe"
            Write-Host "Starting install"
            Start-Process -FilePath "c:\install\Git.exe" -ArgumentList "/VERYSILENT /NORESTART" -Verb runas -Wait
            Write-Host "Removing installer"
            Remove-Item "c:\install\Git.exe"
        }-ArgumentList $download
    }
    else {
        Write-Host "Error "$git.StatusCode
    }    
}