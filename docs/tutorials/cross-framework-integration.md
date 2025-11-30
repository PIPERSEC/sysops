# Cross-Framework Integration Examples

This guide demonstrates how to leverage all three frameworks (SysOps, NetOps, SecOps) together for comprehensive operations.

## Use Case 1: Secure Infrastructure Deployment

### Scenario
Deploy secure cloud infrastructure with automated network configuration and security scanning.

### Workflow

**1. SysOps: Provision Infrastructure** (`/Users/jcox/Repos/Default/envs/sysops`)
```bash
cd sysops/projects/secure-deployment
terraform init
terraform plan
terraform apply

# Get outputs for network configuration
terraform output network_details > /tmp/network-config.json
```

**2. NetOps: Configure Network Devices** (`/Users/jcox/Repos/Default/envs/netops`)
```python
# netops/projects/auto-configure/deploy_network.py
import json
from napalm import get_network_driver

# Load infrastructure details from SysOps
with open('/tmp/network-config.json') as f:
    infra = json.load(f)

# Configure network devices
driver = get_network_driver('ios')
device = driver(hostname=infra['router_ip'], username='admin', password='***')

device.open()
device.load_merge_candidate(config=generate_config(infra))
device.commit_config()
device.close()
```

**3. SecOps: Security Scan** (`/Users/jcox/Repos/Default/envs/secops`)
```bash
cd secops
python scripts/scanning/security-scanner.py ../sysops/projects/secure-deployment

# Run compliance check
python scripts/compliance/compliance-auditor.py --framework pci-dss
```

## Use Case 2: Incident Response Pipeline

### Scenario
Automated incident response across infrastructure, network, and security.

### Workflow

**1. SecOps: Detect Threat**
```python
# secops/scripts/incident-response/threat-detector.py
def detect_suspicious_activity():
    # Monitor logs for threats
    if threat_detected:
        trigger_incident_response()
```

**2. NetOps: Isolate Compromised System**
```python
# netops/scripts/incident-response/network-isolation.py
from netmiko import ConnectHandler

def isolate_host(ip_address):
    \"\"\"Apply ACL to isolate compromised host.\"\"\"
    switch = ConnectHandler(
        device_type='cisco_ios',
        host='core-switch-01',
        username='admin',
        password='***'
    )

    acl_config = f'''
    ip access-list extended QUARANTINE
      deny ip host {ip_address} any
      permit ip any any
    '''

    switch.send_config_set(acl_config.split('\\n'))
    switch.disconnect()
```

**3. SysOps: Snapshot and Forensics**
```bash
# sysops/scripts/incident-response/snapshot-instance.sh
#!/bin/bash
# Snapshot EC2 instance for forensics

INSTANCE_ID=$1
SNAPSHOT_NAME="forensics-$(date +%Y%m%d-%H%M%S)"

aws ec2 create-snapshot \
    --volume-id $(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' \
        --output text) \
    --description "$SNAPSHOT_NAME"
```

## Use Case 3: Continuous Compliance

### Scenario
Automated compliance checking across all layers.

### Integration Script

```python
#!/usr/bin/env python3
\"\"\"
Continuous Compliance Checker
Checks compliance across infrastructure, network, and security.
\"\"\"

import subprocess
import json
from datetime import datetime

def run_sysops_validation():
    \"\"\"Run SysOps infrastructure validation.\"\"\"
    result = subprocess.run(
        ['python', '../sysops/scripts/infrastructure-validator.py', '--json-output', '/tmp/infra-results.json'],
        capture_output=True
    )
    return result.returncode == 0

def run_netops_compliance():
    \"\"\"Run NetOps configuration compliance.\"\"\"
    result = subprocess.run(
        ['python', '../netops/scripts/config-compliance-checker.py'],
        capture_output=True
    )
    return result.returncode == 0

def run_secops_audit():
    \"\"\"Run SecOps security audit.\"\"\"
    result = subprocess.run(
        ['python', '../secops/scripts/compliance/compliance-auditor.py', '--framework', 'pci-dss'],
        capture_output=True
    )
    return result.returncode == 0

def generate_compliance_report():
    \"\"\"Generate unified compliance report.\"\"\"
    report = {
        'timestamp': datetime.now().isoformat(),
        'sysops': run_sysops_validation(),
        'netops': run_netops_compliance(),
        'secops': run_secops_audit()
    }

    # Save report
    with open('compliance-report.json', 'w') as f:
        json.dump(report, f, indent=2)

    # Determine overall compliance
    all_passed = all(report.values() if k != 'timestamp' else True for k in report.keys())

    print(f\"\\nOverall Compliance Status: {'✅ PASS' if all_passed else '❌ FAIL'}\")
    return all_passed

if __name__ == '__main__':
    import sys
    passed = generate_compliance_report()
    sys.exit(0 if passed else 1)
```

## Use Case 4: Cost & Security Optimization

### Workflow

```bash
#!/bin/bash
# Comprehensive optimization check

echo "Running SysOps Cost Analysis..."
cd /Users/jcox/Repos/Default/envs/sysops
python scripts/cloud-cost-analyzer.py --export cost-report.json

echo "Running NetOps Health Check..."
cd /Users/jcox/Repos/Default/envs/netops
python scripts/network-health-checker.py --export network-health.json

echo "Running SecOps Security Scan..."
cd /Users/jcox/Repos/Default/envs/secops
python scripts/scanning/security-scanner.py --export security-scan.json

echo "Generating Combined Report..."
python3 << 'EOF'
import json

# Load all reports
with open('/Users/jcox/Repos/Default/envs/sysops/cost-report.json') as f:
    cost = json.load(f)

with open('/Users/jcox/Repos/Default/envs/netops/network-health.json') as f:
    network = json.load(f)

with open('/Users/jcox/Repos/Default/envs/secops/security-scan.json') as f:
    security = json.load(f)

# Generate combined report
print("\\n" + "="*80)
print("Combined Operations Report")
print("="*80)
print(f"\\nCost Optimization Findings: {len(cost.get('findings', []))}")
print(f"Network Health Issues: {network['summary']['critical'] + network['summary']['warning']}")
print(f"Security Issues: {sum(1 for s in security['scans'].values() if s.get('status') == 'fail')}")
print("="*80)
EOF
```

## Best Practices for Integration

### 1. Shared Configuration

Create a shared config file that all frameworks can access:

```yaml
# /Users/jcox/Repos/Default/envs/shared-config.yml
aws:
  region: us-east-1
  profile: production

network:
  management_network: 192.168.100.0/24
  devices:
    - hostname: core-switch-01
      ip: 192.168.100.1
      type: cisco_ios

security:
  scan_schedule: daily
  compliance_frameworks:
    - pci-dss
    - soc2

notifications:
  slack_webhook: https://hooks.slack.com/services/YOUR/WEBHOOK
  email: security@example.com
```

### 2. Unified Logging

Send all framework logs to a central location:

```python
# shared-logging.py
import logging
import json

class UnifiedLogger:
    def __init__(self, framework_name):
        self.framework = framework_name
        self.logger = logging.getLogger(framework_name)

        handler = logging.FileHandler('/var/log/ops/unified.log')
        handler.setFormatter(logging.Formatter(
            '{"timestamp":"%(asctime)s","framework":"%(name)s","level":"%(levelname)s","message":"%(message)s"}'
        ))

        self.logger.addHandler(handler)
        self.logger.setLevel(logging.INFO)

    def log_event(self, event_type, details):
        self.logger.info(json.dumps({
            'event_type': event_type,
            'framework': self.framework,
            'details': details
        }))
```

### 3. Automated Orchestration

Use a master script to coordinate all three frameworks:

```python
#!/usr/bin/env python3
\"\"\"
Master Orchestration Script
Coordinates SysOps, NetOps, and SecOps workflows.
\"\"\"

import subprocess
import sys
from pathlib import Path

BASE_PATH = Path('/Users/jcox/Repos/Default/envs')

def run_framework_script(framework, script_path, *args):
    \"\"\"Run a script from a specific framework.\"\"\"
    full_path = BASE_PATH / framework / script_path
    cmd = ['python', str(full_path)] + list(args)

    print(f\"Running {framework}: {script_path}\")
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        print(f\"❌ {framework} failed: {result.stderr}\")
        return False

    print(f\"✅ {framework} completed\")
    return True

def main():
    \"\"\"Main orchestration workflow.\"\"\"
    workflows = [
        ('sysops', 'scripts/infrastructure-validator.py'),
        ('netops', 'scripts/network-health-checker.py'),
        ('secops', 'scripts/scanning/security-scanner.py', '.'),
    ]

    results = []
    for workflow in workflows:
        success = run_framework_script(*workflow)
        results.append(success)

    # Overall status
    if all(results):
        print(\"\\n✅ All frameworks completed successfully\")
        return 0
    else:
        print(\"\\n❌ Some frameworks failed\")
        return 1

if __name__ == '__main__':
    sys.exit(main())
```

## Monitoring & Alerts

Set up monitoring for all three frameworks:

```python
# monitoring/unified-monitor.py
import requests
import json

def send_alert(framework, severity, message):
    \"\"\"Send alert to Slack/Email/PagerDuty.\"\"\"

    # Slack example
    slack_webhook = "YOUR_SLACK_WEBHOOK"

    payload = {
        \"text\": f\"[{severity}] {framework}: {message}\",
        \"username\": \"OpsBot\",
        \"icon_emoji\": \":robot_face:\"
    }

    requests.post(slack_webhook, json=payload)

# Use in all frameworks
send_alert('secops', 'CRITICAL', 'Security scan found 5 high-severity issues')
send_alert('netops', 'WARNING', 'Router CPU at 85%')
send_alert('sysops', 'INFO', 'Cost savings opportunity: $500/month')
```

## Summary

By integrating all three frameworks, you can:

1. **Automate End-to-End Operations**: From infrastructure provisioning to security validation
2. **Unified Compliance**: Check compliance across all layers
3. **Coordinated Incident Response**: Respond to incidents holistically
4. **Comprehensive Monitoring**: Single pane of glass for all operations
5. **Cost & Security Optimization**: Find opportunities across the stack

Each framework remains independent but can easily share data and coordinate actions when needed.
