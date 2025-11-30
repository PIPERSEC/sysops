<#
.SYNOPSIS
    Microsoft 365 Security and Configuration Best Practices Checker

.DESCRIPTION
    Comprehensive script to audit Microsoft 365 tenant security configurations,
    compliance settings, and best practices based on Microsoft recommendations.

.NOTES
    Author: System Operations Team
    Version: 1.0
    References:
    - https://github.com/microsoft/CSS-Exchange
    - https://learn.microsoft.com/en-us/microsoft-365/security/
    - https://learn.microsoft.com/en-us/microsoft-365/compliance/

.PREREQUISITES
    Install required modules:
    Install-Module -Name ExchangeOnlineManagement -Force
    Install-Module -Name Microsoft.Graph -Force
    Install-Module -Name MicrosoftTeams -Force
    Install-Module -Name Microsoft.Online.SharePoint.PowerShell -Force

.EXAMPLE
    .\M365-Security-ConfigCheck.ps1 -TenantDomain "contoso.onmicrosoft.com"
    .\M365-Security-ConfigCheck.ps1 -TenantDomain "contoso.onmicrosoft.com" -ExportPath "C:\Reports"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$TenantDomain,

    [Parameter(Mandatory=$false)]
    [string]$ExportPath = "$env:TEMP\M365SecurityCheck_$(Get-Date -Format 'yyyyMMdd_HHmmss')",

    [Parameter(Mandatory=$false)]
    [switch]$SkipExchangeOnline,

    [Parameter(Mandatory=$false)]
    [switch]$SkipSharePoint,

    [Parameter(Mandatory=$false)]
    [switch]$SkipTeams
)

# Initialize results
$Script:Results = @()
$Script:StartTime = Get-Date

function Write-CheckResult {
    param(
        [string]$Service,  # Exchange, Azure AD, SharePoint, Teams, Security
        [string]$Category,
        [string]$CheckName,
        [string]$Status,  # Pass, Fail, Warning, Info, NotConfigured
        [string]$CurrentValue,
        [string]$RecommendedValue = "",
        [string]$Impact = "",
        [string]$Reference = ""
    )

    $Script:Results += [PSCustomObject]@{
        Service = $Service
        Category = $Category
        Check = $CheckName
        Status = $Status
        CurrentValue = $CurrentValue
        RecommendedValue = $RecommendedValue
        Impact = $Impact
        Reference = $Reference
        Timestamp = Get-Date
    }

    $color = switch($Status) {
        "Pass" { "Green" }
        "Fail" { "Red" }
        "Warning" { "Yellow" }
        "NotConfigured" { "Magenta" }
        default { "White" }
    }

    Write-Host "[$Status] $Service - $CheckName" -ForegroundColor $color
}

function Test-RequiredModules {
    Write-Host "`n=== Checking Required PowerShell Modules ===" -ForegroundColor Cyan

    $requiredModules = @(
        @{ Name = "ExchangeOnlineManagement"; MinVersion = "3.0.0" },
        @{ Name = "Microsoft.Graph"; MinVersion = "2.0.0" },
        @{ Name = "MicrosoftTeams"; MinVersion = "5.0.0" }
    )

    $missingModules = @()

    foreach ($module in $requiredModules) {
        $installed = Get-Module -ListAvailable -Name $module.Name |
                     Where-Object { $_.Version -ge [version]$module.MinVersion } |
                     Select-Object -First 1

        if ($installed) {
            Write-Host "✓ $($module.Name) v$($installed.Version) is installed" -ForegroundColor Green
        } else {
            Write-Host "✗ $($module.Name) v$($module.MinVersion)+ is required but not installed" -ForegroundColor Red
            $missingModules += $module.Name
        }
    }

    if ($missingModules.Count -gt 0) {
        Write-Host "`nTo install missing modules, run:" -ForegroundColor Yellow
        foreach ($module in $missingModules) {
            Write-Host "  Install-Module -Name $module -Force -AllowClobber" -ForegroundColor Yellow
        }
        throw "Required modules are missing. Please install them and try again."
    }
}

function Connect-M365Services {
    Write-Host "`n=== Connecting to Microsoft 365 Services ===" -ForegroundColor Cyan

    try {
        # Connect to Microsoft Graph
        Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
        Connect-MgGraph -Scopes @(
            "Organization.Read.All",
            "Directory.Read.All",
            "Policy.Read.All",
            "SecurityEvents.Read.All",
            "AuditLog.Read.All"
        ) -NoWelcome -ErrorAction Stop
        Write-Host "✓ Connected to Microsoft Graph" -ForegroundColor Green

        # Connect to Exchange Online
        if (-not $SkipExchangeOnline) {
            Write-Host "Connecting to Exchange Online..." -ForegroundColor Yellow
            Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
            Write-Host "✓ Connected to Exchange Online" -ForegroundColor Green
        }

        # Connect to Teams
        if (-not $SkipTeams) {
            Write-Host "Connecting to Microsoft Teams..." -ForegroundColor Yellow
            Connect-MicrosoftTeams -ErrorAction Stop | Out-Null
            Write-Host "✓ Connected to Microsoft Teams" -ForegroundColor Green
        }

    } catch {
        Write-Host "Error connecting to M365 services: $_" -ForegroundColor Red
        throw
    }
}

#region Azure AD / Entra ID Checks
function Test-AzureADConfiguration {
    Write-Host "`n=== Azure AD / Entra ID Security Configuration ===" -ForegroundColor Cyan

    # Check MFA enforcement
    try {
        $mfaPolicy = Get-MgPolicyAuthenticationMethodPolicy -ErrorAction SilentlyContinue
        if ($mfaPolicy) {
            Write-CheckResult -Service "Azure AD" -Category "Authentication" -CheckName "MFA Policy" `
                -Status "Info" -CurrentValue "MFA policies are configured" `
                -Impact "Multi-factor authentication protects against credential compromise" `
                -Reference "https://learn.microsoft.com/en-us/entra/identity/authentication/concept-mfa-howitworks"
        }
    } catch {
        Write-CheckResult -Service "Azure AD" -Category "Authentication" -CheckName "MFA Policy" `
            -Status "Warning" -CurrentValue "Unable to verify MFA configuration" `
            -RecommendedValue "Enable MFA for all users" `
            -Reference "https://learn.microsoft.com/en-us/entra/identity/authentication/howto-mfa-getstarted"
    }

    # Check Conditional Access policies
    try {
        $caPolicies = Get-MgIdentityConditionalAccessPolicy -All -ErrorAction SilentlyContinue
        if ($caPolicies.Count -gt 0) {
            $enabledPolicies = ($caPolicies | Where-Object { $_.State -eq "enabled" }).Count
            Write-CheckResult -Service "Azure AD" -Category "Conditional Access" -CheckName "Conditional Access Policies" `
                -Status "Pass" -CurrentValue "$enabledPolicies enabled policies out of $($caPolicies.Count) total" `
                -Impact "Conditional Access provides intelligent security controls" `
                -Reference "https://learn.microsoft.com/en-us/entra/identity/conditional-access/overview"
        } else {
            Write-CheckResult -Service "Azure AD" -Category "Conditional Access" -CheckName "Conditional Access Policies" `
                -Status "Warning" -CurrentValue "No Conditional Access policies configured" `
                -RecommendedValue "Configure CA policies for enhanced security" `
                -Impact "Missing intelligent access controls" `
                -Reference "https://learn.microsoft.com/en-us/entra/identity/conditional-access/overview"
        }
    } catch {
        Write-CheckResult -Service "Azure AD" -Category "Conditional Access" -CheckName "Conditional Access Policies" `
            -Status "Info" -CurrentValue "Unable to query (requires Premium license)"
    }

    # Check Password Policy
    try {
        $org = Get-MgOrganization
        $passwordPolicy = $org.PasswordValidityPeriodInDays

        if ($passwordPolicy -eq $null -or $passwordPolicy -eq 0) {
            Write-CheckResult -Service "Azure AD" -Category "Password Policy" -CheckName "Password Expiration" `
                -Status "Pass" -CurrentValue "Passwords do not expire (recommended for cloud)" `
                -Impact "Modern best practice: no expiration with MFA" `
                -Reference "https://learn.microsoft.com/en-us/entra/identity/authentication/concept-password-ban-bad"
        } else {
            Write-CheckResult -Service "Azure AD" -Category "Password Policy" -CheckName "Password Expiration" `
                -Status "Info" -CurrentValue "Passwords expire after $passwordPolicy days" `
                -RecommendedValue "Consider disabling expiration and rely on MFA + monitoring"
        }
    } catch {
        Write-CheckResult -Service "Azure AD" -Category "Password Policy" -CheckName "Password Expiration" `
            -Status "Warning" -CurrentValue "Unable to verify password policy"
    }

    # Check Security Defaults
    try {
        $securityDefaults = Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy -ErrorAction SilentlyContinue
        if ($securityDefaults.IsEnabled) {
            Write-CheckResult -Service "Azure AD" -Category "Security Baseline" -CheckName "Security Defaults" `
                -Status "Pass" -CurrentValue "Enabled" `
                -Impact "Provides baseline security for all users" `
                -Reference "https://learn.microsoft.com/en-us/entra/fundamentals/security-defaults"
        } else {
            Write-CheckResult -Service "Azure AD" -Category "Security Baseline" -CheckName "Security Defaults" `
                -Status "Info" -CurrentValue "Disabled (may be using Conditional Access instead)" `
                -Impact "Ensure Conditional Access policies provide equivalent protection"
        }
    } catch {
        Write-CheckResult -Service "Azure AD" -Category "Security Baseline" -CheckName "Security Defaults" `
            -Status "Warning" -CurrentValue "Unable to verify"
    }

    # Check for risky users
    try {
        $riskyUsers = Get-MgRiskyUser -Filter "riskState eq 'atRisk'" -ErrorAction SilentlyContinue
        if ($riskyUsers.Count -eq 0) {
            Write-CheckResult -Service "Azure AD" -Category "Identity Protection" -CheckName "Risky Users" `
                -Status "Pass" -CurrentValue "No users currently at risk"
        } else {
            Write-CheckResult -Service "Azure AD" -Category "Identity Protection" -CheckName "Risky Users" `
                -Status "Warning" -CurrentValue "$($riskyUsers.Count) users flagged as risky" `
                -RecommendedValue "Investigate and remediate risky users" `
                -Impact "Potential compromised accounts" `
                -Reference "https://learn.microsoft.com/en-us/entra/id-protection/overview-identity-protection"
        }
    } catch {
        Write-CheckResult -Service "Azure AD" -Category "Identity Protection" -CheckName "Risky Users" `
            -Status "Info" -CurrentValue "Unable to query (requires Premium P2 license)"
    }
}
#endregion

#region Exchange Online Checks
function Test-ExchangeOnlineConfiguration {
    if ($SkipExchangeOnline) {
        Write-Host "`n=== Skipping Exchange Online checks ===" -ForegroundColor Yellow
        return
    }

    Write-Host "`n=== Exchange Online Security Configuration ===" -ForegroundColor Cyan

    # Check Anti-Malware policies
    try {
        $malwarePolicies = Get-MalwareFilterPolicy
        $defaultPolicy = $malwarePolicies | Where-Object { $_.IsDefault -eq $true }

        if ($defaultPolicy.EnableFileFilter) {
            Write-CheckResult -Service "Exchange" -Category "Malware Protection" -CheckName "Common Attachment Filter" `
                -Status "Pass" -CurrentValue "Enabled" `
                -Impact "Blocks common malicious file types" `
                -Reference "https://learn.microsoft.com/en-us/defender-office-365/anti-malware-protection-about"
        } else {
            Write-CheckResult -Service "Exchange" -Category "Malware Protection" -CheckName "Common Attachment Filter" `
                -Status "Warning" -CurrentValue "Disabled" `
                -RecommendedValue "Enable common attachment filtering" `
                -Impact "Increased malware risk"
        }
    } catch {
        Write-CheckResult -Service "Exchange" -Category "Malware Protection" -CheckName "Anti-Malware Policies" `
            -Status "Warning" -CurrentValue "Unable to verify configuration"
    }

    # Check Anti-Spam policies
    try {
        $spamPolicies = Get-HostedContentFilterPolicy
        $defaultSpamPolicy = $spamPolicies | Where-Object { $_.IsDefault -eq $true }

        if ($defaultSpamPolicy.EnableEndUserSpamNotifications) {
            Write-CheckResult -Service "Exchange" -Category "Spam Protection" -CheckName "End User Spam Notifications" `
                -Status "Pass" -CurrentValue "Enabled (every $($defaultSpamPolicy.EndUserSpamNotificationFrequency) days)" `
                -Impact "Users can review quarantined messages"
        } else {
            Write-CheckResult -Service "Exchange" -Category "Spam Protection" -CheckName "End User Spam Notifications" `
                -Status "Info" -CurrentValue "Disabled" `
                -RecommendedValue "Consider enabling user notifications"
        }
    } catch {
        Write-CheckResult -Service "Exchange" -Category "Spam Protection" -CheckName "Anti-Spam Policies" `
            -Status "Warning" -CurrentValue "Unable to verify configuration"
    }

    # Check DKIM signing
    try {
        $dkimConfig = Get-DkimSigningConfig | Where-Object { $_.Enabled -eq $true }
        if ($dkimConfig.Count -gt 0) {
            Write-CheckResult -Service "Exchange" -Category "Email Authentication" -CheckName "DKIM Signing" `
                -Status "Pass" -CurrentValue "Enabled for $($dkimConfig.Count) domain(s)" `
                -Impact "Authenticates outbound email, reduces spoofing" `
                -Reference "https://learn.microsoft.com/en-us/defender-office-365/email-authentication-dkim-configure"
        } else {
            Write-CheckResult -Service "Exchange" -Category "Email Authentication" -CheckName "DKIM Signing" `
                -Status "Fail" -CurrentValue "Not enabled for any domains" `
                -RecommendedValue "Enable DKIM signing for all sending domains" `
                -Impact "Email may be marked as spam or rejected" `
                -Reference "https://learn.microsoft.com/en-us/defender-office-365/email-authentication-dkim-configure"
        }
    } catch {
        Write-CheckResult -Service "Exchange" -Category "Email Authentication" -CheckName "DKIM Signing" `
            -Status "Warning" -CurrentValue "Unable to verify DKIM configuration"
    }

    # Check ATP/Defender for Office 365 policies
    try {
        $atpPolicies = Get-SafeAttachmentPolicy
        if ($atpPolicies.Count -gt 0) {
            $enabledATP = ($atpPolicies | Where-Object { $_.Enable -eq $true }).Count
            Write-CheckResult -Service "Exchange" -Category "Advanced Threat Protection" -CheckName "Safe Attachments" `
                -Status "Pass" -CurrentValue "$enabledATP policies enabled" `
                -Impact "Protects against zero-day malware" `
                -Reference "https://learn.microsoft.com/en-us/defender-office-365/safe-attachments-about"
        } else {
            Write-CheckResult -Service "Exchange" -Category "Advanced Threat Protection" -CheckName "Safe Attachments" `
                -Status "Warning" -CurrentValue "No policies configured" `
                -RecommendedValue "Configure Safe Attachments (requires Defender for Office 365)" `
                -Impact "Missing advanced malware protection"
        }

        $safeLinksPolicy = Get-SafeLinksPolicy
        if ($safeLinksPolicy.Count -gt 0) {
            Write-CheckResult -Service "Exchange" -Category "Advanced Threat Protection" -CheckName "Safe Links" `
                -Status "Pass" -CurrentValue "$($safeLinksPolicy.Count) policies configured" `
                -Impact "Protects against malicious URLs" `
                -Reference "https://learn.microsoft.com/en-us/defender-office-365/safe-links-about"
        } else {
            Write-CheckResult -Service "Exchange" -Category "Advanced Threat Protection" -CheckName "Safe Links" `
                -Status "Warning" -CurrentValue "No policies configured" `
                -RecommendedValue "Configure Safe Links (requires Defender for Office 365)"
        }
    } catch {
        Write-CheckResult -Service "Exchange" -Category "Advanced Threat Protection" -CheckName "Defender for Office 365" `
            -Status "Info" -CurrentValue "Not available (requires Defender for Office 365 license)"
    }

    # Check mailbox auditing
    try {
        $auditConfig = Get-OrganizationConfig | Select-Object AuditDisabled
        if (-not $auditConfig.AuditDisabled) {
            Write-CheckResult -Service "Exchange" -Category "Auditing" -CheckName "Mailbox Auditing" `
                -Status "Pass" -CurrentValue "Enabled by default" `
                -Impact "Tracks mailbox access and changes" `
                -Reference "https://learn.microsoft.com/en-us/purview/audit-mailboxes"
        } else {
            Write-CheckResult -Service "Exchange" -Category "Auditing" -CheckName "Mailbox Auditing" `
                -Status "Fail" -CurrentValue "Disabled" `
                -RecommendedValue "Enable mailbox auditing organization-wide" `
                -Impact "Cannot track security incidents"
        }
    } catch {
        Write-CheckResult -Service "Exchange" -Category "Auditing" -CheckName "Mailbox Auditing" `
            -Status "Warning" -CurrentValue "Unable to verify"
    }

    # Check for legacy protocols
    try {
        $orgConfig = Get-OrganizationConfig
        if ($orgConfig.OAuth2ClientProfileEnabled) {
            Write-CheckResult -Service "Exchange" -Category "Modern Authentication" -CheckName "OAuth2 Client Profile" `
                -Status "Pass" -CurrentValue "Enabled" `
                -Impact "Modern authentication for all clients"
        }
    } catch {
        Write-CheckResult -Service "Exchange" -Category "Modern Authentication" -CheckName "Modern Auth" `
            -Status "Info" -CurrentValue "Unable to verify configuration"
    }
}
#endregion

#region SharePoint/OneDrive Checks
function Test-SharePointConfiguration {
    if ($SkipSharePoint) {
        Write-Host "`n=== Skipping SharePoint Online checks ===" -ForegroundColor Yellow
        return
    }

    Write-Host "`n=== SharePoint Online Security Configuration ===" -ForegroundColor Cyan

    # Note: SharePoint checks require SharePoint Online Management Shell
    # Basic checks that can be done via Graph API

    Write-CheckResult -Service "SharePoint" -Category "Configuration" -CheckName "SharePoint Checks" `
        -Status "Info" -CurrentValue "Advanced SharePoint checks require SharePoint Online Management Shell" `
        -Reference "https://learn.microsoft.com/en-us/sharepoint/sharepoint-online"
}
#endregion

#region Microsoft Teams Checks
function Test-TeamsConfiguration {
    if ($SkipTeams) {
        Write-Host "`n=== Skipping Microsoft Teams checks ===" -ForegroundColor Yellow
        return
    }

    Write-Host "`n=== Microsoft Teams Security Configuration ===" -ForegroundColor Cyan

    try {
        # Check external access settings
        $teamsClientConfig = Get-CsTeamsClientConfiguration -ErrorAction SilentlyContinue
        if ($teamsClientConfig) {
            Write-CheckResult -Service "Teams" -Category "Collaboration" -CheckName "Teams Client Configuration" `
                -Status "Info" -CurrentValue "Configuration retrieved successfully" `
                -Reference "https://learn.microsoft.com/en-us/microsoftteams/teams-security-guide"
        }

        # Check meeting policies
        $meetingPolicies = Get-CsTeamsMeetingPolicy -ErrorAction SilentlyContinue
        if ($meetingPolicies) {
            $globalPolicy = $meetingPolicies | Where-Object { $_.Identity -eq "Global" }

            if ($globalPolicy.AllowAnonymousUsersToJoinMeeting -eq $false) {
                Write-CheckResult -Service "Teams" -Category "Meetings" -CheckName "Anonymous Meeting Join" `
                    -Status "Pass" -CurrentValue "Disabled (more secure)" `
                    -Impact "Prevents unauthorized meeting access"
            } else {
                Write-CheckResult -Service "Teams" -Category "Meetings" -CheckName "Anonymous Meeting Join" `
                    -Status "Info" -CurrentValue "Enabled (consider business need)" `
                    -Impact "Balance security with business requirements"
            }

            if ($globalPolicy.AutoAdmittedUsers -eq "EveryoneInCompany") {
                Write-CheckResult -Service "Teams" -Category "Meetings" -CheckName "Auto Admit Users" `
                    -Status "Pass" -CurrentValue "Company users only" `
                    -Impact "External users wait in lobby"
            }
        }
    } catch {
        Write-CheckResult -Service "Teams" -Category "Configuration" -CheckName "Teams Policies" `
            -Status "Warning" -CurrentValue "Unable to retrieve Teams configuration: $_"
    }
}
#endregion

#region Generate Report
function Export-M365Report {
    param($Results, $Path)

    # Export to CSV
    $csvPath = "$Path.csv"
    $Results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

    # Generate HTML report
    $htmlPath = "$Path.html"

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Microsoft 365 Security Configuration Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .header { background: linear-gradient(135deg, #0078d4 0%, #00bcf2 100%); color: white; padding: 30px; border-radius: 5px; margin-bottom: 20px; }
        .header h1 { margin: 0; font-size: 2em; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }
        .summary-card { background: white; padding: 20px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); text-align: center; }
        .summary-number { font-size: 2.5em; font-weight: bold; margin: 10px 0; }
        .pass { color: #107c10; }
        .fail { color: #d13438; }
        .warning { color: #ff8c00; }
        .info { color: #0078d4; }
        .service-section { background: white; margin: 20px 0; padding: 20px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        th { background: #0078d4; color: white; padding: 12px; text-align: left; font-weight: 600; }
        td { padding: 10px; border-bottom: 1px solid #e0e0e0; }
        tr:hover { background: #f8f8f8; }
        .status-badge { padding: 5px 12px; border-radius: 3px; font-weight: bold; font-size: 0.85em; display: inline-block; }
        .status-Pass { background: #dff6dd; color: #107c10; }
        .status-Fail { background: #fde7e9; color: #d13438; }
        .status-Warning { background: #fff4ce; color: #ff8c00; }
        .status-Info { background: #e6f3ff; color: #0078d4; }
        .status-NotConfigured { background: #f0f0f0; color: #666; }
        .impact { color: #666; font-size: 0.9em; font-style: italic; }
        .footer { text-align: center; color: #666; margin: 30px 0; padding: 20px; }
        a { color: #0078d4; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🛡️ Microsoft 365 Security Configuration Report</h1>
        <p>Tenant: $TenantDomain | Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>

    <div class="summary">
        <div class="summary-card">
            <div>Total Checks</div>
            <div class="summary-number">$($Results.Count)</div>
        </div>
        <div class="summary-card">
            <div class="summary-number pass">$(($Results | Where-Object Status -eq 'Pass').Count)</div>
            <div>Passed</div>
        </div>
        <div class="summary-card">
            <div class="summary-number fail">$(($Results | Where-Object Status -eq 'Fail').Count)</div>
            <div>Failed</div>
        </div>
        <div class="summary-card">
            <div class="summary-number warning">$(($Results | Where-Object Status -eq 'Warning').Count)</div>
            <div>Warnings</div>
        </div>
        <div class="summary-card">
            <div class="summary-number info">$(($Results | Where-Object Status -eq 'Info').Count)</div>
            <div>Info</div>
        </div>
    </div>
"@

    # Group results by service
    $services = $Results | Group-Object -Property Service

    foreach ($service in $services) {
        $html += @"
    <div class="service-section">
        <h2>$($service.Name)</h2>
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
        foreach ($result in $service.Group) {
            $html += @"
                <tr>
                    <td>$($result.Category)</td>
                    <td><strong>$($result.Check)</strong></td>
                    <td><span class="status-badge status-$($result.Status)">$($result.Status)</span></td>
                    <td>
                        Current: $($result.CurrentValue)
                        $(if ($result.RecommendedValue) { "<br>Recommended: <strong>$($result.RecommendedValue)</strong>" })
                        $(if ($result.Impact) { "<br><span class='impact'>Impact: $($result.Impact)</span>" })
                        $(if ($result.Reference) { "<br><a href='$($result.Reference)' target='_blank'>📚 Learn More</a>" })
                    </td>
                </tr>
"@
        }
        $html += @"
            </tbody>
        </table>
    </div>
"@
    }

    $html += @"
    <div class="footer">
        <p><strong>Microsoft 365 Security Configuration Checker v1.0</strong></p>
        <p>Based on Microsoft security best practices and CSS-Exchange tools</p>
        <p>
            <a href="https://learn.microsoft.com/en-us/microsoft-365/security/" target="_blank">Microsoft 365 Security</a> |
            <a href="https://github.com/microsoft/CSS-Exchange" target="_blank">CSS-Exchange GitHub</a>
        </p>
    </div>
</body>
</html>
"@

    $html | Out-File -FilePath $htmlPath -Encoding UTF8

    return @{
        HTML = $htmlPath
        CSV = $csvPath
    }
}
#endregion

#region Main Execution
function Main {
    Write-Host @"
╔═══════════════════════════════════════════════════════════════════╗
║   Microsoft 365 Security & Configuration Checker                 ║
║   Based on Microsoft CSS-Exchange and Security Best Practices    ║
╚═══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

    # Check required modules
    Test-RequiredModules

    # Connect to services
    Connect-M365Services

    # Run checks
    Test-AzureADConfiguration
    Test-ExchangeOnlineConfiguration
    Test-SharePointConfiguration
    Test-TeamsConfiguration

    # Generate summary
    $endTime = Get-Date
    $duration = $endTime - $Script:StartTime

    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    Write-Host "Total Checks: $($Script:Results.Count)" -ForegroundColor White
    Write-Host "Passed: $(($Script:Results | Where-Object Status -eq 'Pass').Count)" -ForegroundColor Green
    Write-Host "Failed: $(($Script:Results | Where-Object Status -eq 'Fail').Count)" -ForegroundColor Red
    Write-Host "Warnings: $(($Script:Results | Where-Object Status -eq 'Warning').Count)" -ForegroundColor Yellow
    Write-Host "Info: $(($Script:Results | Where-Object Status -eq 'Info').Count)" -ForegroundColor Cyan
    Write-Host "Duration: $([math]::Round($duration.TotalSeconds, 2)) seconds" -ForegroundColor White

    # Export reports
    Write-Host "`nGenerating reports..." -ForegroundColor Cyan
    $reportPaths = Export-M365Report -Results $Script:Results -Path $ExportPath
    Write-Host "HTML Report: $($reportPaths.HTML)" -ForegroundColor Green
    Write-Host "CSV Export: $($reportPaths.CSV)" -ForegroundColor Green

    # Disconnect
    Write-Host "`nDisconnecting from services..." -ForegroundColor Yellow
    Disconnect-MgGraph -ErrorAction SilentlyContinue
    Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
    Disconnect-MicrosoftTeams -ErrorAction SilentlyContinue

    # Open HTML report
    try {
        Start-Process $reportPaths.HTML
    } catch {
        Write-Host "Could not automatically open report. Please open manually." -ForegroundColor Yellow
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
