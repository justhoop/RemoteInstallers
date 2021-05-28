param([Parameter(mandatory = $true)][string]$ComputerName )
$url = "https://www.mendeley.com/autoupdates/installer/Windows-x86/stable-incoming"

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
    Write-Host "Starting install"
    if ($changetempdir) {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $oldTMP = $env:TMP
            $oldTEMP = $env:TEMP
            $env:TMP = "C:\install\"
            $env:TEMP = "C:\install\"
            Invoke-WebRequest -Uri $args[0] -OutFile "c:\install\Mendeley.exe"
            Start-Process -FilePath "c:\install\Mendeley.exe" -ArgumentList "/S" -Verb RunAs -Wait
            Remove-Item "c:\install\Mendeley.exe"
            $env:TMP = $oldTMP
            $env:TEMP = $oldTEMP
        } -ArgumentList $url
    }
    Start-Sleep -Seconds 5
}