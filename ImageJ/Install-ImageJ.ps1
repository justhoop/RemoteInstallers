<#
.SYNOPSIS
Install the latest version of ImageJ.
.DESCRIPTION
Finds the latest version of ImageJ available, then downloads, extracts and installs it.
.PARAMETER ComputerName
The name of the remote computer to install to.
.EXAMPLE
Install-ImageJ -ComputerName PC01
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
        $ImageJ = Invoke-WebRequest "https://imagej.nih.gov/ij/download.html" -UseBasicParsing
        $downloadfile = ($ImageJ.links | Where-Object {$_.href -match "-win-"}).href
        Invoke-WebRequest -Uri $downloadfile -OutFile c:\install\imagej.zip
        Write-Host "Starting install"
        Expand-Archive -literalpath "C:\install\imagej.zip" -DestinationPath "C:\"
        New-Item -ItemType SymbolicLink -Path "C:\Users\Public\Desktop" -Name "ImageJ.lnk" -Value "C:\ImageJ\ImageJ.exe"
        Write-Host "Removing install file"
        Remove-Item -Path "c:\install\imagej.zip"
    }
}