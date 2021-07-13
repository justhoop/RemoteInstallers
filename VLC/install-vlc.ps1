<#
.SYNOPSIS
Install the latest version of the VLC media player.
.DESCRIPTION
Finds the latest version of the VLC media player available, then downloads and installs it.
.PARAMETER ComputerName
The name of the remote computer to install to.
.EXAMPLE
Install-VLC -ComputerName PC01
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

if(Set-WinRMState $ComputerName){
    $vlc = Invoke-WebRequest -Uri 'http://www.videolan.org/vlc/download-windows.html' -UseBasicParsing
    if($vlc.StatusCode -eq 200){
        $mirrorpage = "https:" + ($vlc.Links | Where-Object {$_ -match "win64.msi"}).href
        $mirrors = Invoke-WebRequest -Uri $mirrorpage -UseBasicParsing
        if($mirrors.StatusCode -eq 200){
            $download = ($mirrors.Links | Where-Object {$_ -match "win64.msi"}).href[0]
            Write-Host "Checking for install directory"
            if (-not (Test-Path "\\$ComputerName\c$\install")) {
                Write-Host "Creating install directory"
                new-item -Path "\\$ComputerName\c$\install" -ItemType "Directory"
            }
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                Write-Host "Downloading installer"
                Invoke-WebRequest -Uri $args[0] -OutFile "c:\install\vlc.msi"
                Write-Host "Starting install"
                Start-Process -FilePath msiexec -ArgumentList "/i c:\install\vlc.msi /q" -Verb runas -Wait
                Write-Host "Removing installer"
                Remove-Item "c:\install\vlc.msi"
            }-ArgumentList $download
        }
        else {
            Write-Host "Error "$mirrors.StatusCode
        }
    }
    else {
        Write-Host "Error "$vlc.StatusCode
    }    
}