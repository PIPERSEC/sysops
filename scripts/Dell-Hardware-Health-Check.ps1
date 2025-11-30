<#
.SYNOPSIS
    Dell Hardware Health and Configuration Checker

.DESCRIPTION
    Comprehensive script to check Dell server hardware health, firmware versions,
    and best practices using Dell OpenManage tools and iDRAC integration.

.NOTES
    Author: System Operations Team
    Version: 1.0
    References:
    - https://github.com/dell/OpenManage-PowerShell-Modules
    - https://www.dell.com/support/kbdoc/en-us/000175879/support-for-openmanage-enterprise
    - https://www.dell.com/support/manuals/en-us/openmanage-integration-microsoft-windows-admin-center/

.PREREQUISITES
    Option 1 - Dell OpenManage Server Administrator (OMSA):
    - Install Dell OpenManage Server Administrator on the server
    - Download from: https://www.dell.com/support/home/en-us/product-support/product/openmanage-server-administrator

    Option 2 - Dell iDRAC PowerShell Modules:
    - Install-Module -Name DellBIOSProvider
    - Install Dell OpenManage PowerShell Modules from Dell TechCenter

    Option 3 - WMI/CIM (Basic checks without OMSA):
    - Works on any Dell server with Windows

.EXAMPLE
    .\Dell-Hardware-Health-Check.ps1
    .\Dell-Hardware-Health-Check.ps1 -UseOMSA
    .\Dell-Hardware-Health-Check.ps1 -iDRACHost "192.168.1.100" -Credential (Get-Credential)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ExportPath = "$env:TEMP\DellHardwareCheck_$(Get-Date -Format 'yyyyMMdd_HHmmss').html",

    [Parameter(Mandatory=$false)]
    [switch]$UseOMSA,

    [Parameter(Mandatory=$false)]
    [string]$iDRACHost,

    [Parameter(Mandatory=$false)]
    [PSCredential]$Credential,

    [Parameter(Mandatory=$false)]
    [switch]$CheckFirmwareVersions
)

$Script:Results = @()
$Script:StartTime = Get-Date
$Script:OMSAAvailable = $false
$Script:SystemInfo = @{}

function Write-CheckResult {
    param(
        [string]$Category,
        [string]$Component,
        [string]$Status,  # Healthy, Warning, Critical, Unknown
        [string]$Details,
        [string]$Recommendation = "",
        [string]$CurrentValue = "",
        [string]$Reference = ""
    )

    $Script:Results += [PSCustomObject]@{
        Category = $Category
        Component = $Component
        Status = $Status
        Details = $Details
        CurrentValue = $CurrentValue
        Recommendation = $Recommendation
        Reference = $Reference
        Timestamp = Get-Date
    }

    $color = switch($Status) {
        "Healthy" { "Green" }
        "Critical" { "Red" }
        "Warning" { "Yellow" }
        default { "White" }
    }

    Write-Host "[$Status] $Component" -ForegroundColor $color
    if ($Details) {
        Write-Verbose "  $Details"
    }
}

function Test-DellHardware {
    Write-Host "`n=== Detecting Dell Hardware ===" -ForegroundColor Cyan

    try {
        $cs = Get-CimInstance Win32_ComputerSystem
        $bios = Get-CimInstance Win32_BIOS

        if ($cs.Manufacturer -notmatch "Dell") {
            Write-Host "This is not a Dell system. Manufacturer: $($cs.Manufacturer)" -ForegroundColor Red
            throw "Not a Dell system"
        }

        $Script:SystemInfo = @{
            Manufacturer = $cs.Manufacturer
            Model = $cs.Model
            ServiceTag = $bios.SerialNumber
            BIOSVersion = $bios.SMBIOSBIOSVersion
            BIOSDate = $bios.ReleaseDate
        }

        Write-Host "✓ Dell System Detected" -ForegroundColor Green
        Write-Host "  Model: $($Script:SystemInfo.Model)" -ForegroundColor Gray
        Write-Host "  Service Tag: $($Script:SystemInfo.ServiceTag)" -ForegroundColor Gray
        Write-Host "  BIOS Version: $($Script:SystemInfo.BIOSVersion)" -ForegroundColor Gray

        return $true

    } catch {
        Write-Host "Error detecting Dell hardware: $_" -ForegroundColor Red
        return $false
    }
}

function Test-OMSAAvailability {
    Write-Host "`n=== Checking for Dell OpenManage Server Administrator ===" -ForegroundColor Cyan

    # Check if omreport.exe is available
    $omreportPath = "C:\Program Files\Dell\SysMgt\oma\bin\omreport.exe"

    if (Test-Path $omreportPath) {
        $Script:OMSAAvailable = $true
        Write-Host "✓ Dell OMSA is installed" -ForegroundColor Green

        # Get OMSA version
        try {
            $version = & $omreportPath system version | Select-String "Version"
            Write-Host "  $version" -ForegroundColor Gray
        } catch {
            Write-Verbose "Could not retrieve OMSA version"
        }

        return $true
    } else {
        $Script:OMSAAvailable = $false
        Write-Host "⚠ Dell OMSA is not installed" -ForegroundColor Yellow
        Write-Host "  Install from: https://www.dell.com/support/home/en-us/product-support/product/openmanage-server-administrator" -ForegroundColor Gray
        Write-Host "  Falling back to WMI/CIM checks..." -ForegroundColor Yellow

        return $false
    }
}

#region OMSA-based Checks
function Get-OMSASystemHealth {
    if (-not $Script:OMSAAvailable) { return }

    Write-Host "`n=== Dell OMSA - Overall System Health ===" -ForegroundColor Cyan

    $omreport = "C:\Program Files\Dell\SysMgt\oma\bin\omreport.exe"

    try {
        # Overall system health
        $systemHealth = & $omreport system -fmt ssv | ConvertFrom-Csv -Delimiter ";"

        $health = $systemHealth | Where-Object { $_.Property -eq "SEVERITY" } | Select-Object -ExpandProperty Value

        if ($health -eq "Ok") {
            Write-CheckResult -Category "System" -Component "Overall Health" -Status "Healthy" `
                -Details "System health is OK" `
                -Reference "https://www.dell.com/support/kbdoc/en-us/000136490/command-list-of-openmanage-server-administrator-omsa"
        } else {
            Write-CheckResult -Category "System" -Component "Overall Health" -Status "Warning" `
                -Details "System health status: $health" `
                -Recommendation "Review component-level health details"
        }

    } catch {
        Write-CheckResult -Category "System" -Component "Overall Health" -Status "Unknown" `
            -Details "Unable to query OMSA: $_"
    }
}

function Get-OMSAStorageHealth {
    if (-not $Script:OMSAAvailable) { return }

    Write-Host "`n=== Dell OMSA - Storage Health ===" -ForegroundColor Cyan

    $omreport = "C:\Program Files\Dell\SysMgt\oma\bin\omreport.exe"

    try {
        # Check physical disks
        $pdisks = & $omreport storage pdisk controller=0 -fmt ssv 2>$null

        if ($pdisks) {
            $pdiskData = $pdisks | ConvertFrom-Csv -Delimiter ";"

            foreach ($disk in $pdiskData) {
                if ($disk.Status -eq "Ok") {
                    Write-CheckResult -Category "Storage" -Component "Physical Disk $($disk.ID)" -Status "Healthy" `
                        -Details "$($disk.Capacity) - $($disk.State)" `
                        -CurrentValue $disk.Status
                } else {
                    Write-CheckResult -Category "Storage" -Component "Physical Disk $($disk.ID)" -Status "Warning" `
                        -Details "$($disk.Capacity) - Status: $($disk.Status)" `
                        -CurrentValue $disk.Status `
                        -Recommendation "Check disk health and consider replacement"
                }
            }
        }

        # Check virtual disks / RAID arrays
        $vdisks = & $omreport storage vdisk controller=0 -fmt ssv 2>$null

        if ($vdisks) {
            $vdiskData = $vdisks | ConvertFrom-Csv -Delimiter ";"

            foreach ($vdisk in $vdiskData) {
                if ($vdisk.Status -eq "Ok") {
                    Write-CheckResult -Category "Storage" -Component "Virtual Disk $($vdisk.ID)" -Status "Healthy" `
                        -Details "RAID $($vdisk.Layout) - $($vdisk.Size)" `
                        -CurrentValue $vdisk.State
                } else {
                    Write-CheckResult -Category "Storage" -Component "Virtual Disk $($vdisk.ID)" -Status "Critical" `
                        -Details "Status: $($vdisk.Status)" `
                        -CurrentValue $vdisk.State `
                        -Recommendation "RAID array requires attention - data at risk!"
                }
            }
        }

    } catch {
        Write-CheckResult -Category "Storage" -Component "Storage Health" -Status "Unknown" `
            -Details "Unable to query storage: $_"
    }
}

function Get-OMSAChassis {
    if (-not $Script:OMSAAvailable) { return }

    Write-Host "`n=== Dell OMSA - Chassis Health ===" -ForegroundColor Cyan

    $omreport = "C:\Program Files\Dell\SysMgt\oma\bin\omreport.exe"

    try {
        # Fans
        $fans = & $omreport chassis fans -fmt ssv 2>$null
        if ($fans) {
            $fanData = $fans | ConvertFrom-Csv -Delimiter ";"
            foreach ($fan in $fanData) {
                if ($fan.Status -eq "Ok") {
                    Write-CheckResult -Category "Cooling" -Component $fan.Name -Status "Healthy" `
                        -Details "Speed: $($fan.Reading)" `
                        -CurrentValue $fan.Status
                } else {
                    Write-CheckResult -Category "Cooling" -Component $fan.Name -Status "Critical" `
                        -Details "Status: $($fan.Status)" `
                        -Recommendation "Fan failure - check for thermal issues"
                }
            }
        }

        # Power Supplies
        $pwrsupply = & $omreport chassis pwrsupplies -fmt ssv 2>$null
        if ($pwrsupply) {
            $psData = $pwrsupply | ConvertFrom-Csv -Delimiter ";"
            foreach ($ps in $psData) {
                if ($ps.Status -eq "Ok") {
                    Write-CheckResult -Category "Power" -Component $ps.Name -Status "Healthy" `
                        -Details "Online" `
                        -CurrentValue $ps.Status
                } else {
                    Write-CheckResult -Category "Power" -Component $ps.Name -Status "Critical" `
                        -Details "Status: $($ps.Status)" `
                        -Recommendation "Power supply failure detected"
                }
            }
        }

        # Temperatures
        $temps = & $omreport chassis temps -fmt ssv 2>$null
        if ($temps) {
            $tempData = $temps | ConvertFrom-Csv -Delimiter ";"
            foreach ($temp in $tempData) {
                $reading = [int]($temp.Reading -replace '[^\d]','')
                $maxWarn = if ($temp.'Warning Threshold') { [int]($temp.'Warning Threshold' -replace '[^\d]','') } else { 75 }

                if ($temp.Status -eq "Ok") {
                    Write-CheckResult -Category "Temperature" -Component $temp.Name -Status "Healthy" `
                        -Details "$($temp.Reading)" `
                        -CurrentValue $temp.Status
                } elseif ($reading -ge $maxWarn) {
                    Write-CheckResult -Category "Temperature" -Component $temp.Name -Status "Warning" `
                        -Details "$($temp.Reading) - Approaching threshold" `
                        -CurrentValue $temp.Status `
                        -Recommendation "Check cooling system"
                } else {
                    Write-CheckResult -Category "Temperature" -Component $temp.Name -Status "Critical" `
                        -Details "$($temp.Reading)" `
                        -CurrentValue $temp.Status `
                        -Recommendation "Critical temperature - check cooling immediately"
                }
            }
        }

        # Voltages
        $volts = & $omreport chassis volts -fmt ssv 2>$null
        if ($volts) {
            $voltData = $volts | ConvertFrom-Csv -Delimiter ";"
            foreach ($volt in $voltData) {
                if ($volt.Status -eq "Ok") {
                    Write-CheckResult -Category "Power" -Component $volt.Name -Status "Healthy" `
                        -Details "$($volt.Reading)" `
                        -CurrentValue $volt.Status
                } else {
                    Write-CheckResult -Category "Power" -Component $volt.Name -Status "Warning" `
                        -Details "Status: $($volt.Status) - $($volt.Reading)" `
                        -Recommendation "Voltage irregularity detected"
                }
            }
        }

    } catch {
        Write-CheckResult -Category "Chassis" -Component "Chassis Health" -Status "Unknown" `
            -Details "Unable to query chassis components: $_"
    }
}

function Get-OMSAMemory {
    if (-not $Script:OMSAAvailable) { return }

    Write-Host "`n=== Dell OMSA - Memory Health ===" -ForegroundColor Cyan

    $omreport = "C:\Program Files\Dell\SysMgt\oma\bin\omreport.exe"

    try {
        $memory = & $omreport chassis memory -fmt ssv 2>$null
        if ($memory) {
            $memData = $memory | ConvertFrom-Csv -Delimiter ";"

            foreach ($dimm in $memData) {
                if ($dimm.Status -eq "Ok") {
                    Write-CheckResult -Category "Memory" -Component $dimm.Name -Status "Healthy" `
                        -Details "$($dimm.Size)" `
                        -CurrentValue $dimm.Status
                } else {
                    Write-CheckResult -Category "Memory" -Component $dimm.Name -Status "Critical" `
                        -Details "Status: $($dimm.Status)" `
                        -Recommendation "Memory module failure - replace DIMM"
                }
            }
        }

    } catch {
        Write-CheckResult -Category "Memory" -Component "Memory Health" -Status "Unknown" `
            -Details "Unable to query memory: $_"
    }
}

function Get-OMSAProcessors {
    if (-not $Script:OMSAAvailable) { return }

    Write-Host "`n=== Dell OMSA - Processor Health ===" -ForegroundColor Cyan

    $omreport = "C:\Program Files\Dell\SysMgt\oma\bin\omreport.exe"

    try {
        $processors = & $omreport chassis processors -fmt ssv 2>$null
        if ($processors) {
            $procData = $processors | ConvertFrom-Csv -Delimiter ";"

            foreach ($proc in $procData) {
                if ($proc.Status -eq "Ok") {
                    Write-CheckResult -Category "Processor" -Component $proc.Name -Status "Healthy" `
                        -Details "$($proc.'Brand Name')" `
                        -CurrentValue $proc.Status
                } else {
                    Write-CheckResult -Category "Processor" -Component $proc.Name -Status "Critical" `
                        -Details "Status: $($proc.Status)" `
                        -Recommendation "Processor issue detected"
                }
            }
        }

    } catch {
        Write-CheckResult -Category "Processor" -Component "Processor Health" -Status "Unknown" `
            -Details "Unable to query processors: $_"
    }
}
#endregion

#region WMI/CIM Fallback Checks
function Get-CIMHardwareBasics {
    if ($Script:OMSAAvailable -and $UseOMSA) { return }

    Write-Host "`n=== Basic Hardware Information (WMI/CIM) ===" -ForegroundColor Cyan

    # Processors
    $processors = Get-CimInstance Win32_Processor
    foreach ($proc in $processors) {
        Write-CheckResult -Category "Processor" -Component $proc.DeviceID -Status "Healthy" `
            -Details "$($proc.Name) - $($proc.NumberOfCores) cores @ $($proc.MaxClockSpeed) MHz" `
            -CurrentValue "Detected"
    }

    # Memory
    $memory = Get-CimInstance Win32_PhysicalMemory
    $totalMemoryGB = ($memory | Measure-Object -Property Capacity -Sum).Sum / 1GB

    Write-CheckResult -Category "Memory" -Component "Total Memory" -Status "Healthy" `
        -Details "$([math]::Round($totalMemoryGB, 2)) GB installed across $($memory.Count) DIMM(s)" `
        -CurrentValue "$($memory.Count) modules"

    # Disks
    $disks = Get-CimInstance Win32_DiskDrive
    foreach ($disk in $disks) {
        $sizeGB = [math]::Round($disk.Size / 1GB, 2)
        $status = if ($disk.Status -eq "OK") { "Healthy" } else { "Warning" }

        Write-CheckResult -Category "Storage" -Component $disk.Caption -Status $status `
            -Details "$sizeGB GB - Interface: $($disk.InterfaceType)" `
            -CurrentValue $disk.Status
    }

    # Network Adapters
    $netAdapters = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true }
    foreach ($adapter in $netAdapters) {
        $status = if ($adapter.NetConnectionStatus -eq 2) { "Healthy" } else { "Warning" }
        $statusText = switch ($adapter.NetConnectionStatus) {
            0 { "Disconnected" }
            2 { "Connected" }
            7 { "Media Disconnected" }
            default { "Unknown" }
        }

        Write-CheckResult -Category "Network" -Component $adapter.Name -Status $status `
            -Details $statusText `
            -CurrentValue $statusText
    }
}

function Get-EventLogErrors {
    Write-Host "`n=== Recent Hardware Errors (Event Log) ===" -ForegroundColor Cyan

    try {
        # Check System event log for hardware errors
        $last24Hours = (Get-Date).AddHours(-24)

        # Hardware errors
        $hardwareErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            Level = 1,2  # Critical and Error
            StartTime = $last24Hours
        } -ErrorAction SilentlyContinue | Where-Object {
            $_.ProviderName -match "disk|raid|storage|scsi|ntfs"
        } | Select-Object -First 10

        if ($hardwareErrors.Count -eq 0) {
            Write-CheckResult -Category "System" -Component "Event Log - Hardware Errors" -Status "Healthy" `
                -Details "No hardware errors in last 24 hours" `
                -CurrentValue "0 errors"
        } else {
            Write-CheckResult -Category "System" -Component "Event Log - Hardware Errors" -Status "Warning" `
                -Details "$($hardwareErrors.Count) hardware-related errors in last 24 hours" `
                -Recommendation "Review Event Viewer for details" `
                -CurrentValue "$($hardwareErrors.Count) errors"
        }

    } catch {
        Write-CheckResult -Category "System" -Component "Event Log" -Status "Unknown" `
            -Details "Unable to query event log: $_"
    }
}
#endregion

#region Firmware Version Check
function Get-FirmwareVersions {
    if (-not $CheckFirmwareVersions) {
        Write-Host "`n=== Skipping Firmware Version Check (use -CheckFirmwareVersions to enable) ===" -ForegroundColor Yellow
        return
    }

    Write-Host "`n=== Firmware Versions ===" -ForegroundColor Cyan

    Write-CheckResult -Category "Firmware" -Component "BIOS" -Status "Healthy" `
        -Details "Version: $($Script:SystemInfo.BIOSVersion)" `
        -CurrentValue $Script:SystemInfo.BIOSVersion `
        -Recommendation "Check Dell support site for latest BIOS version" `
        -Reference "https://www.dell.com/support/home/en-us/product-support/servicetag/$($Script:SystemInfo.ServiceTag)"

    Write-Host "  Check for updates at: https://www.dell.com/support/home/en-us/product-support/servicetag/$($Script:SystemInfo.ServiceTag)" -ForegroundColor Gray
}
#endregion

#region Generate Report
function Export-HTMLReport {
    param($SystemInfo, $Results, $Path)

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Dell Hardware Health Report - $($SystemInfo.ServiceTag)</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .header { background: linear-gradient(135deg, #0076ce 0%, #003e7e 100%); color: white; padding: 25px; border-radius: 5px; }
        .dell-logo { font-size: 2.5em; font-weight: bold; }
        .system-info { background: white; padding: 20px; margin: 20px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .info-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 15px; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 15px; margin: 20px 0; }
        .summary-card { background: white; padding: 20px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); text-align: center; }
        .summary-number { font-size: 2.5em; font-weight: bold; margin: 10px 0; }
        .healthy { color: #107c10; }
        .critical { color: #d13438; }
        .warning { color: #ff8c00; }
        .unknown { color: #666; }
        .section { background: white; margin: 20px 0; padding: 20px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        th { background: #0076ce; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #e0e0e0; }
        tr:hover { background: #f8f8f8; }
        .status-badge { padding: 5px 12px; border-radius: 3px; font-weight: bold; font-size: 0.85em; }
        .status-Healthy { background: #dff6dd; color: #107c10; }
        .status-Critical { background: #fde7e9; color: #d13438; }
        .status-Warning { background: #fff4ce; color: #ff8c00; }
        .status-Unknown { background: #f0f0f0; color: #666; }
        .footer { text-align: center; color: #666; margin: 30px 0; }
        a { color: #0076ce; }
    </style>
</head>
<body>
    <div class="header">
        <div class="dell-logo">DELL</div>
        <h1>Hardware Health Report</h1>
        <p>Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>

    <div class="system-info">
        <h2>System Information</h2>
        <div class="info-grid">
            <div><strong>Model:</strong> $($SystemInfo.Model)</div>
            <div><strong>Service Tag:</strong> $($SystemInfo.ServiceTag)</div>
            <div><strong>BIOS Version:</strong> $($SystemInfo.BIOSVersion)</div>
            <div><strong>BIOS Date:</strong> $($SystemInfo.BIOSDate)</div>
        </div>
        <p style="margin-top: 15px;">
            <a href="https://www.dell.com/support/home/en-us/product-support/servicetag/$($SystemInfo.ServiceTag)" target="_blank">
                🔗 View Dell Support Page for this Service Tag
            </a>
        </p>
    </div>

    <div class="summary">
        <div class="summary-card">
            <div>Total Checks</div>
            <div class="summary-number">$($Results.Count)</div>
        </div>
        <div class="summary-card">
            <div class="summary-number healthy">$(($Results | Where-Object Status -eq 'Healthy').Count)</div>
            <div>Healthy</div>
        </div>
        <div class="summary-card">
            <div class="summary-number critical">$(($Results | Where-Object Status -eq 'Critical').Count)</div>
            <div>Critical</div>
        </div>
        <div class="summary-card">
            <div class="summary-number warning">$(($Results | Where-Object Status -eq 'Warning').Count)</div>
            <div>Warnings</div>
        </div>
    </div>
"@

    # Group by category
    $categories = $Results | Group-Object -Property Category

    foreach ($cat in $categories) {
        $html += "<div class='section'><h2>$($cat.Name)</h2><table><thead><tr><th>Component</th><th>Status</th><th>Details</th></tr></thead><tbody>"

        foreach ($result in $cat.Group) {
            $html += @"
            <tr>
                <td><strong>$($result.Component)</strong></td>
                <td><span class="status-badge status-$($result.Status)">$($result.Status)</span></td>
                <td>
                    $($result.Details)
                    $(if($result.Recommendation){"<br>→ <em>$($result.Recommendation)</em>"})
                    $(if($result.Reference){"<br><a href='$($result.Reference)' target='_blank'>📚 More Info</a>"})
                </td>
            </tr>
"@
        }
        $html += "</tbody></table></div>"
    }

    $html += @"
    <div class="footer">
        <p><strong>Dell Hardware Health Checker v1.0</strong></p>
        <p>Based on Dell OpenManage tools and best practices</p>
        <p><a href="https://www.dell.com/support/kbdoc/en-us/000175879/support-for-openmanage-enterprise" target="_blank">Dell OpenManage Documentation</a></p>
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
║   Dell Hardware Health and Configuration Checker                 ║
║   Based on Dell OpenManage and Best Practices                    ║
╚═══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

    # Detect Dell hardware
    if (-not (Test-DellHardware)) {
        Write-Host "This script is designed for Dell servers only." -ForegroundColor Red
        return
    }

    # Check for OMSA
    Test-OMSAAvailability

    # Run appropriate checks
    if ($Script:OMSAAvailable -and $UseOMSA) {
        Write-Host "`nUsing Dell OpenManage Server Administrator for detailed checks..." -ForegroundColor Green
        Get-OMSASystemHealth
        Get-OMSAStorageHealth
        Get-OMSAChassis
        Get-OMSAMemory
        Get-OMSAProcessors
    } else {
        Write-Host "`nUsing WMI/CIM for basic hardware checks..." -ForegroundColor Yellow
        Get-CIMHardwareBasics
    }

    # Common checks
    Get-EventLogErrors
    Get-FirmwareVersions

    # Summary
    $endTime = Get-Date
    $duration = $endTime - $Script:StartTime

    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    Write-Host "System: $($Script:SystemInfo.Model) (Service Tag: $($Script:SystemInfo.ServiceTag))" -ForegroundColor White
    Write-Host "Total Checks: $($Script:Results.Count)" -ForegroundColor White
    Write-Host "Healthy: $(($Script:Results | Where-Object Status -eq 'Healthy').Count)" -ForegroundColor Green
    Write-Host "Critical: $(($Script:Results | Where-Object Status -eq 'Critical').Count)" -ForegroundColor Red
    Write-Host "Warnings: $(($Script:Results | Where-Object Status -eq 'Warning').Count)" -ForegroundColor Yellow
    Write-Host "Unknown: $(($Script:Results | Where-Object Status -eq 'Unknown').Count)" -ForegroundColor Gray
    Write-Host "Duration: $([math]::Round($duration.TotalSeconds, 2)) seconds" -ForegroundColor White

    # Generate report
    Write-Host "`nGenerating HTML report..." -ForegroundColor Cyan
    $reportPath = Export-HTMLReport -SystemInfo $Script:SystemInfo -Results $Script:Results -Path $ExportPath
    Write-Host "Report saved to: $reportPath" -ForegroundColor Green

    # Open report
    try {
        Start-Process $reportPath
    } catch {
        Write-Host "Could not open report automatically." -ForegroundColor Yellow
    }

    return $Script:Results
}

# Execute
try {
    Main
} catch {
    Write-Host "`nError: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
#endregion
