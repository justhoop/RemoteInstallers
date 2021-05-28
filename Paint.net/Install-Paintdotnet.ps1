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
        $pdn = Invoke-WebRequest https://www.dotpdn.com/downloads/pdn.html
        $downloadfile = ($pdn.links | Where-Object {$_.href -match ".zip"})[0].href.replace('..','')
        Invoke-WebRequest -Uri " https://www.dotpdn.com$downloadfile" -OutFile c:\install\pdn.zip
        Expand-Archive -literalpath "C:\install\pdn.zip" -DestinationPath "C:\install\pdn"
        $installer = Get-ChildItem pdn\*.exe
        Start-Process $installer -ArgumentList "/auto" -verb runas -Wait
        Start-Sleep -Seconds 5
        Write-Host "Removing install files"
        Remove-Item -Path "c:\install\pdn" -Recurse
        Remove-Item -Path "c:\install\pdn.zip"
    }
}