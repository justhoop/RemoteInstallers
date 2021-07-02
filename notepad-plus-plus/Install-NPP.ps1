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

function Install-NPP {
    param (
        [string]$computername
    )
    if (Set-WinRMState -computer $computername) {
        Write-Host "Checking for install directory"
        if (-not (Test-Path "\\$ComputerName\c$\install")) {
            Write-Host "Creating install directory"
            new-item -Path "\\$ComputerName\c$\install" -ItemType "Directory"
        }
        $np = Invoke-WebRequest "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/" -UseBasicParsing
        if ($np.statuscode -eq 200) {
            $downloads = $np.links | Where-Object {$_.outerHTML -match "Installer.x64.exe"}
            $downloadurl = "https://github.com" + $downloads[0].href
            Invoke-Command -ComputerName $ComputerName -ScriptBlock{
                Write-Host "Downloading installer"
                Invoke-WebRequest -Uri $Args[0] -OutFile "C:\install\npp.exe"
                Write-Host "Starting install"
                Start-Process "C:\install\npp.exe" -ArgumentList "/S" -Verb Runas -Wait
                Write-Host "Removing installer"
                Remove-Item -Path "C:\install\npp.exe"
            } -ArgumentList $downloadurl
        }
    }   
}

Install-NPP -computername $computername