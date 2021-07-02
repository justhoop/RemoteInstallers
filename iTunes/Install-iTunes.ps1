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
    Write-Host "Checking for install directory"
    if (-not (Test-Path "\\$ComputerName\c$\install")) {
        Write-Host "Creating install directory"
        new-item -Path "\\$ComputerName\c$\install" -ItemType "Directory"
    }
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Write-Host "Downloading latest installer"
        Invoke-WebRequest -Uri "https://www.apple.com/itunes/download/win64" -OutFile "c:\install\itunes.exe" -UseBasicParsing
        Write-Host "Starting install"
        Start-Process -FilePath "c:\install\itunes.exe" -ArgumentList "/qn /norestart" -Verb runas -Wait
        Write-Host "Removing install file"
        Remove-Item "c:\install\itunes.exe"
    }-ArgumentList $download  
}