# Getting Started with SysOps Framework

This tutorial will walk you through setting up and using the SysOps framework for your first infrastructure project.

## Table of Contents
1. [Initial Setup](#initial-setup)
2. [Understanding the Structure](#understanding-the-structure)
3. [Your First Terraform Project](#your-first-terraform-project)
4. [Working with Ansible](#working-with-ansible)
5. [Using AI Context](#using-ai-context)
6. [Best Practices](#best-practices)

## Initial Setup

### 1. Environment Preparation

First, ensure you have all prerequisites installed:

```bash
# Check Python version (should be 3.13+)
python3 --version

# Check Terraform
terraform version

# Check Ansible
ansible --version

# Check Docker
docker --version

# Check kubectl (if using Kubernetes)
kubectl version --client
```

### 2. Activate Virtual Environment

```bash
cd /path/to/sysops
source bin/activate
```

You should see `(sysops)` in your terminal prompt.

### 3. Configure Cloud Credentials

**For AWS:**
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output format: json
```

**For Azure:**
```bash
az login
az account set --subscription "Your Subscription Name"
```

**For GCP:**
```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

## Understanding the Structure

### Key Directories

- **`projects/`**: Your active work goes here. Each project gets its own subdirectory.
- **`templates/`**: Starting points for common infrastructure patterns.
- **`ai-context/`**: Helps AI assistants understand your project and provide better help.
- **`docs/`**: Documentation, runbooks, and standards.
- **`.claude/`**: Configuration for Claude Code integration.

### The AI Context System

Before starting any work, review:

1. **[ai-context/personas/systems-engineer.md](../ai-context/personas/systems-engineer.md)**: Understand the systems engineering mindset
2. **[ai-context/memory-bank/best-practices.md](../ai-context/memory-bank/best-practices.md)**: Review established patterns
3. **[ai-context/memory-bank/project-context.md](../ai-context/memory-bank/project-context.md)**: See current projects

## Your First Terraform Project

### Step 1: Create Project Structure

```bash
mkdir -p projects/my-first-vpc
cd projects/my-first-vpc
```

### Step 2: Copy VPC Template

```bash
cp -r ../../templates/terraform/vpc/* .
```

You now have:
```
my-first-vpc/
├── main.tf
├── variables.tf
└── outputs.tf
```

### Step 3: Customize Variables

Edit `variables.tf` or create `terraform.tfvars`:

```hcl
# terraform.tfvars
vpc_name = "my-dev-vpc"
vpc_cidr = "10.0.0.0/16"

aws_region = "us-east-1"

availability_zones = [
  "us-east-1a",
  "us-east-1b"
]

public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnet_cidrs = [
  "10.0.11.0/24",
  "10.0.12.0/24"
]

common_tags = {
  Environment = "development"
  ManagedBy   = "Terraform"
  Project     = "MyFirstVPC"
  Owner       = "YourName"
}
```

### Step 4: Initialize Terraform

```bash
terraform init
```

This downloads required providers and sets up the backend.

### Step 5: Plan Your Infrastructure

```bash
terraform plan
```

Review the output carefully. Terraform will show you what it plans to create.

### Step 6: Apply Changes

```bash
# Save plan to file
terraform plan -out=tfplan

# Apply the plan
terraform apply tfplan
```

Type `yes` when prompted.

### Step 7: Verify Deployment

```bash
# See outputs
terraform output

# Check AWS Console or CLI
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=my-dev-vpc"
```

### Step 8: Document Your Work

Update the project context:

Edit `../../ai-context/memory-bank/project-context.md`:

```markdown
## Active Projects

### My First VPC (projects/my-first-vpc)
- **Status**: Active
- **Created**: 2025-11-30
- **Purpose**: Learning Terraform and VPC setup
- **Resources**: VPC with 2 public and 2 private subnets across 2 AZs
- **Next Steps**: Add security groups and EC2 instances
```

## Working with Ansible

### Step 1: Create Ansible Project

```bash
mkdir -p projects/server-config
cd projects/server-config
```

### Step 2: Set Up Structure

```bash
mkdir -p inventory playbooks roles
```

### Step 3: Create Inventory

Create `inventory/hosts.ini`:

```ini
[webservers]
web01 ansible_host=192.168.1.10

[databases]
db01 ansible_host=192.168.1.20

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3
```

### Step 4: Copy Common Role

```bash
cp -r ../../templates/ansible/roles/common roles/
```

### Step 5: Create Playbook

Create `playbooks/site.yml`:

```yaml
---
- name: Configure all servers
  hosts: all
  become: yes
  roles:
    - common

- name: Configure web servers
  hosts: webservers
  become: yes
  tasks:
    - name: Install nginx
      package:
        name: nginx
        state: present

    - name: Ensure nginx is running
      service:
        name: nginx
        state: started
        enabled: yes
```

### Step 6: Test Connectivity

```bash
ansible all -i inventory/hosts.ini -m ping
```

### Step 7: Run Playbook

```bash
# Dry run first
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --check

# Actual run
ansible-playbook -i inventory/hosts.ini playbooks/site.yml
```

## Using AI Context

### Leveraging Personas

When working on different tasks, mentally (or explicitly) adopt the appropriate persona:

**For infrastructure design:**
Read [ai-context/personas/systems-engineer.md](../ai-context/personas/systems-engineer.md) and apply that mindset.

**For security reviews:**
Read [ai-context/personas/security-engineer.md](../ai-context/personas/security-engineer.md) and review with security focus.

### Using Chain of Thought Templates

When facing complex decisions, use the CoT templates:

**Designing new infrastructure:**
1. Open [ai-context/cot-templates/infrastructure-design.md](../ai-context/cot-templates/infrastructure-design.md)
2. Follow the template step-by-step
3. Document your decisions

**Troubleshooting issues:**
1. Open [ai-context/cot-templates/troubleshooting.md](../ai-context/cot-templates/troubleshooting.md)
2. Work through the systematic approach
3. Add solutions to memory bank

### Using Few-Shot Examples

Before writing code, review examples:

**Creating Terraform modules:**
See [ai-context/few-shot-examples/terraform-module.md](../ai-context/few-shot-examples/terraform-module.md)

**Writing Ansible playbooks:**
See [ai-context/few-shot-examples/ansible-playbook.md](../ai-context/few-shot-examples/ansible-playbook.md)

**Python automation:**
See [ai-context/few-shot-examples/python-script.md](../ai-context/few-shot-examples/python-script.md)

### Claude Code Integration

If using Claude Code, leverage custom commands:

```bash
# In VSCode with Claude Code
/analyze-infra
/create-runbook server-deployment
/security-audit
```

## Best Practices

### 1. Always Use Version Control

```bash
# Initialize git if not already done
git init

# Create .gitignore
cat > .gitignore <<EOF
*.tfstate
*.tfstate.backup
.terraform/
*.tfvars
.env
*.pem
*.key
EOF

# Commit your work
git add .
git commit -m "feat: initial VPC setup"
```

### 2. Tag Your Resources

Always include these tags:
- `Environment`: dev/staging/prod
- `ManagedBy`: Terraform/Ansible/etc
- `Project`: Project name
- `Owner`: Your name or team

### 3. Document Decisions

After making architectural decisions, document them:

Edit `ai-context/memory-bank/architectural-decisions.md` and add an ADR.

### 4. Test Before Production

1. Test in development environment
2. Use `terraform plan` and `ansible --check`
3. Review changes carefully
4. Have rollback plan ready

### 5. Keep Security in Mind

- Never commit secrets
- Use AWS Secrets Manager, Vault, or similar
- Implement least privilege
- Regular security audits

### 6. Monitor and Alert

Set up monitoring from the start:
- CloudWatch for AWS
- Azure Monitor for Azure
- Stackdriver for GCP
- Prometheus + Grafana for Kubernetes

## Next Steps

Now that you've completed your first projects:

1. **Explore More Templates**: Check out [templates/](../templates/) for Kubernetes and Docker examples
2. **Read Standards**: Review [docs/standards/infrastructure-code.md](../docs/standards/infrastructure-code.md)
3. **Create Runbooks**: Document your procedures in [docs/runbooks/](../docs/runbooks/)
4. **Build Custom Modules**: Create reusable Terraform modules
5. **Automate**: Set up CI/CD for your infrastructure code

## Getting Help

- Check [ai-context/memory-bank/common-issues.md](../ai-context/memory-bank/common-issues.md)
- Review relevant runbooks in [docs/runbooks/](../docs/runbooks/)
- Use Claude Code commands for analysis
- Consult official documentation

## Summary

You've learned:
- ✅ How to set up the SysOps framework
- ✅ How to use templates for Terraform and Ansible
- ✅ How to leverage AI context for better decisions
- ✅ Best practices for infrastructure as code
- ✅ How to document your work

Continue building, learning, and contributing back to the framework!
