<#
.SYNOPSIS
    Azure Deployment and Compliance Best Practices Checker

.DESCRIPTION
    Comprehensive script to audit Azure subscriptions for security, compliance,
    and best practices based on Microsoft Cloud Adoption Framework and Azure Well-Architected Framework.

.NOTES
    Author: System Operations Team
    Version: 1.0
    References:
    - https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/
    - https://learn.microsoft.com/en-us/azure/well-architected/
    - https://learn.microsoft.com/en-us/azure/governance/policy/

.PREREQUISITES
    Install required modules:
    Install-Module -Name Az -Force -AllowClobber
    Connect-AzAccount

.EXAMPLE
    .\Azure-BestPractices-Checker.ps1
    .\Azure-BestPractices-Checker.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012"
    .\Azure-BestPractices-Checker.ps1 -ExportPath "C:\Reports\AzureAudit"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,

    [Parameter(Mandatory=$false)]
    [string]$ExportPath = "$env:TEMP\AzureBestPractices_$(Get-Date -Format 'yyyyMMdd_HHmmss')",

    [Parameter(Mandatory=$false)]
    [switch]$IncludeCostAnalysis,

    [Parameter(Mandatory=$false)]
    [switch]$CheckAllSubscriptions
)

#Requires -Modules Az.Accounts, Az.Resources, Az.Security, Az.Monitor

$Script:Results = @()
$Script:StartTime = Get-Date
$Script:Subscriptions = @()

function Write-CheckResult {
    param(
        [string]$Subscription,
        [string]$Category,
        [string]$CheckName,
        [string]$Status,  # Pass, Fail, Warning, Info
        [string]$ResourceName = "",
        [string]$CurrentValue,
        [string]$RecommendedValue = "",
        [string]$Impact = "",
        [string]$Reference = ""
    )

    $Script:Results += [PSCustomObject]@{
        Subscription = $Subscription
        Category = $Category
        Check = $CheckName
        Resource = $ResourceName
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
        default { "White" }
    }

    $resourceInfo = if ($ResourceName) { " [$ResourceName]" } else { "" }
    Write-Host "[$Status] $CheckName$resourceInfo" -ForegroundColor $color
}

function Test-AzureConnection {
    Write-Host "`n=== Checking Azure Connection ===" -ForegroundColor Cyan

    try {
        $context = Get-AzContext
        if (-not $context) {
            Write-Host "Not connected to Azure. Please run Connect-AzAccount first." -ForegroundColor Red
            throw "Azure connection required"
        }

        Write-Host "✓ Connected as: $($context.Account.Id)" -ForegroundColor Green
        Write-Host "✓ Tenant: $($context.Tenant.Id)" -ForegroundColor Green

        # Get subscriptions
        if ($CheckAllSubscriptions) {
            $Script:Subscriptions = Get-AzSubscription | Where-Object { $_.State -eq "Enabled" }
            Write-Host "✓ Will check $($Script:Subscriptions.Count) enabled subscription(s)" -ForegroundColor Green
        } elseif ($SubscriptionId) {
            $Script:Subscriptions = @(Get-AzSubscription -SubscriptionId $SubscriptionId)
        } else {
            $Script:Subscriptions = @(Get-AzSubscription -SubscriptionId $context.Subscription.Id)
        }

        Write-Host "✓ Target subscription(s): $($Script:Subscriptions.Count)" -ForegroundColor Green

    } catch {
        Write-Host "Error checking Azure connection: $_" -ForegroundColor Red
        throw
    }
}

#region Security Center / Defender for Cloud
function Test-SecurityCenter {
    param($SubscriptionName)

    Write-Host "`n=== Microsoft Defender for Cloud (Security Center) ===" -ForegroundColor Cyan

    try {
        # Check Defender for Cloud pricing tier
        $pricings = Get-AzSecurityPricing

        $enabledServices = $pricings | Where-Object { $_.PricingTier -eq "Standard" }
        $freeServices = $pricings | Where-Object { $_.PricingTier -eq "Free" }

        if ($enabledServices.Count -gt 0) {
            Write-CheckResult -Subscription $SubscriptionName -Category "Security" -CheckName "Defender for Cloud" `
                -Status "Pass" -CurrentValue "$($enabledServices.Count) services on Standard tier" `
                -Impact "Enhanced threat protection enabled" `
                -Reference "https://learn.microsoft.com/en-us/azure/defender-for-cloud/"
        } else {
            Write-CheckResult -Subscription $SubscriptionName -Category "Security" -CheckName "Defender for Cloud" `
                -Status "Warning" -CurrentValue "All services on Free tier" `
                -RecommendedValue "Enable Standard tier for critical resources" `
                -Impact "Limited security features and threat protection" `
                -Reference "https://learn.microsoft.com/en-us/azure/defender-for-cloud/enhanced-security-features-overview"
        }

        # Check security contacts
        $securityContacts = Get-AzSecurityContact
        if ($securityContacts.Count -gt 0) {
            Write-CheckResult -Subscription $SubscriptionName -Category "Security" -CheckName "Security Contacts" `
                -Status "Pass" -CurrentValue "$($securityContacts.Count) contact(s) configured" `
                -Impact "Security alerts will be sent to designated contacts"
        } else {
            Write-CheckResult -Subscription $SubscriptionName -Category "Security" -CheckName "Security Contacts" `
                -Status "Fail" -CurrentValue "No security contacts configured" `
                -RecommendedValue "Configure security contacts to receive alerts" `
                -Impact "Security incidents may go unnoticed" `
                -Reference "https://learn.microsoft.com/en-us/azure/defender-for-cloud/configure-email-notifications"
        }

        # Check auto-provisioning
        $autoProvisionSettings = Get-AzSecurityAutoProvisioningSetting
        $logsEnabled = $autoProvisionSettings | Where-Object { $_.AutoProvision -eq "On" }

        if ($logsEnabled.Count -gt 0) {
            Write-CheckResult -Subscription $SubscriptionName -Category "Security" -CheckName "Auto-Provisioning" `
                -Status "Pass" -CurrentValue "Enabled" `
                -Impact "Automatic deployment of monitoring agents"
        } else {
            Write-CheckResult -Subscription $SubscriptionName -Category "Security" -CheckName "Auto-Provisioning" `
                -Status "Warning" -CurrentValue "Disabled" `
                -RecommendedValue "Enable auto-provisioning for monitoring agents" `
                -Impact "Manual agent deployment required"
        }

    } catch {
        Write-CheckResult -Subscription $SubscriptionName -Category "Security" -CheckName "Defender for Cloud" `
            -Status "Warning" -CurrentValue "Unable to verify: $_"
    }
}
#endregion

#region RBAC and Identity
function Test-IAMBestPractices {
    param($SubscriptionName)

    Write-Host "`n=== Identity and Access Management (IAM) ===" -ForegroundColor Cyan

    try {
        # Check for classic administrators
        $classicAdmins = Get-AzRoleAssignment | Where-Object {
            $_.RoleDefinitionName -in @("CoAdministrator", "ServiceAdministrator", "AccountAdministrator")
        }

        if ($classicAdmins.Count -eq 0) {
            Write-CheckResult -Subscription $SubscriptionName -Category "IAM" -CheckName "Classic Administrators" `
                -Status "Pass" -CurrentValue "No classic administrators" `
                -Impact "Using modern RBAC only"
        } else {
            Write-CheckResult -Subscription $SubscriptionName -Category "IAM" -CheckName "Classic Administrators" `
                -Status "Warning" -CurrentValue "$($classicAdmins.Count) classic administrator(s) found" `
                -RecommendedValue "Migrate to Azure RBAC" `
                -Impact "Classic roles are deprecated" `
                -Reference "https://learn.microsoft.com/en-us/azure/role-based-access-control/classic-administrators"
        }

        # Check for Owner assignments at subscription level
        $owners = Get-AzRoleAssignment -RoleDefinitionName "Owner" -Scope "/subscriptions/$((Get-AzContext).Subscription.Id)"

        if ($owners.Count -le 3) {
            Write-CheckResult -Subscription $SubscriptionName -Category "IAM" -CheckName "Subscription Owners" `
                -Status "Pass" -CurrentValue "$($owners.Count) owner(s) at subscription level" `
                -Impact "Limited privileged access"
        } elseif ($owners.Count -le 5) {
            Write-CheckResult -Subscription $SubscriptionName -Category "IAM" -CheckName "Subscription Owners" `
                -Status "Info" -CurrentValue "$($owners.Count) owner(s) at subscription level" `
                -RecommendedValue "Review and minimize owner assignments"
        } else {
            Write-CheckResult -Subscription $SubscriptionName -Category "IAM" -CheckName "Subscription Owners" `
                -Status "Warning" -CurrentValue "$($owners.Count) owner(s) at subscription level" `
                -RecommendedValue "Reduce number of owners (recommended: 2-3)" `
                -Impact "Too many privileged users increases risk" `
                -Reference "https://learn.microsoft.com/en-us/azure/role-based-access-control/best-practices"
        }

        # Check for custom roles
        $customRoles = Get-AzRoleDefinition | Where-Object { $_.IsCustom -eq $true }
        if ($customRoles.Count -gt 0) {
            Write-CheckResult -Subscription $SubscriptionName -Category "IAM" -CheckName "Custom RBAC Roles" `
                -Status "Info" -CurrentValue "$($customRoles.Count) custom role(s) defined" `
                -Impact "Review custom roles for least privilege" `
                -Reference "https://learn.microsoft.com/en-us/azure/role-based-access-control/custom-roles"
        }

    } catch {
        Write-CheckResult -Subscription $SubscriptionName -Category "IAM" -CheckName "IAM Configuration" `
            -Status "Warning" -CurrentValue "Unable to verify: $_"
    }
}
#endregion

#region Azure Policy
function Test-AzurePolicy {
    param($SubscriptionName)

    Write-Host "`n=== Azure Policy and Compliance ===" -ForegroundColor Cyan

    try {
        # Check policy assignments
        $policyAssignments = Get-AzPolicyAssignment -Scope "/subscriptions/$((Get-AzContext).Subscription.Id)"

        if ($policyAssignments.Count -gt 0) {
            Write-CheckResult -Subscription $SubscriptionName -Category "Governance" -CheckName "Azure Policies" `
                -Status "Pass" -CurrentValue "$($policyAssignments.Count) policy assignment(s)" `
                -Impact "Governance controls are in place" `
                -Reference "https://learn.microsoft.com/en-us/azure/governance/policy/"
        } else {
            Write-CheckResult -Subscription $SubscriptionName -Category "Governance" -CheckName "Azure Policies" `
                -Status "Warning" -CurrentValue "No policies assigned" `
                -RecommendedValue "Assign built-in or custom policies for governance" `
                -Impact "No automated compliance enforcement" `
                -Reference "https://learn.microsoft.com/en-us/azure/governance/policy/samples/built-in-policies"
        }

        # Check for policy compliance state
        $policyStates = Get-AzPolicyState -Filter "ComplianceState eq 'NonCompliant'" -Top 100

        if ($policyStates.Count -eq 0) {
            Write-CheckResult -Subscription $SubscriptionName -Category "Governance" -CheckName "Policy Compliance" `
                -Status "Pass" -CurrentValue "All resources compliant" `
                -Impact "Meeting policy requirements"
        } else {
            Write-CheckResult -Subscription $SubscriptionName -Category "Governance" -CheckName "Policy Compliance" `
                -Status "Warning" -CurrentValue "$($policyStates.Count) non-compliant resource(s)" `
                -RecommendedValue "Review and remediate non-compliant resources" `
                -Impact "Policy violations detected" `
                -Reference "https://learn.microsoft.com/en-us/azure/governance/policy/how-to/get-compliance-data"
        }

    } catch {
        Write-CheckResult -Subscription $SubscriptionName -Category "Governance" -CheckName "Azure Policy" `
            -Status "Warning" -CurrentValue "Unable to verify: $_"
    }
}
#endregion

#region Resource Locks
function Test-ResourceLocks {
    param($SubscriptionName)

    Write-Host "`n=== Resource Locks ===" -ForegroundColor Cyan

    try {
        # Check for locks on critical resource groups
        $resourceGroups = Get-AzResourceGroup
        $lockedRGs = 0
        $criticalRGs = 0

        foreach ($rg in $resourceGroups) {
            # Consider RGs with "prod", "production", or infrastructure resources as critical
            $isCritical = $rg.ResourceGroupName -match "prod|production|infrastructure|core"

            if ($isCritical) {
                $criticalRGs++
                $locks = Get-AzResourceLock -ResourceGroupName $rg.ResourceGroupName
                if ($locks.Count -gt 0) {
                    $lockedRGs++
                }
            }
        }

        if ($criticalRGs -eq 0) {
            Write-CheckResult -Subscription $SubscriptionName -Category "Governance" -CheckName "Resource Locks" `
                -Status "Info" -CurrentValue "No critical resource groups detected" `
                -Impact "Consider applying locks to production resources"
        } elseif ($lockedRGs -eq $criticalRGs) {
            Write-CheckResult -Subscription $SubscriptionName -Category "Governance" -CheckName "Resource Locks" `
                -Status "Pass" -CurrentValue "All $criticalRGs critical RG(s) have locks" `
                -Impact "Protected against accidental deletion" `
                -Reference "https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources"
        } else {
            Write-CheckResult -Subscription $SubscriptionName -Category "Governance" -CheckName "Resource Locks" `
                -Status "Warning" -CurrentValue "$lockedRGs of $criticalRGs critical RG(s) have locks" `
                -RecommendedValue "Apply CanNotDelete locks to production resources" `
                -Impact "Risk of accidental deletion" `
                -Reference "https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources"
        }

    } catch {
        Write-CheckResult -Subscription $SubscriptionName -Category "Governance" -CheckName "Resource Locks" `
            -Status "Warning" -CurrentValue "Unable to verify: $_"
    }
}
#endregion

#region Networking Security
function Test-NetworkSecurity {
    param($SubscriptionName)

    Write-Host "`n=== Network Security ===" -ForegroundColor Cyan

    try {
        # Check Network Security Groups
        $nsgs = Get-AzNetworkSecurityGroup

        if ($nsgs.Count -gt 0) {
            $insecureRules = @()

            foreach ($nsg in $nsgs) {
                # Check for overly permissive rules (Any source, Any destination, Allow)
                foreach ($rule in $nsg.SecurityRules) {
                    if ($rule.Access -eq "Allow" -and
                        $rule.SourceAddressPrefix -eq "*" -and
                        $rule.DestinationAddressPrefix -eq "*") {
                        $insecureRules += "$($nsg.Name)/$($rule.Name)"
                    }
                }
            }

            if ($insecureRules.Count -eq 0) {
                Write-CheckResult -Subscription $SubscriptionName -Category "Network" -CheckName "NSG Security Rules" `
                    -Status "Pass" -CurrentValue "$($nsgs.Count) NSG(s), no overly permissive rules" `
                    -Impact "Network segmentation properly configured"
            } else {
                Write-CheckResult -Subscription $SubscriptionName -Category "Network" -CheckName "NSG Security Rules" `
                    -Status "Warning" -CurrentValue "$($insecureRules.Count) overly permissive rule(s) found" `
                    -RecommendedValue "Restrict NSG rules to specific sources/destinations" `
                    -Impact "Potential security exposure" `
                    -Reference "https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview"
            }
        }

        # Check for Network Watcher
        $networkWatchers = Get-AzNetworkWatcher
        if ($networkWatchers.Count -gt 0) {
            Write-CheckResult -Subscription $SubscriptionName -Category "Network" -CheckName "Network Watcher" `
                -Status "Pass" -CurrentValue "Enabled in $($networkWatchers.Count) region(s)" `
                -Impact "Network monitoring and diagnostics available" `
                -Reference "https://learn.microsoft.com/en-us/azure/network-watcher/"
        } else {
            Write-CheckResult -Subscription $SubscriptionName -Category "Network" -CheckName "Network Watcher" `
                -Status "Warning" -CurrentValue "Not enabled" `
                -RecommendedValue "Enable Network Watcher for network monitoring" `
                -Impact "Limited network visibility"
        }

    } catch {
        Write-CheckResult -Subscription $SubscriptionName -Category "Network" -CheckName "Network Security" `
            -Status "Warning" -CurrentValue "Unable to verify: $_"
    }
}
#endregion

#region Monitoring and Logging
function Test-MonitoringLogging {
    param($SubscriptionName)

    Write-Host "`n=== Monitoring and Logging ===" -ForegroundColor Cyan

    try {
        # Check for Log Analytics workspaces
        $workspaces = Get-AzOperationalInsightsWorkspace

        if ($workspaces.Count -gt 0) {
            Write-CheckResult -Subscription $SubscriptionName -Category "Monitoring" -CheckName "Log Analytics" `
                -Status "Pass" -CurrentValue "$($workspaces.Count) workspace(s) configured" `
                -Impact "Centralized logging available" `
                -Reference "https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-overview"
        } else {
            Write-CheckResult -Subscription $SubscriptionName -Category "Monitoring" -CheckName "Log Analytics" `
                -Status "Warning" -CurrentValue "No Log Analytics workspaces" `
                -RecommendedValue "Create Log Analytics workspace for centralized logging" `
                -Impact "No centralized log collection" `
                -Reference "https://learn.microsoft.com/en-us/azure/azure-monitor/logs/quick-create-workspace"
        }

        # Check Activity Log diagnostic settings
        $subscriptionId = (Get-AzContext).Subscription.Id
        $diagSettings = Get-AzDiagnosticSetting -ResourceId "/subscriptions/$subscriptionId" -ErrorAction SilentlyContinue

        if ($diagSettings) {
            Write-CheckResult -Subscription $SubscriptionName -Category "Monitoring" -CheckName "Activity Log Export" `
                -Status "Pass" -CurrentValue "Activity logs are being exported" `
                -Impact "Audit trail preserved" `
                -Reference "https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/activity-log"
        } else {
            Write-CheckResult -Subscription $SubscriptionName -Category "Monitoring" -CheckName "Activity Log Export" `
                -Status "Warning" -CurrentValue "Activity logs not exported" `
                -RecommendedValue "Configure diagnostic settings for Activity Log" `
                -Impact "Audit logs may be lost after retention period" `
                -Reference "https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings"
        }

        # Check for action groups (alerting)
        $actionGroups = Get-AzActionGroup
        if ($actionGroups.Count -gt 0) {
            Write-CheckResult -Subscription $SubscriptionName -Category "Monitoring" -CheckName "Alert Action Groups" `
                -Status "Pass" -CurrentValue "$($actionGroups.Count) action group(s) configured" `
                -Impact "Alert notifications configured"
        } else {
            Write-CheckResult -Subscription $SubscriptionName -Category "Monitoring" -CheckName "Alert Action Groups" `
                -Status "Warning" -CurrentValue "No action groups configured" `
                -RecommendedValue "Create action groups for alert notifications" `
                -Impact "Alerts may not be delivered" `
                -Reference "https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups"
        }

    } catch {
        Write-CheckResult -Subscription $SubscriptionName -Category "Monitoring" -CheckName "Monitoring" `
            -Status "Warning" -CurrentValue "Unable to verify: $_"
    }
}
#endregion

#region Backup and DR
function Test-BackupDR {
    param($SubscriptionName)

    Write-Host "`n=== Backup and Disaster Recovery ===" -ForegroundColor Cyan

    try {
        # Check for Recovery Services vaults
        $vaults = Get-AzRecoveryServicesVault

        if ($vaults.Count -gt 0) {
            Write-CheckResult -Subscription $SubscriptionName -Category "Backup" -CheckName "Recovery Services Vaults" `
                -Status "Pass" -CurrentValue "$($vaults.Count) vault(s) configured" `
                -Impact "Backup infrastructure in place" `
                -Reference "https://learn.microsoft.com/en-us/azure/backup/"
        } else {
            Write-CheckResult -Subscription $SubscriptionName -Category "Backup" -CheckName "Recovery Services Vaults" `
                -Status "Info" -CurrentValue "No Recovery Services vaults" `
                -RecommendedValue "Consider Azure Backup for critical resources" `
                -Impact "No native Azure backup configured"
        }

        # Check VMs for backup
        $vms = Get-AzVM
        if ($vms.Count -gt 0) {
            $backedUpVMs = 0
            foreach ($vault in $vaults) {
                Set-AzRecoveryServicesVaultContext -Vault $vault
                $containers = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM
                $backedUpVMs += $containers.Count
            }

            if ($backedUpVMs -eq $vms.Count) {
                Write-CheckResult -Subscription $SubscriptionName -Category "Backup" -CheckName "VM Backup Coverage" `
                    -Status "Pass" -CurrentValue "All $($vms.Count) VM(s) backed up" `
                    -Impact "Full VM protection"
            } elseif ($backedUpVMs -gt 0) {
                Write-CheckResult -Subscription $SubscriptionName -Category "Backup" -CheckName "VM Backup Coverage" `
                    -Status "Warning" -CurrentValue "$backedUpVMs of $($vms.Count) VM(s) backed up" `
                    -RecommendedValue "Enable backup for all production VMs" `
                    -Impact "Some VMs not protected" `
                    -Reference "https://learn.microsoft.com/en-us/azure/backup/backup-azure-vms-introduction"
            } else {
                Write-CheckResult -Subscription $SubscriptionName -Category "Backup" -CheckName "VM Backup Coverage" `
                    -Status "Warning" -CurrentValue "No VMs are backed up" `
                    -RecommendedValue "Enable Azure Backup for VMs" `
                    -Impact "No VM protection"
            }
        }

    } catch {
        Write-CheckResult -Subscription $SubscriptionName -Category "Backup" -CheckName "Backup Configuration" `
            -Status "Warning" -CurrentValue "Unable to verify: $_"
    }
}
#endregion

#region Cost Management
function Test-CostManagement {
    param($SubscriptionName)

    if (-not $IncludeCostAnalysis) {
        Write-Host "`n=== Skipping Cost Analysis (use -IncludeCostAnalysis to enable) ===" -ForegroundColor Yellow
        return
    }

    Write-Host "`n=== Cost Management ===" -ForegroundColor Cyan

    try {
        # Check for budgets
        $budgets = Get-AzConsumptionBudget -ErrorAction SilentlyContinue

        if ($budgets.Count -gt 0) {
            Write-CheckResult -Subscription $SubscriptionName -Category "Cost" -CheckName "Budgets" `
                -Status "Pass" -CurrentValue "$($budgets.Count) budget(s) configured" `
                -Impact "Cost monitoring and alerts in place" `
                -Reference "https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets"
        } else {
            Write-CheckResult -Subscription $SubscriptionName -Category "Cost" -CheckName "Budgets" `
                -Status "Warning" -CurrentValue "No budgets configured" `
                -RecommendedValue "Create budgets to monitor spending" `
                -Impact "No proactive cost alerts" `
                -Reference "https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets"
        }

    } catch {
        Write-CheckResult -Subscription $SubscriptionName -Category "Cost" -CheckName "Cost Management" `
            -Status "Info" -CurrentValue "Unable to verify cost settings"
    }
}
#endregion

#region Report Generation
function Export-AzureReport {
    param($Results, $Path)

    # Export CSV
    $csvPath = "$Path.csv"
    $Results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

    # Generate HTML
    $htmlPath = "$Path.html"

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Best Practices Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .header { background: linear-gradient(135deg, #0078d4 0%, #00bcf2 100%); color: white; padding: 30px; border-radius: 5px; }
        .header h1 { margin: 0; font-size: 2.5em; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 15px; margin: 20px 0; }
        .summary-card { background: white; padding: 20px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); text-align: center; }
        .summary-number { font-size: 2.5em; font-weight: bold; margin: 10px 0; }
        .pass { color: #107c10; }
        .fail { color: #d13438; }
        .warning { color: #ff8c00; }
        .info { color: #0078d4; }
        .section { background: white; margin: 20px 0; padding: 20px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        th { background: #0078d4; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #e0e0e0; }
        tr:hover { background: #f8f8f8; }
        .status-badge { padding: 5px 12px; border-radius: 3px; font-weight: bold; font-size: 0.85em; }
        .status-Pass { background: #dff6dd; color: #107c10; }
        .status-Fail { background: #fde7e9; color: #d13438; }
        .status-Warning { background: #fff4ce; color: #ff8c00; }
        .status-Info { background: #e6f3ff; color: #0078d4; }
        .footer { text-align: center; color: #666; margin: 30px 0; }
        a { color: #0078d4; }
    </style>
</head>
<body>
    <div class="header">
        <h1>☁️ Azure Best Practices Report</h1>
        <p>Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
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

    # Group by subscription then category
    $subscriptions = $Results | Group-Object -Property Subscription

    foreach ($sub in $subscriptions) {
        $html += "<div class='section'><h2>Subscription: $($sub.Name)</h2>"

        $categories = $sub.Group | Group-Object -Property Category
        foreach ($cat in $categories) {
            $html += "<h3>$($cat.Name)</h3><table><thead><tr><th>Check</th><th>Status</th><th>Details</th></tr></thead><tbody>"

            foreach ($result in $cat.Group) {
                $html += @"
                <tr>
                    <td><strong>$($result.Check)</strong>$(if($result.Resource){"<br><small>$($result.Resource)</small>"})</td>
                    <td><span class="status-badge status-$($result.Status)">$($result.Status)</span></td>
                    <td>
                        $($result.CurrentValue)
                        $(if($result.RecommendedValue){"<br>→ <strong>$($result.RecommendedValue)</strong>"})
                        $(if($result.Impact){"<br><em>$($result.Impact)</em>"})
                        $(if($result.Reference){"<br><a href='$($result.Reference)' target='_blank'>📚 Reference</a>"})
                    </td>
                </tr>
"@
            }
            $html += "</tbody></table>"
        }
        $html += "</div>"
    }

    $html += @"
    <div class="footer">
        <p><strong>Azure Best Practices Checker v1.0</strong></p>
        <p>Based on Azure Well-Architected Framework and Cloud Adoption Framework</p>
        <p><a href="https://learn.microsoft.com/en-us/azure/well-architected/" target="_blank">Azure Well-Architected Framework</a></p>
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
║   Azure Best Practices and Compliance Checker                    ║
║   Based on Azure Well-Architected Framework                      ║
╚═══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

    # Test connection
    Test-AzureConnection

    # Run checks for each subscription
    foreach ($subscription in $Script:Subscriptions) {
        Write-Host "`n========================================" -ForegroundColor Magenta
        Write-Host "Checking Subscription: $($subscription.Name)" -ForegroundColor Magenta
        Write-Host "========================================" -ForegroundColor Magenta

        Set-AzContext -SubscriptionId $subscription.Id | Out-Null

        Test-SecurityCenter -SubscriptionName $subscription.Name
        Test-IAMBestPractices -SubscriptionName $subscription.Name
        Test-AzurePolicy -SubscriptionName $subscription.Name
        Test-ResourceLocks -SubscriptionName $subscription.Name
        Test-NetworkSecurity -SubscriptionName $subscription.Name
        Test-MonitoringLogging -SubscriptionName $subscription.Name
        Test-BackupDR -SubscriptionName $subscription.Name
        Test-CostManagement -SubscriptionName $subscription.Name
    }

    # Summary
    $endTime = Get-Date
    $duration = $endTime - $Script:StartTime

    Write-Host "`n=== Overall Summary ===" -ForegroundColor Cyan
    Write-Host "Subscriptions Checked: $($Script:Subscriptions.Count)" -ForegroundColor White
    Write-Host "Total Checks: $($Script:Results.Count)" -ForegroundColor White
    Write-Host "Passed: $(($Script:Results | Where-Object Status -eq 'Pass').Count)" -ForegroundColor Green
    Write-Host "Failed: $(($Script:Results | Where-Object Status -eq 'Fail').Count)" -ForegroundColor Red
    Write-Host "Warnings: $(($Script:Results | Where-Object Status -eq 'Warning').Count)" -ForegroundColor Yellow
    Write-Host "Info: $(($Script:Results | Where-Object Status -eq 'Info').Count)" -ForegroundColor Cyan
    Write-Host "Duration: $([math]::Round($duration.TotalSeconds, 2)) seconds" -ForegroundColor White

    # Export report
    Write-Host "`nGenerating reports..." -ForegroundColor Cyan
    $reportPaths = Export-AzureReport -Results $Script:Results -Path $ExportPath
    Write-Host "HTML Report: $($reportPaths.HTML)" -ForegroundColor Green
    Write-Host "CSV Export: $($reportPaths.CSV)" -ForegroundColor Green

    # Open report
    try {
        Start-Process $reportPaths.HTML
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
