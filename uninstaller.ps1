#Requires -RunAsAdministrator

# Define the installation path
$FilePath = "$env:TEMP\nextdns"

# Function to remove the installed certificate
function RemoveCertificate {
    try {
        $cert = Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object { $_.Subject -like "*NextDNS*" }
        if ($cert) {
            Remove-Item -Path $cert.PSPath -Force
            Write-Output " certificate removed successfully."
        } else {
            Write-Output " certificate not found."
        }
    } catch {
        Write-Output "Failed to remove certificate: $_"
    }
}

# Uninstall NextDNS
try {
    Start-Process -FilePath "$FilePath\nextdns.exe" -ArgumentList "uninstall" -Verb RunAs -Wait
    Write-Output " uninstalled successfully."
} catch {
    Write-Error "Error uninstalling : $_"
}

# Remove the certificate
RemoveCertificate

# Remove the downloaded files
try {
    Remove-Item -Path $FilePath -Recurse -Force
    Remove-Item -Path "$env:TEMP\cer.cer" -Force -ErrorAction SilentlyContinue
    Write-Output "Temporary files removed successfully."
} catch {
    Write-Error "Error removing temporary files: $_"
}

Write-Output "Uninstallation process completed."
