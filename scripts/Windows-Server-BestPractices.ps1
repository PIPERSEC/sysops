<#
.SYNOPSIS
    Windows Server Best Practices and Configuration Checker

.DESCRIPTION
    Comprehensive script to check Windows Server configurations against Microsoft best practices.
    Based on Microsoft Security Compliance Toolkit and official recommendations.

.NOTES
    Author: System Operations Team
    Version: 1.0
    References:
    - https://learn.microsoft.com/en-us/windows/security/operating-system-security/device-management/windows-security-configuration-framework/security-compliance-toolkit-10
    - https://learn.microsoft.com/en-us/windows/security/operating-system-security/device-management/windows-security-configuration-framework/windows-security-baselines

.EXAMPLE
    .\Windows-Server-BestPractices.ps1 -Verbose
    .\Windows-Server-BestPractices.ps1 -ExportPath "C:\Reports\ServerCheck.html"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ExportPath = "$env:TEMP\WindowsServerBestPractices_$(Get-Date -Format 'yyyyMMdd_HHmmss').html",

    [Parameter(Mandatory=$false)]
    [switch]$IncludeDetailedLogs
)

#Requires -RunAsAdministrator

# Initialize results collection
$Script:Results = @()
$Script:StartTime = Get-Date

function Write-CheckResult {
    param(
        [string]$Category,
        [string]$CheckName,
        [string]$Status,  # Pass, Fail, Warning, Info
        [string]$Message,
        [string]$Recommendation = "",
        [string]$Reference = ""
    )

    $Script:Results += [PSCustomObject]@{
        Category = $Category
        Check = $CheckName
        Status = $Status
        Message = $Message
        Recommendation = $Recommendation
        Reference = $Reference
        Timestamp = Get-Date
    }

    $color = switch($Status) {
        "Pass" { "Green" }
        "Fail" { "Red" }
        "Warning" { "Yellow" }
        default { "White" }
    }

    Write-Host "[$Status] $Category - $CheckName" -ForegroundColor $color
    if ($IncludeDetailedLogs) {
        Write-Host "  $Message" -ForegroundColor Gray
    }
}

#region System Information
function Get-SystemInformation {
    Write-Host "`n=== Gathering System Information ===" -ForegroundColor Cyan

    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_BIOS

    $sysInfo = [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        OSVersion = $os.Caption
        OSBuild = $os.BuildNumber
        InstallDate = $os.InstallDate
        LastBootTime = $os.LastBootUpTime
        Manufacturer = $cs.Manufacturer
        Model = $cs.Model
        TotalMemoryGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
        Domain = $cs.Domain
        BIOSVersion = $bios.SMBIOSBIOSVersion
    }

    Write-Host "Server: $($sysInfo.ComputerName) - $($sysInfo.OSVersion) Build $($sysInfo.OSBuild)" -ForegroundColor Green
    return $sysInfo
}
#endregion

#region Security Checks
function Test-SecurityBaseline {
    Write-Host "`n=== Security Baseline Checks ===" -ForegroundColor Cyan

    # Check Windows Defender status
    try {
        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($defenderStatus) {
            if ($defenderStatus.AntivirusEnabled) {
                Write-CheckResult -Category "Security" -CheckName "Windows Defender" -Status "Pass" `
                    -Message "Windows Defender is enabled and running" `
                    -Reference "https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/"
            } else {
                Write-CheckResult -Category "Security" -CheckName "Windows Defender" -Status "Warning" `
                    -Message "Windows Defender antivirus is not enabled" `
                    -Recommendation "Enable Windows Defender or ensure third-party antivirus is installed"
            }
        }
    } catch {
        Write-CheckResult -Category "Security" -CheckName "Windows Defender" -Status "Info" `
            -Message "Could not query Windows Defender status (may use third-party AV)"
    }

    # Check Windows Firewall
    $firewallProfiles = Get-NetFirewallProfile
    foreach ($profile in $firewallProfiles) {
        if ($profile.Enabled) {
            Write-CheckResult -Category "Security" -CheckName "Firewall - $($profile.Name)" -Status "Pass" `
                -Message "Firewall is enabled for $($profile.Name) profile"
        } else {
            Write-CheckResult -Category "Security" -CheckName "Firewall - $($profile.Name)" -Status "Fail" `
                -Message "Firewall is DISABLED for $($profile.Name) profile" `
                -Recommendation "Enable Windows Firewall for all profiles" `
                -Reference "https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/"
        }
    }

    # Check UAC settings
    $uacKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    $uacLevel = Get-ItemProperty -Path $uacKey -Name "ConsentPromptBehaviorAdmin" -ErrorAction SilentlyContinue
    if ($uacLevel.ConsentPromptBehaviorAdmin -ge 2) {
        Write-CheckResult -Category "Security" -CheckName "User Account Control (UAC)" -Status "Pass" `
            -Message "UAC is configured appropriately (Level: $($uacLevel.ConsentPromptBehaviorAdmin))"
    } else {
        Write-CheckResult -Category "Security" -CheckName "User Account Control (UAC)" -Status "Fail" `
            -Message "UAC is set too low or disabled" `
            -Recommendation "Set UAC to at least 'Prompt for consent on the secure desktop'" `
            -Reference "https://learn.microsoft.com/en-us/windows/security/identity-protection/user-account-control/"
    }

    # Check for SMBv1
    $smbv1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
    if ($smbv1.State -eq "Disabled") {
        Write-CheckResult -Category "Security" -CheckName "SMBv1 Protocol" -Status "Pass" `
            -Message "SMBv1 is disabled (recommended)" `
            -Reference "https://learn.microsoft.com/en-us/windows-server/storage/file-server/troubleshoot/detect-enable-and-disable-smbv1-v2-v3"
    } else {
        Write-CheckResult -Category "Security" -CheckName "SMBv1 Protocol" -Status "Fail" `
            -Message "SMBv1 is ENABLED - security risk!" `
            -Recommendation "Disable SMBv1: Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol" `
            -Reference "https://learn.microsoft.com/en-us/windows-server/storage/file-server/troubleshoot/detect-enable-and-disable-smbv1-v2-v3"
    }

    # Check LSA Protection
    $lsaKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    $lsaProtection = Get-ItemProperty -Path $lsaKey -Name "RunAsPPL" -ErrorAction SilentlyContinue
    if ($lsaProtection.RunAsPPL -eq 1) {
        Write-CheckResult -Category "Security" -CheckName "LSA Protection" -Status "Pass" `
            -Message "LSA Protection is enabled"
    } else {
        Write-CheckResult -Category "Security" -CheckName "LSA Protection" -Status "Warning" `
            -Message "LSA Protection is not enabled" `
            -Recommendation "Enable LSA Protection to prevent credential theft" `
            -Reference "https://learn.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/configuring-additional-lsa-protection"
    }
}
#endregion

#region Update and Patch Management
function Test-UpdateCompliance {
    Write-Host "`n=== Windows Update and Patch Status ===" -ForegroundColor Cyan

    # Check Windows Update service
    $wuService = Get-Service -Name wuauserv
    if ($wuService.Status -eq "Running") {
        Write-CheckResult -Category "Updates" -CheckName "Windows Update Service" -Status "Pass" `
            -Message "Windows Update service is running"
    } else {
        Write-CheckResult -Category "Updates" -CheckName "Windows Update Service" -Status "Warning" `
            -Message "Windows Update service is not running" `
            -Recommendation "Start the Windows Update service"
    }

    # Check last update installation
    try {
        $lastUpdate = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1
        $daysSinceUpdate = (New-TimeSpan -Start $lastUpdate.InstalledOn -End (Get-Date)).Days

        if ($daysSinceUpdate -le 30) {
            Write-CheckResult -Category "Updates" -CheckName "Recent Updates" -Status "Pass" `
                -Message "Last update installed: $($lastUpdate.HotFixID) on $($lastUpdate.InstalledOn) ($daysSinceUpdate days ago)"
        } elseif ($daysSinceUpdate -le 60) {
            Write-CheckResult -Category "Updates" -CheckName "Recent Updates" -Status "Warning" `
                -Message "Last update was $daysSinceUpdate days ago" `
                -Recommendation "Check for and install pending Windows updates"
        } else {
            Write-CheckResult -Category "Updates" -CheckName "Recent Updates" -Status "Fail" `
                -Message "Last update was $daysSinceUpdate days ago - critically outdated!" `
                -Recommendation "Immediately check for and install Windows updates" `
                -Reference "https://learn.microsoft.com/en-us/windows/deployment/update/windows-update-overview"
        }
    } catch {
        Write-CheckResult -Category "Updates" -CheckName "Recent Updates" -Status "Warning" `
            -Message "Unable to determine last update date"
    }

    # Check pending reboot
    $rebootPending = $false
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
        $rebootPending = $true
    }
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") {
        $rebootPending = $true
    }

    if ($rebootPending) {
        Write-CheckResult -Category "Updates" -CheckName "Pending Reboot" -Status "Warning" `
            -Message "System has a pending reboot to complete updates" `
            -Recommendation "Schedule a maintenance window to reboot the server"
    } else {
        Write-CheckResult -Category "Updates" -CheckName "Pending Reboot" -Status "Pass" `
            -Message "No pending reboot required"
    }
}
#endregion

#region Performance and Resource Checks
function Test-SystemPerformance {
    Write-Host "`n=== System Performance and Resources ===" -ForegroundColor Cyan

    # Check disk space
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null }
    foreach ($drive in $drives) {
        $percentFree = [math]::Round(($drive.Free / ($drive.Used + $drive.Free)) * 100, 2)

        if ($percentFree -ge 20) {
            Write-CheckResult -Category "Performance" -CheckName "Disk Space - $($drive.Name):" -Status "Pass" `
                -Message "$percentFree% free ($([math]::Round($drive.Free/1GB, 2)) GB available)"
        } elseif ($percentFree -ge 10) {
            Write-CheckResult -Category "Performance" -CheckName "Disk Space - $($drive.Name):" -Status "Warning" `
                -Message "Only $percentFree% free ($([math]::Round($drive.Free/1GB, 2)) GB available)" `
                -Recommendation "Clean up disk space or expand volume"
        } else {
            Write-CheckResult -Category "Performance" -CheckName "Disk Space - $($drive.Name):" -Status "Fail" `
                -Message "CRITICAL: Only $percentFree% free ($([math]::Round($drive.Free/1GB, 2)) GB available)" `
                -Recommendation "Immediately free up disk space" `
                -Reference "https://learn.microsoft.com/en-us/windows-server/storage/disk-management/overview-of-disk-management"
        }
    }

    # Check memory usage
    $os = Get-CimInstance Win32_OperatingSystem
    $memoryUsedPercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)

    if ($memoryUsedPercent -le 80) {
        Write-CheckResult -Category "Performance" -CheckName "Memory Usage" -Status "Pass" `
            -Message "$memoryUsedPercent% memory in use"
    } elseif ($memoryUsedPercent -le 90) {
        Write-CheckResult -Category "Performance" -CheckName "Memory Usage" -Status "Warning" `
            -Message "$memoryUsedPercent% memory in use" `
            -Recommendation "Monitor memory usage and consider adding more RAM"
    } else {
        Write-CheckResult -Category "Performance" -CheckName "Memory Usage" -Status "Fail" `
            -Message "$memoryUsedPercent% memory in use - critically high!" `
            -Recommendation "Investigate high memory usage or add more RAM"
    }

    # Check page file configuration
    $pageFile = Get-CimInstance Win32_PageFileUsage
    if ($pageFile) {
        Write-CheckResult -Category "Performance" -CheckName "Page File" -Status "Pass" `
            -Message "Page file configured: $($pageFile.AllocatedBaseSize) MB allocated"
    } else {
        Write-CheckResult -Category "Performance" -CheckName "Page File" -Status "Warning" `
            -Message "No page file configured" `
            -Recommendation "Configure a page file for optimal performance and crash dump collection"
    }
}
#endregion

#region Event Log Checks
function Test-EventLogs {
    Write-Host "`n=== Event Log Analysis ===" -ForegroundColor Cyan

    # Check for critical errors in last 24 hours
    $last24Hours = (Get-Date).AddHours(-24)

    $criticalErrors = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        Level = 1  # Critical
        StartTime = $last24Hours
    } -ErrorAction SilentlyContinue | Measure-Object

    if ($criticalErrors.Count -eq 0) {
        Write-CheckResult -Category "Event Logs" -CheckName "Critical System Errors" -Status "Pass" `
            -Message "No critical errors in last 24 hours"
    } else {
        Write-CheckResult -Category "Event Logs" -CheckName "Critical System Errors" -Status "Warning" `
            -Message "$($criticalErrors.Count) critical errors found in last 24 hours" `
            -Recommendation "Review Event Viewer for critical system errors"
    }

    # Check for logon failures
    $logonFailures = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4625  # Failed logon
        StartTime = $last24Hours
    } -ErrorAction SilentlyContinue | Measure-Object

    if ($logonFailures.Count -eq 0) {
        Write-CheckResult -Category "Event Logs" -CheckName "Failed Logon Attempts" -Status "Pass" `
            -Message "No failed logon attempts in last 24 hours"
    } elseif ($logonFailures.Count -le 10) {
        Write-CheckResult -Category "Event Logs" -CheckName "Failed Logon Attempts" -Status "Info" `
            -Message "$($logonFailures.Count) failed logon attempts in last 24 hours (normal range)"
    } else {
        Write-CheckResult -Category "Event Logs" -CheckName "Failed Logon Attempts" -Status "Warning" `
            -Message "$($logonFailures.Count) failed logon attempts in last 24 hours" `
            -Recommendation "Review security logs for potential brute force attacks" `
            -Reference "https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/security-best-practices/monitoring-active-directory-for-signs-of-compromise"
    }
}
#endregion

#region Service Checks
function Test-CriticalServices {
    Write-Host "`n=== Critical Services Status ===" -ForegroundColor Cyan

    $criticalServices = @(
        "EventLog",
        "Dnscache",
        "RpcSs",
        "LanmanServer",
        "LanmanWorkstation"
    )

    foreach ($serviceName in $criticalServices) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            if ($service.Status -eq "Running") {
                Write-CheckResult -Category "Services" -CheckName "$($service.DisplayName)" -Status "Pass" `
                    -Message "Service is running"
            } else {
                Write-CheckResult -Category "Services" -CheckName "$($service.DisplayName)" -Status "Fail" `
                    -Message "Service is NOT running (Status: $($service.Status))" `
                    -Recommendation "Start the $($service.DisplayName) service"
            }
        }
    }
}
#endregion

#region Time Configuration
function Test-TimeConfiguration {
    Write-Host "`n=== Time Configuration ===" -ForegroundColor Cyan

    $w32tm = w32tm /query /status
    if ($LASTEXITCODE -eq 0) {
        Write-CheckResult -Category "Configuration" -CheckName "Time Synchronization" -Status "Pass" `
            -Message "Time service is synchronized" `
            -Reference "https://learn.microsoft.com/en-us/windows-server/networking/windows-time-service/windows-time-service-top"
    } else {
        Write-CheckResult -Category "Configuration" -CheckName "Time Synchronization" -Status "Fail" `
            -Message "Time service is not synchronized" `
            -Recommendation "Configure and start Windows Time service: w32tm /config /manualpeerlist:time.windows.com /syncfromflags:manual /update" `
            -Reference "https://learn.microsoft.com/en-us/windows-server/networking/windows-time-service/windows-time-service-top"
    }
}
#endregion

#region Generate Report
function Export-HTMLReport {
    param($SystemInfo, $Results, $Path)

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Windows Server Best Practices Report - $($SystemInfo.ComputerName)</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .header { background: linear-gradient(135deg, #0078d4 0%, #00bcf2 100%); color: white; padding: 20px; border-radius: 5px; }
        .summary { background: white; padding: 15px; margin: 20px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-top: 15px; }
        .summary-item { text-align: center; padding: 15px; background: #f8f8f8; border-radius: 5px; }
        .summary-number { font-size: 2em; font-weight: bold; }
        .pass { color: #107c10; }
        .fail { color: #d13438; }
        .warning { color: #ff8c00; }
        .info { color: #0078d4; }
        table { width: 100%; border-collapse: collapse; background: white; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        th { background-color: #0078d4; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background-color: #f5f5f5; }
        .status-badge { padding: 5px 10px; border-radius: 3px; font-weight: bold; display: inline-block; }
        .status-Pass { background-color: #dff6dd; color: #107c10; }
        .status-Fail { background-color: #fde7e9; color: #d13438; }
        .status-Warning { background-color: #fff4ce; color: #ff8c00; }
        .status-Info { background-color: #e6f3ff; color: #0078d4; }
        .recommendation { font-style: italic; color: #666; font-size: 0.9em; }
        .footer { text-align: center; color: #666; margin-top: 30px; padding: 20px; }
        a { color: #0078d4; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Windows Server Best Practices Report</h1>
        <p>Server: $($SystemInfo.ComputerName) | Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>

    <div class="summary">
        <h2>System Information</h2>
        <table>
            <tr><td><strong>OS Version:</strong></td><td>$($SystemInfo.OSVersion) (Build $($SystemInfo.OSBuild))</td></tr>
            <tr><td><strong>Manufacturer:</strong></td><td>$($SystemInfo.Manufacturer) $($SystemInfo.Model)</td></tr>
            <tr><td><strong>Domain:</strong></td><td>$($SystemInfo.Domain)</td></tr>
            <tr><td><strong>Total Memory:</strong></td><td>$($SystemInfo.TotalMemoryGB) GB</td></tr>
            <tr><td><strong>Install Date:</strong></td><td>$($SystemInfo.InstallDate)</td></tr>
            <tr><td><strong>Last Boot:</strong></td><td>$($SystemInfo.LastBootTime)</td></tr>
        </table>
    </div>

    <div class="summary">
        <h2>Check Summary</h2>
        <div class="summary-grid">
            <div class="summary-item">
                <div class="summary-number pass">$(($Results | Where-Object Status -eq 'Pass').Count)</div>
                <div>Passed</div>
            </div>
            <div class="summary-item">
                <div class="summary-number fail">$(($Results | Where-Object Status -eq 'Fail').Count)</div>
                <div>Failed</div>
            </div>
            <div class="summary-item">
                <div class="summary-number warning">$(($Results | Where-Object Status -eq 'Warning').Count)</div>
                <div>Warnings</div>
            </div>
            <div class="summary-item">
                <div class="summary-number info">$(($Results | Where-Object Status -eq 'Info').Count)</div>
                <div>Info</div>
            </div>
        </div>
    </div>

    <h2>Detailed Results</h2>
    <table>
        <thead>
            <tr>
                <th>Category</th>
                <th>Check</th>
                <th>Status</th>
                <th>Details</th>
            </tr>
        </thead>
        <tbody>
"@

    foreach ($result in $Results) {
        $html += @"
            <tr>
                <td>$($result.Category)</td>
                <td>$($result.Check)</td>
                <td><span class="status-badge status-$($result.Status)">$($result.Status)</span></td>
                <td>
                    $($result.Message)
                    $(if ($result.Recommendation) { "<br><span class='recommendation'>→ $($result.Recommendation)</span>" })
                    $(if ($result.Reference) { "<br><a href='$($result.Reference)' target='_blank'>📚 Reference</a>" })
                </td>
            </tr>
"@
    }

    $html += @"
        </tbody>
    </table>

    <div class="footer">
        <p>Report generated by Windows Server Best Practices Checker v1.0</p>
        <p>Based on Microsoft Security Compliance Toolkit and official documentation</p>
        <p><a href="https://learn.microsoft.com/en-us/windows/security/" target="_blank">Microsoft Security Documentation</a></p>
    </div>
</body>
</html>
"@

    $html | Out-File -FilePath $Path -Encoding UTF8
    return $Path
}
#endregion

#region Main Execution
function Main {
    Write-Host @"
╔═══════════════════════════════════════════════════════════════════╗
║   Windows Server Best Practices and Configuration Checker        ║
║   Based on Microsoft Security Compliance Toolkit                 ║
╚═══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

    # Gather system information
    $systemInfo = Get-SystemInformation

    # Run all checks
    Test-SecurityBaseline
    Test-UpdateCompliance
    Test-SystemPerformance
    Test-EventLogs
    Test-CriticalServices
    Test-TimeConfiguration

    # Calculate statistics
    $endTime = Get-Date
    $duration = $endTime - $Script:StartTime

    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    Write-Host "Total Checks: $($Script:Results.Count)" -ForegroundColor White
    Write-Host "Passed: $(($Script:Results | Where-Object Status -eq 'Pass').Count)" -ForegroundColor Green
    Write-Host "Failed: $(($Script:Results | Where-Object Status -eq 'Fail').Count)" -ForegroundColor Red
    Write-Host "Warnings: $(($Script:Results | Where-Object Status -eq 'Warning').Count)" -ForegroundColor Yellow
    Write-Host "Info: $(($Script:Results | Where-Object Status -eq 'Info').Count)" -ForegroundColor Cyan
    Write-Host "Duration: $([math]::Round($duration.TotalSeconds, 2)) seconds" -ForegroundColor White

    # Export report
    Write-Host "`nGenerating HTML report..." -ForegroundColor Cyan
    $reportPath = Export-HTMLReport -SystemInfo $systemInfo -Results $Script:Results -Path $ExportPath
    Write-Host "Report saved to: $reportPath" -ForegroundColor Green

    # Open report
    try {
        Start-Process $reportPath
    } catch {
        Write-Host "Could not automatically open report. Please open manually: $reportPath" -ForegroundColor Yellow
    }

    return $Script:Results
}

# Execute main function
Main
#endregion
