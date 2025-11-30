# System Operations Best Practices Scripts

Comprehensive PowerShell scripts for checking best practices, configurations, and deployments for Microsoft (Windows, M365, Azure) and Dell products. These scripts are based on authoritative sources from Microsoft and Dell official repositories.

## 📋 Table of Contents

- [Overview](#overview)
- [Scripts](#scripts)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Documentation](#detailed-documentation)
- [References](#references)

---

## 🎯 Overview

This collection includes enterprise-grade auditing and health check scripts for:

- **Windows Server** - Security baseline, updates, performance, and configuration
- **Microsoft 365** - Security settings, compliance, Exchange Online, Teams, Azure AD
- **Azure** - Governance, security, networking, monitoring, and compliance
- **Dell Hardware** - Hardware health, RAID status, firmware, and environmental monitoring

All scripts generate detailed HTML reports with actionable recommendations based on official Microsoft and Dell best practices.

---

## 📁 Scripts

### 1. Windows-Server-BestPractices.ps1

Comprehensive Windows Server configuration and security audit based on Microsoft Security Compliance Toolkit.

**Features:**
- Security baseline checks (Defender, Firewall, UAC, SMBv1, LSA Protection)
- Windows Update compliance and patch status
- Performance monitoring (disk space, memory, page file)
- Event log analysis (critical errors, failed logons)
- Critical service status verification
- Time synchronization validation

**Usage:**
```powershell
# Basic usage with default HTML report
.\Windows-Server-BestPractices.ps1

# Custom export path with detailed logs
.\Windows-Server-BestPractices.ps1 -ExportPath "C:\Reports\ServerAudit.html" -IncludeDetailedLogs
```

**Requirements:**
- Windows Server 2012 R2 or later
- Administrator privileges
- PowerShell 5.1 or later

---

### 2. M365-Security-ConfigCheck.ps1

Microsoft 365 tenant security and configuration auditing across Exchange Online, Azure AD, SharePoint, and Teams.

**Features:**
- **Azure AD/Entra ID**: MFA policies, Conditional Access, password policies, security defaults, risky users
- **Exchange Online**: Anti-malware, anti-spam, DKIM signing, Safe Attachments/Links, mailbox auditing
- **Microsoft Teams**: Meeting policies, external access, collaboration settings
- **SharePoint Online**: Security and compliance configurations

**Usage:**
```powershell
# Full audit of M365 tenant
.\M365-Security-ConfigCheck.ps1 -TenantDomain "contoso.onmicrosoft.com"

# Skip specific services
.\M365-Security-ConfigCheck.ps1 -TenantDomain "contoso.onmicrosoft.com" -SkipTeams -SkipSharePoint

# Custom export location
.\M365-Security-ConfigCheck.ps1 -TenantDomain "contoso.onmicrosoft.com" -ExportPath "C:\Reports\M365Audit"
```

**Requirements:**
- PowerShell 7.2+ recommended (works with 5.1)
- Required modules:
  ```powershell
  Install-Module -Name ExchangeOnlineManagement -Force
  Install-Module -Name Microsoft.Graph -Force
  Install-Module -Name MicrosoftTeams -Force
  Install-Module -Name Microsoft.Online.SharePoint.PowerShell -Force
  ```
- Global Administrator or appropriate role permissions

---

### 3. Azure-BestPractices-Checker.ps1

Azure subscription security, governance, and compliance auditing based on Azure Well-Architected Framework.

**Features:**
- **Security**: Microsoft Defender for Cloud, security contacts, auto-provisioning
- **IAM**: RBAC roles, classic administrators, owner assignments
- **Governance**: Azure Policy assignments, compliance state, resource locks
- **Networking**: NSG rules, Network Watcher, security configurations
- **Monitoring**: Log Analytics, Activity Log export, Action Groups
- **Backup/DR**: Recovery Services vaults, VM backup coverage
- **Cost Management**: Budget configurations (optional)

**Usage:**
```powershell
# Check current subscription
.\Azure-BestPractices-Checker.ps1

# Check specific subscription
.\Azure-BestPractices-Checker.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012"

# Check all subscriptions with cost analysis
.\Azure-BestPractices-Checker.ps1 -CheckAllSubscriptions -IncludeCostAnalysis

# Custom export path
.\Azure-BestPractices-Checker.ps1 -ExportPath "C:\Reports\AzureAudit"
```

**Requirements:**
- Azure PowerShell modules:
  ```powershell
  Install-Module -Name Az -Force -AllowClobber
  ```
- Azure authentication:
  ```powershell
  Connect-AzAccount
  ```
- Reader role minimum (Contributor/Owner for full checks)

---

### 4. Dell-Hardware-Health-Check.ps1

Dell server hardware health monitoring using Dell OpenManage Server Administrator (OMSA) or WMI/CIM fallback.

**Features:**
- **System Health**: Overall system status from OMSA
- **Storage**: Physical disk health, RAID array status, virtual disk state
- **Chassis**: Fan speeds, power supply status, temperature sensors, voltage monitoring
- **Memory**: DIMM health and status
- **Processors**: CPU health monitoring
- **Event Logs**: Recent hardware errors from Windows Event Log
- **Firmware**: BIOS version with Dell support links

**Usage:**
```powershell
# Basic check (uses OMSA if available, otherwise WMI)
.\Dell-Hardware-Health-Check.ps1

# Force OMSA usage
.\Dell-Hardware-Health-Check.ps1 -UseOMSA

# Include firmware version recommendations
.\Dell-Hardware-Health-Check.ps1 -CheckFirmwareVersions

# Custom export path
.\Dell-Hardware-Health-Check.ps1 -ExportPath "C:\Reports\DellHealth.html"
```

**Requirements:**
- Dell PowerEdge server hardware
- **Option 1** (Recommended): Dell OpenManage Server Administrator (OMSA)
  - Download: [Dell OMSA](https://www.dell.com/support/home/en-us/product-support/product/openmanage-server-administrator)
- **Option 2**: Windows WMI/CIM (basic checks without OMSA)
- Administrator privileges
- PowerShell 5.1 or later

---

## 🔧 Prerequisites

### General Requirements

- **PowerShell**: Version 5.1 minimum (7.2+ recommended for M365 scripts)
- **Execution Policy**: Set to allow script execution
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```
- **Administrator Privileges**: Most scripts require elevation

### Module Installation

```powershell
# For M365 Security Check
Install-Module -Name ExchangeOnlineManagement -Force
Install-Module -Name Microsoft.Graph -Force
Install-Module -Name MicrosoftTeams -Force

# For Azure Best Practices Check
Install-Module -Name Az -Force -AllowClobber

# For Dell Hardware (optional - enhances capabilities)
# Install Dell OpenManage Server Administrator from Dell website
```

---

## 🚀 Quick Start

### 1. Clone or Download Scripts

```bash
git clone <repository-url>
cd sysops/scripts
```

### 2. Run Your First Check

**Windows Server Check:**
```powershell
# Open PowerShell as Administrator
.\Windows-Server-BestPractices.ps1
```

**M365 Security Check:**
```powershell
# Install required modules first (one-time setup)
Install-Module ExchangeOnlineManagement, Microsoft.Graph, MicrosoftTeams -Force

# Run the check
.\M365-Security-ConfigCheck.ps1 -TenantDomain "your-tenant.onmicrosoft.com"
```

**Azure Check:**
```powershell
# Install and connect to Azure
Install-Module -Name Az -Force
Connect-AzAccount

# Run the check
.\Azure-BestPractices-Checker.ps1
```

**Dell Hardware Check:**
```powershell
# Run on a Dell server
.\Dell-Hardware-Health-Check.ps1
```

### 3. Review Reports

All scripts automatically generate and open HTML reports in your default browser. Reports include:
- Executive summary with pass/fail statistics
- Detailed findings by category
- Actionable recommendations
- Links to Microsoft/Dell official documentation

---

## 📚 Detailed Documentation

### Report Outputs

Each script generates two outputs:

1. **HTML Report** (Primary)
   - Professional formatted report
   - Color-coded status indicators
   - Executive summary dashboard
   - Detailed findings with recommendations
   - Direct links to documentation

2. **CSV Export** (M365/Azure scripts)
   - Raw data for further analysis
   - Import into Excel or databases
   - Suitable for tracking over time

### Status Indicators

| Status | Meaning | Action Required |
|--------|---------|----------------|
| ✅ **Pass/Healthy** | Meets best practices | None - monitoring only |
| ⚠️ **Warning** | Attention recommended | Review and consider remediation |
| ❌ **Fail/Critical** | Does not meet standards | Immediate action required |
| ℹ️ **Info/Unknown** | Informational only | Review for context |

### Common Parameters

All scripts support these common parameters:

- `-ExportPath` - Custom location for report output
- `-Verbose` - Detailed console output during execution
- `-ErrorAction` - Control error handling behavior

---

## 🔗 References

### Microsoft Official Resources

**Security and Compliance:**
- [Microsoft Security Compliance Toolkit](https://learn.microsoft.com/en-us/windows/security/operating-system-security/device-management/windows-security-configuration-framework/security-compliance-toolkit-10)
- [Windows Security Baselines](https://learn.microsoft.com/en-us/windows/security/operating-system-security/device-management/windows-security-configuration-framework/windows-security-baselines)
- [Microsoft 365 Security](https://learn.microsoft.com/en-us/microsoft-365/security/)

**PowerShell Best Practices:**
- [PowerShell Scripting Best Practices](https://dstreefkerk.github.io/2025-06-powershell-scripting-best-practices/)
- [PowerShell Gallery](https://www.powershellgallery.com/)

**Exchange and M365:**
- [Microsoft CSS-Exchange GitHub](https://github.com/microsoft/CSS-Exchange)
- [CSS-Exchange Security Scripts](https://github.com/microsoft/CSS-Exchange/tree/main/Security)
- [Exchange Online Protection](https://learn.microsoft.com/en-us/defender-office-365/anti-malware-protection-about)
- [Azure AD Conditional Access](https://learn.microsoft.com/en-us/entra/identity/conditional-access/overview)

**Azure:**
- [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/)
- [Azure Cloud Adoption Framework](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/)
- [Azure Security Best Practices](https://learn.microsoft.com/en-us/azure/security/fundamentals/best-practices-and-patterns)
- [Microsoft Defender for Cloud](https://learn.microsoft.com/en-us/azure/defender-for-cloud/)

### Dell Official Resources

**OpenManage:**
- [Dell OpenManage PowerShell Modules (GitHub)](https://github.com/dell/OpenManage-PowerShell-Modules)
- [Dell OpenManage Enterprise Support](https://www.dell.com/support/kbdoc/en-us/000175879/support-for-openmanage-enterprise)
- [OpenManage Server Administrator Commands](https://www.dell.com/support/kbdoc/en-us/000136490/command-list-of-openmanage-server-administrator-omsa)

**Hardware Monitoring:**
- [Dell PowerEdge Server Support](https://www.dell.com/support/home/en-us/products/server_int)
- [Dell iDRAC Documentation](https://www.dell.com/support/manuals/en-us/openmanage-integration-microsoft-windows-admin-center/)

### Community Resources

- [Monitoring Dell Systems with PowerShell](https://www.cyberdrain.com/blog-series-monitoring-using-powershell-part-two-using-powershell-to-monitor-dell-systems/)
- [Microsoft GitHub Organization](https://github.com/microsoft)

---

## 📊 Sample Report Output

### Windows Server Report
```
╔═══════════════════════════════════════════════════════════════════╗
║   Windows Server Best Practices and Configuration Checker        ║
║   Based on Microsoft Security Compliance Toolkit                 ║
╚═══════════════════════════════════════════════════════════════════╝

=== Summary ===
Total Checks: 25
Passed: 18
Failed: 2
Warnings: 4
Info: 1
```

### M365 Security Report
```
╔═══════════════════════════════════════════════════════════════════╗
║   Microsoft 365 Security & Configuration Checker                 ║
║   Based on Microsoft CSS-Exchange and Security Best Practices    ║
╚═══════════════════════════════════════════════════════════════════╝

Services Checked:
✓ Azure AD / Entra ID
✓ Exchange Online
✓ Microsoft Teams
```

### Azure Report
```
╔═══════════════════════════════════════════════════════════════════╗
║   Azure Best Practices and Compliance Checker                    ║
║   Based on Azure Well-Architected Framework                      ║
╚═══════════════════════════════════════════════════════════════════╝

Subscriptions Checked: 1
Categories: Security, IAM, Governance, Network, Monitoring, Backup, Cost
```

### Dell Hardware Report
```
╔═══════════════════════════════════════════════════════════════════╗
║   Dell Hardware Health and Configuration Checker                 ║
║   Based on Dell OpenManage and Best Practices                    ║
╚═══════════════════════════════════════════════════════════════════╝

✓ Dell System Detected
  Model: PowerEdge R740
  Service Tag: ABC1234
  BIOS Version: 2.15.1
```

---

## 🤝 Contributing

These scripts are designed to be maintained and extended. When contributing:

1. Follow PowerShell best practices
2. Include proper error handling
3. Update documentation for new features
4. Reference official Microsoft/Dell documentation
5. Test on target platforms before committing

---

## 📝 License

These scripts are provided as-is for system operations and auditing purposes. Always test in non-production environments first.

---

## ⚠️ Important Notes

1. **Test First**: Always test scripts in a non-production environment
2. **Permissions**: Ensure you have appropriate permissions before running
3. **Backups**: Maintain backups before making configuration changes based on recommendations
4. **Documentation**: Review official Microsoft/Dell documentation for detailed remediation steps
5. **Updates**: Check for script updates regularly as best practices evolve

---

## 📞 Support

For issues or questions:

1. Review the detailed comments within each script
2. Check the official Microsoft/Dell documentation linked in references
3. Review script output for specific error messages
4. Ensure all prerequisites are met

---

**Last Updated:** 2025-11-30
**Version:** 1.0
**Based on:** Microsoft Security Compliance Toolkit, Azure Well-Architected Framework, Dell OpenManage
