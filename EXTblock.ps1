#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Blocks Chrome extension installation with whitelist
.DESCRIPTION
    Configures Windows registry to block all Chrome extensions except whitelisted ones
#>
[CmdletBinding()]
param(
    [switch]$Elevated,
    $URL = "iex (irm 'https://raw.githubusercontent.com/Mudales/nextdns/main/EXTblock.ps1')"
)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false) {
    if ($Elevated) {
        # Tried to elevate, did not work, aborting
        Write-Host "❌ Failed to elevate privileges. Please run PowerShell as Administrator manually." -ForegroundColor Red
        exit 1
    } else {
        # Running from pipeline (irm | iex) - auto-elevate
        Write-Host "🔐 Elevating privileges..." -ForegroundColor Yellow
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& {$URL}`""
        exit
    }
}

Write-Host "✅ Running with administrator privileges" -ForegroundColor Green
Write-Host "🔒 Configuring Chrome extension policy..." -ForegroundColor Cyan

# Registry path for Chrome policies
$registryPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"

# Create registry keys if they don't exist
if (-not (Test-Path $registryPath)) {
    Write-Host "📁 Creating Chrome policy registry path..." -ForegroundColor Yellow
    New-Item -Path $registryPath -Force | Out-Null
}

# Create ExtensionInstallBlocklist key
$blocklistPath = "$registryPath\ExtensionInstallBlocklist"
if (-not (Test-Path $blocklistPath)) {
    New-Item -Path $blocklistPath -Force | Out-Null
}

# Create ExtensionInstallAllowlist key
$allowlistPath = "$registryPath\ExtensionInstallAllowlist"
if (-not (Test-Path $allowlistPath)) {
    New-Item -Path $allowlistPath -Force | Out-Null
}

# Block all extensions
Write-Host "🚫 Setting blocklist to block all extensions..." -ForegroundColor Yellow
Set-ItemProperty -Path $blocklistPath -Name "1" -Value "*" -Type String

# Whitelist specific extensions
Write-Host "✅ Adding whitelisted extensions..." -ForegroundColor Yellow
$whitelistedExtensions = @(
    "efaidnbmnnnibpcajpcglclefindmkaj",  # Adobe Acrobat
    "aapbdbdomjkkjkaonfhkkikfgjllcleb",  # Google Translate
    "kbfnbcaeplbcioakkpcpgfkobkghlhen",  # Google Docs Offline
    "ddkjiahejlhfcafbddmgiahcphecmpfh"   # Google Drive
)

$index = 1
foreach ($extension in $whitelistedExtensions) {
    Set-ItemProperty -Path $allowlistPath -Name "$index" -Value $extension -Type String
    Write-Host "  ➕ Added: $extension" -ForegroundColor Gray
    $index++
}

Write-Host ""
Write-Host "✅ Chrome extension policy configured successfully!" -ForegroundColor Green
Write-Host "📝 Registry location: $registryPath" -ForegroundColor Cyan
Write-Host "🔄 Please restart Chrome and verify at chrome://policy" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
