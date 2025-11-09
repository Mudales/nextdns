#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Downloads and installs NextDNS client with certificate
.DESCRIPTION
    Automates the download, extraction, and installation of NextDNS client
    including certificate installation for HTTPS DNS-over-HTTPS
#>

[CmdletBinding()]
param([switch]$Elevated)

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
Start-Process powershell.exe -Verb RunAs -ArgumentList '-noprofile -noexit -command "irm https://raw.githubusercontent.com/Mudales/nextdns/main/get.ps1 | iex"'
    }
    exit
}

'running with full privileges'

# Script configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'  # Speeds up Invoke-WebRequest

$releaseUrl = "https://github.com/refa3211/nextdns/files/14027656/nextdns_1.41.0_windows_amd64_2.zip"
$certUrl = "https://nextdns.io/ca"
$tempPath = Join-Path $env:TEMP "nextdns"
$zipPath = Join-Path $env:TEMP "nextdns.zip"
$certPath = Join-Path $env:TEMP "nextdns_cert.cer"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Install-NextDNSCertificate {
    <#
    .SYNOPSIS
        Downloads and installs NextDNS root certificate
    #>
    try {
        Write-Log "Downloading NextDNS certificate..."
        Invoke-WebRequest -Uri $certUrl -OutFile $certPath -UseBasicParsing
        
        Write-Log "Installing certificate to Trusted Root store..."
        $cert = Import-Certificate -FilePath $certPath -CertStoreLocation 'Cert:\LocalMachine\Root' -ErrorAction Stop
        
        Write-Log "Certificate installed successfully: $($cert.Thumbprint)" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Failed to install certificate: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
    finally {
        # Clean up certificate file
        if (Test-Path $certPath) {
            Remove-Item -Path $certPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Install-NextDNS {
    try {
        # Create temp directory if it doesn't exist
        if (-not (Test-Path $tempPath)) {
            New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
        }

        # Download the ZIP file
        Write-Log "Downloading NextDNS from GitHub..."
        Invoke-WebRequest -Uri $releaseUrl -OutFile $zipPath -UseBasicParsing
        Write-Log "Download completed successfully"

        # Extract the ZIP file
        Write-Log "Extracting archive..."
        Expand-Archive -Path $zipPath -DestinationPath $tempPath -Force
        Write-Log "Extraction completed"

        # Verify the executable exists
        $exePath = Join-Path $tempPath "nextdns.exe"
        $configPath = Join-Path $tempPath "config"
        
        if (-not (Test-Path $exePath)) {
            throw "NextDNS executable not found at: $exePath"
        }

        # Check if config file exists
        if (-not (Test-Path $configPath)) {
            Write-Log "Warning: Config file not found at $configPath" -Level "WARNING"
        }

        # Install certificate first
        Write-Log "Installing NextDNS certificate..."
        Install-NextDNSCertificate | Out-Null

        # Install NextDNS service
        Write-Log "Installing NextDNS service..."
        $installArgs = "install -config-file `"$configPath`""
        
        $process = Start-Process -FilePath $exePath -ArgumentList $installArgs -Verb RunAs -PassThru -Wait
        
        if ($process.ExitCode -eq 0) {
            Write-Log "NextDNS installed successfully!" -Level "SUCCESS"
        } else {
            throw "NextDNS installation failed with exit code: $($process.ExitCode)"
        }

    }
    catch {
        Write-Log "Installation failed: $($_.Exception.Message)" -Level "ERROR"
        exit 1
    }
    finally {
        # Cleanup
        Write-Log "Cleaning up temporary files..."
        if (Test-Path $zipPath) {
            Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $tempPath) {
            Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Main execution
Write-Log "Starting NextDNS installation process..."
Install-NextDNS
Write-Log "Installation process completed"
