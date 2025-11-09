<#
.SYNOPSIS
    Uninstalls NextDNS client and removes certificate
.DESCRIPTION
    Removes NextDNS service, certificate, and temporary files
.NOTES
    Run this script with: irm https://raw.githubusercontent.com/Mudales/nextdns/main/uninstall.ps1 | iex
#>

param(
    [switch]$Elevated,
    $ReleaseUrl = "https://github.com/Mudales/nextdns/files/14027656/nextdns_1.41.0_windows_amd64_2.zip",
    $URL = "irm https://raw.githubusercontent.com/Mudales/nextdns/main/uninstall.ps1 | iex"
)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false) {
    if ($Elevated) {
        # tried to elevate, did not work, aborting
    } elseif ($myinvocation.MyCommand.Definition) {
        # Running from file
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    } else {
        # Running from pipeline (irm | iex)
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-noprofile -noexit -command $URL"
    }
    Start-Sleep 2
    exit
}

'running with full privileges'

# Script configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$tempPath = Join-Path $env:TEMP "nextdns_uninstall"
$zipPath = Join-Path $env:TEMP "nextdns_uninstall.zip"
$oldTempPath = Join-Path $env:TEMP "nextdns"
$oldCertPath = Join-Path $env:TEMP "cer.cer"
$oldCertPath2 = Join-Path $env:TEMP "nextdns_cert.cer"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Get-NextDNSExecutable {
    <#
    .SYNOPSIS
        Gets NextDNS executable for uninstallation
    #>
    Write-Log "Obtaining NextDNS executable..."
    
    # Check existing installation
    $oldExe = Join-Path $oldTempPath "nextdns.exe"
    if (Test-Path $oldExe) {
        Write-Log "Found existing executable"
        return $oldExe
    }
    
    # Download fresh copy
    try {
        if (-not (Test-Path $tempPath)) {
            New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
        }
        
        Write-Log "Downloading NextDNS..."
        Invoke-WebRequest -Uri $ReleaseUrl -OutFile $zipPath -UseBasicParsing
        
        Write-Log "Extracting archive..."
        Expand-Archive -Path $zipPath -DestinationPath $tempPath -Force
        
        $exePath = Join-Path $tempPath "nextdns.exe"
        if (Test-Path $exePath) {
            Write-Log "Download completed"
            return $exePath
        }
        throw "Executable not found after extraction"
    }
    catch {
        Write-Log "Failed to obtain executable: $_" -Level "WARNING"
        return $null
    }
}

function Remove-NextDNSCertificate {
    <#
    .SYNOPSIS
        Removes NextDNS root certificate
    #>
    try {
        Write-Log "Removing NextDNS certificates..."
        
        $certs = Get-ChildItem Cert:\LocalMachine\Root | Where-Object { 
            $_.Subject -like "*NextDNS*" -or $_.Issuer -like "*NextDNS*" 
        }
        
        if ($certs) {
            foreach ($cert in $certs) {
                Remove-Item $cert.PSPath -Force
                Write-Log "Removed certificate: $($cert.Thumbprint)" -Level "SUCCESS"
            }
        } else {
            Write-Log "No certificates found" -Level "WARNING"
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to remove certificate: $_" -Level "ERROR"
        return $false
    }
}

function Uninstall-NextDNS {
    try {
        Write-Host "`n=== NextDNS Uninstaller ===" -ForegroundColor Cyan
        
        # Get the executable
        $exe = Get-NextDNSExecutable
        
        if ($exe) {
            # Uninstall NextDNS service
            Write-Log "Uninstalling NextDNS service..."
            $process = Start-Process -FilePath $exe -ArgumentList "uninstall" -PassThru -Wait -NoNewWindow
            
            if ($process.ExitCode -eq 0) {
                Write-Log "Service uninstalled successfully" -Level "SUCCESS"
            } else {
                Write-Log "Uninstall returned exit code: $($process.ExitCode)" -Level "WARNING"
            }
        } else {
            Write-Log "Continuing with certificate and file cleanup..." -Level "WARNING"
        }
        
        # Remove certificate
        Write-Log "Removing NextDNS certificate..."
        Remove-NextDNSCertificate | Out-Null
        
        # Cleanup files
        Write-Log "Cleaning up temporary files..."
        
        $pathsToClean = @(
            $tempPath,
            $oldTempPath,
            $zipPath,
            $oldCertPath,
            $oldCertPath2
        )
        
        foreach ($path in $pathsToClean) {
            if (Test-Path $path) {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Removed: $path"
            }
        }
        
        Write-Log "Uninstallation completed successfully!" -Level "SUCCESS"
        Write-Host "`nNextDNS has been removed from your system." -ForegroundColor Cyan
        
    }
    catch {
        Write-Log "Uninstallation failed: $($_.Exception.Message)" -Level "ERROR"
        Start-Sleep 3
        exit 1
    }
}

# Main execution
Write-Log "Starting NextDNS uninstallation process..."
Uninstall-NextDNS
Write-Log "Uninstallation process completed"
Start-Sleep 3
exit
