<#
.SYNOPSIS
Install the latest version of Autodesk DWG TrueView.
.DESCRIPTION
Uses a permalink to get the latest version of DWG TrueView and install it silently.
.PARAMETER ComputerName
The name of the remote computer to install to.
.EXAMPLE
Install-TrueView -ComputerName PC01
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
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        $d = Invoke-WebRequest 'https://www.autodesk.com/viewers' -UseBasicParsing
        $url = ($d.Links | Where-Object {$_.href -match "sfx.exe"})[0].href
        Write-Host "Downloading installer"
        Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\dwg.exe" -UseBasicParsing
        Write-Host "Extracting installer"
        Start-Process "$env:TEMP\dwg.exe" -ArgumentList "-suppresslaunch -d $env:TEMP" -Wait
        Write-Host "Starting install"
        #need to find the dir name instead of explicit def
        Start-Process msiexec -ArgumentList "/i $env:TEMP\DWGTrueView_2022_English_64bit_dlm\x64\dwgviewr\dwgviewr.msi /q ADSK_SETUP_EXE=1" -Wait -Verb runas
        Write-Host "Removing installer"
        #need to find the dir name instead of explicit def
        Remove-Item "$env:TEMP\DWGTrueView_2022_English_64bit_dlm" -recurse
        Remove-Item "$env:TEMP\dwg.exe"
    }
}