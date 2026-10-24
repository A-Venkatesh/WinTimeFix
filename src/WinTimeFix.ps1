[CmdletBinding()]
param(
    [string[]]$NtpServers = @(
        "time.google.com,0x9",
        "pool.ntp.org,0x9",
        "time.cloudflare.com,0x9",
        "time.windows.com,0x9"
    ),
    [switch]$ForceHttps,
    [switch]$NonInteractive
)

<#
.SYNOPSIS
    WinTimeFix - Windows Time Synchronization & Clock Repair Utility
.DESCRIPTION
    A lightweight, robust tool to resolve Windows 10/11 time synchronization failures,
    including 15-hour phase skew rejection, Secure Time Seeding bugs, corrupted service
    registrations, and blocked UDP 123 networks.
.LINK
    https://github.com/A-Venkatesh/WinTimeFix
#>

# Ensure script is running with elevated Administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] Administrator privileges required. Elevating..." -ForegroundColor Yellow
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($ForceHttps) { $argList += " -ForceHttps" }
    if ($NonInteractive) { $argList += " -NonInteractive" }
    Start-Process powershell.exe -ArgumentList $argList -Verb RunAs
    exit
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   WinTimeFix - Windows Time Sync Repair Tool            " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

function Sync-ViaHttps {
    Write-Host "[HTTPS Fallback] Attempting time sync via HTTPS (Port 443)..." -ForegroundColor Cyan
    $timeSources = @(
        "https://www.google.com",
        "https://www.cloudflare.com",
        "https://www.microsoft.com"
    )

    $synced = $false
    foreach ($source in $timeSources) {
        try {
            Write-Host "  -> Querying $source..." -ForegroundColor Gray
            $response = Invoke-WebRequest -Uri $source -Method Head -UseBasicParsing -TimeoutSec 5
            if ($response.Headers['Date']) {
                $rawDate = $response.Headers['Date']
                $utcTime = [DateTime]::ParseExact($rawDate, 'ddd, dd MMM yyyy HH:mm:ss \G\M\T', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal)
                Set-Date -Date $utcTime.ToLocalTime()
                Write-Host "[SUCCESS] System clock set to: $((Get-Date).ToString())" -ForegroundColor Green
                $synced = $true
                break
            }
        } catch {
            Write-Host "  [!] Failed to reach $($source): $($_.Exception.Message)" -ForegroundColor DarkGray
        }
    }

    if (-not $synced) {
        Write-Host "[ERROR] Could not synchronize time via HTTPS sources." -ForegroundColor Red
    }
}

if ($ForceHttps) {
    Sync-ViaHttps
} else {
    Write-Host "[1/6] Stopping Windows Time service..." -ForegroundColor Yellow
    Stop-Service -Name w32time -Force -ErrorAction SilentlyContinue

    Write-Host "[2/6] Resetting and re-registering W32Time service..." -ForegroundColor Yellow
    & w32tm /unregister
    Start-Sleep -Seconds 1
    & w32tm /register
    Start-Sleep -Seconds 1

    Write-Host "[3/6] Setting W32Time startup type to Automatic..." -ForegroundColor Yellow
    Set-Service -Name w32time -StartupType Automatic

    Write-Host "[4/6] Applying registry fixes (phase limits & SSL seeding bug)..." -ForegroundColor Yellow
    # Remove 15-hour max phase skew limitation
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config" -Name "MaxPosPhaseCorrection" -Value 4294967295 -Type DWord
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config" -Name "MaxNegPhaseCorrection" -Value 4294967295 -Type DWord
    # Disable Secure Time Seeding (known to corrupt clock on Win 10/11)
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config" -Name "UtilizeSslTimeData" -Value 0 -Type DWord

    # Configure NTP server list in active client mode (0x9)
    $serverList = $NtpServers -join " "
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -Name "NtpServer" -Value $serverList -Type String
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -Name "Type" -Value "NTP" -Type String

    Write-Host "[5/6] Verifying Windows Defender Firewall rule for UDP 123..." -ForegroundColor Yellow
    netsh advfirewall firewall add rule name="NTP UDP 123" dir=out action=allow protocol=UDP remoteport=123 | Out-Null

    Write-Host "[6/6] Starting W32Time service and forcing resync..." -ForegroundColor Yellow
    Start-Service -Name w32time
    Start-Sleep -Seconds 2

    & w32tm /config /update | Out-Null
    $syncOutput = (& w32tm /resync /force 2>&1) | Out-String
    Write-Host $syncOutput

    if ($LASTEXITCODE -eq 0 -or $syncOutput -like "*The command completed successfully*") {
        Write-Host "`n[SUCCESS] Windows Time synchronized successfully via NTP!" -ForegroundColor Green
    } else {
        Write-Host "`n[NOTICE] NTP sync failed (UDP 123 may be blocked on this network/ISP)." -ForegroundColor Yellow
        Sync-ViaHttps
    }
}

Write-Host "`nCurrent System Time: $((Get-Date).ToString())" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not $NonInteractive) {
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
