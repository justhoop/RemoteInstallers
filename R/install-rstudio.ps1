<#
.SYNOPSIS
Install the latest version of RStudio.
.DESCRIPTION
Finds the latest version of RStudio available, then downloads and installs it.
.PARAMETER ComputerName
The name of the remote computer to install to.
.EXAMPLE
Install-RStudio -ComputerName PC01
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
    if (Test-Path "\\$ComputerName\c$\install\$sourcefile") {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Write-Host "Downloading latest installer"
            $rstudio = Invoke-WebRequest -uri "https://www.rstudio.com/products/rstudio/download/" -UseBasicParsing
            $downloadfile =  (($rstudio.Links | Where-Object {$_.href -match 'https://download1.rstudio.org/desktop/windows/'})[1]).href
            Invoke-WebRequest -Uri $downloadfile -OutFile "c:\install\rstudio.exe"
            Start-Process "c:\install\rstudio.exe" -ArgumentList "/S" -verb runas -Wait
            Start-Sleep -Seconds 5
            Write-Host "Removing install file"
            Remove-Item -Path "c:\install\rstudio.exe"
        }
    }
}