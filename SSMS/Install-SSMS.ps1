<#
.SYNOPSIS
Install the latest version of SQL Server Management Studio.
.DESCRIPTION
Uses a permalink to get the latest version of SQL Server Management Studio and install it silently.
.PARAMETER ComputerName
The name of the remote computer to install to.
.EXAMPLE
Install-SSMS -ComputerName PC01
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

if (Set-WinRMState $ComputerName) {
    Write-Host "Checking for install directory"
    if (-not (Test-Path "\\$ComputerName\c$\install")) {
        Write-Host "Creating install directory"
        new-item -Path "\\$ComputerName\c$\install" -ItemType "Directory"
    }
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Write-Host "Downloading installer"
        Invoke-WebRequest -Uri "https://aka.ms/ssmsfullsetup" -OutFile "c:\install\SSMS-Setup-ENU.exe" -UseBasicParsing
        Write-Host "Starting install"
        $sql = Start-Process -FilePath "C:\install\SSMS-Setup-ENU.exe" -ArgumentList "/install /quiet /norestart"-Verb runas -Wait -PassThru
        Write-Host "Exit code"$sql.ExitCode
        Write-Host "Removing installer"
        Remove-Item "c:\install\SSMS-Setup-ENU.exe"
    }
}