#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Uninstalls NextDNS client and removes certificate
.DESCRIPTION
    Removes NextDNS service, certificate, and temporary files
.NOTES
    Run this script with: irm https://raw.githubusercontent.com/refa3211/nextdns/main/uninstall.ps1 | iex
#>

[CmdletBinding()]
param(
    [switch]$Elevated,
    
    [string]$ReleaseUrl = "https://github.com/refa3211/nextdns/files/14027656/nextdns_1.41.0_windows_amd64_2.zip",
    
    [string]$ScriptUrl = "https://raw.githubusercontent.com/refa3211/nextdns/main/uninstall.ps1"
)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        # Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
        # From an elevated prompt or a shortcut:
        Start-Process powershell.exe -Verb RunAs -ArgumentList '-noprofile -noexit -command $ScriptUrl'
    }
    exit
}


$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Configuration
$config = @{
    ReleaseUrl = $ReleaseUrl
    TempPath = Join-Path $env:TEMP "nextdns_uninstall"
    OldPaths = @(
        (Join-Path $env:TEMP "nextdns"),
        (Join-Path $env:TEMP "cer.cer"),
        (Join-Path $env:TEMP "nextdns_cert.cer")
    )
}

function Write-Log($Message, $Level = "INFO") {
    $colors = @{ SUCCESS = "Green"; WARNING = "Yellow"; ERROR = "Red"; INFO = "White" }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message" -ForegroundColor $colors[$Level]
}

function Get-NextDNSExecutable {
    Write-Log "Obtaining NextDNS executable..."
    
    # Check existing installation
    $oldExe = Join-Path $config.OldPaths[0] "nextdns.exe"
    if (Test-Path $oldExe) { return $oldExe }
    
    # Download fresh copy
    try {
        $zipPath = "$($config.TempPath).zip"
        New-Item -ItemType Directory -Path $config.TempPath -Force | Out-Null
        Invoke-WebRequest -Uri $config.ReleaseUrl -OutFile $zipPath -UseBasicParsing
        Expand-Archive -Path $zipPath -DestinationPath $config.TempPath -Force
        Remove-Item $zipPath -Force
        
        $exePath = Join-Path $config.TempPath "nextdns.exe"
        if (Test-Path $exePath) { return $exePath }
        throw "Executable not found after extraction"
    }
    catch {
        Write-Log "Failed to obtain executable: $_" -Level "WARNING"
        return $null
    }
}

function Remove-NextDNSCertificate {
    Write-Log "Removing NextDNS certificates..."
    
    $certs = Get-ChildItem Cert:\LocalMachine\Root | Where-Object { 
        $_.Subject -like "*NextDNS*" -or $_.Issuer -like "*NextDNS*" 
    }
    
    if ($certs) {
        $certs | ForEach-Object { 
            Remove-Item $_.PSPath -Force
            Write-Log "Removed certificate: $($_.Thumbprint)" -Level "SUCCESS"
        }
    } else {
        Write-Log "No certificates found" -Level "WARNING"
    }
}

# Main execution
Write-Host "`n=== NextDNS Uninstaller ===" -ForegroundColor Cyan

try {
    # Uninstall service
    $exe = Get-NextDNSExecutable
    if ($exe) {
        Write-Log "Uninstalling NextDNS service..."
        $process = Start-Process -FilePath $exe -ArgumentList "uninstall" -PassThru -Wait -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Log "Service uninstalled successfully" -Level "SUCCESS"
        } else {
            Write-Log "Uninstall returned exit code: $($process.ExitCode)" -Level "WARNING"
        }
    }
    
    # Remove certificate
    Remove-NextDNSCertificate
    
    # Cleanup files
    Write-Log "Cleaning up temporary files..."
    $allPaths = $config.OldPaths + @($config.TempPath, "$($config.TempPath).zip")
    
    $allPaths | ForEach-Object {
        if (Test-Path $_) {
            Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "Removed: $_"
        }
    }
    
    Write-Log "Uninstallation completed successfully!" -Level "SUCCESS"
}
catch {
    Write-Log "Uninstallation failed: $_" -Level "ERROR"
    Read-Host "`nPress Enter to exit"; exit 1
}

Write-Host "`nNextDNS has been removed from your system." -ForegroundColor Cyan
start-sleep 5
exit
