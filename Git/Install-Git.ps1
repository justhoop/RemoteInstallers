param(
    [Parameter(mandatory = $true)][string]$ComputerName,
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
    $git = Invoke-WebRequest -Uri 'https://git-scm.com/download/win' -UseBasicParsing
    if($git.StatusCode -eq 200){
        $download = ($git.Links | Where-Object {$_ -match "64-bit.exe"}).href
        Write-Host "Checking for install directory"
        if (-not (Test-Path "\\$ComputerName\c$\install")) {
            Write-Host "Creating install directory"
            new-item -Path "\\$ComputerName\c$\install" -ItemType "Directory"
        }
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $oldTMP = $env:TMP
            $oldTEMP = $env:TEMP
            $env:TMP = "C:\install\"
            $env:TEMP = "C:\install\"
            Invoke-WebRequest -Uri $args[0] -OutFile "c:\install\Git.exe"
            Start-Process -FilePath "c:\install\Git.exe" -ArgumentList "/VERYSILENT /NORESTART" -Verb runas -Wait
            Remove-Item "c:\install\Git.exe"
            $env:TMP = $oldTMP
            $env:TEMP = $oldTEMP
        }-ArgumentList $download
    }
    else {
        Write-Host "Error "$git.StatusCode
    }    
}