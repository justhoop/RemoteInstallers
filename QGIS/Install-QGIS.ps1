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
    $qgis = ((Invoke-WebRequest "https://qgis.org/en/site/forusers/download.html" -UseBasicParsing).links | Where-Object {$_.href -match ".msi"})[1].href
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