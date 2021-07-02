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
    $rtools = Invoke-WebRequest -Uri 'https://cran.r-project.org/bin/windows/Rtools/' -UseBasicParsing
    if($rtools.StatusCode -eq 200){
        $download = "https://cran.r-project.org/bin/windows/Rtools/" + ($rtools.Links | Where-Object {$_ -match "64.exe"}).href
        Write-Host "Checking for install directory"
        if (-not (Test-Path "\\$ComputerName\c$\install")) {
            Write-Host "Creating install directory"
            new-item -Path "\\$ComputerName\c$\install" -ItemType "Directory"
        }
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Write-Host "Downloading installer"
            Invoke-WebRequest -Uri $args[0] -OutFile "c:\install\rtools.exe"
            Write-Host "Starting install"
            Start-Process -FilePath "c:\install\rtools.exe" -ArgumentList "/VERYSILENT" -Verb runas -Wait
            Write-Host "Removing installer"
            Remove-Item "c:\install\rtools.exe"
        }-ArgumentList $download
    }
    else {
        Write-Host "Error "$rtools.StatusCode
    }    
}