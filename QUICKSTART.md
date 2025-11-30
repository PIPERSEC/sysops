# SysOps Framework - Quick Start Guide

Welcome to your comprehensive Systems Engineering framework! This guide will get you started in 5 minutes.

## What You Have

A complete, production-ready framework for systems engineering and infrastructure automation with:

### 🤖 AI-Assisted Workflows
- **Personas**: Expert perspectives (Systems Engineer, DevOps Architect, Security Engineer)
- **Memory Bank**: Persistent context and best practices
- **Chain of Thought Templates**: Structured decision-making approaches
- **Few-Shot Examples**: Code patterns and standards

### 🛠️ Infrastructure Templates
- **Terraform**: AWS VPC module (ready to use)
- **Ansible**: Common server configuration role
- **Kubernetes**: Production-ready deployment manifests
- **Docker**: Multi-stage Dockerfile with security best practices

### 📚 Documentation
- Comprehensive README
- Getting started tutorial
- Infrastructure coding standards
- GitHub setup guide

### ⚙️ Development Environment
- VSCode workspace configured
- Recommended extensions
- Tasks for Terraform, Ansible, Python, K8s
- Git initialized with proper .gitignore

## Quick Start (3 Steps)

### 1. Push to GitHub

**Option A: Use GitHub CLI**
```bash
brew install gh          # Install GitHub CLI
gh auth login           # Authenticate
./scripts/setup-github.sh    # Run setup script
```

**Option B: Manual**
1. Create repo at https://github.com/PIPERSEC/new
2. Name it `sysops`
3. Run:
   ```bash
   git remote add origin https://github.com/PIPERSEC/sysops.git
   git push -u origin main
   ```

### 2. Install Tools

```bash
# Install Terraform
brew install terraform

# Install Ansible
pip install ansible ansible-lint

# Install AWS CLI (if using AWS)
brew install awscli

# Install kubectl (if using Kubernetes)
brew install kubectl
```

### 3. Start Your First Project

```bash
# Create a new project
mkdir -p projects/my-infrastructure
cd projects/my-infrastructure

# Copy a template
cp -r ../../templates/terraform/vpc .

# Configure your infrastructure
# Edit vpc/terraform.tfvars

# Initialize and plan
cd vpc
terraform init
terraform plan
```

## Directory Overview

```
sysops/
├── projects/              # Your active work goes here
├── templates/             # Starting points for common patterns
│   ├── terraform/        # IaC templates
│   ├── ansible/          # Configuration management
│   ├── kubernetes/       # Container orchestration
│   └── docker/           # Container definitions
├── ai-context/           # AI assistance context
│   ├── personas/         # Expert perspectives
│   ├── memory-bank/      # Persistent knowledge
│   ├── cot-templates/    # Decision frameworks
│   └── few-shot-examples/# Code examples
├── docs/                 # Documentation
│   ├── tutorials/        # How-to guides
│   ├── standards/        # Coding standards
│   └── runbooks/         # Operational procedures
├── scripts/              # Utility scripts
├── .claude/              # Claude Code integration
└── .vscode/              # VSCode configuration
```

## Key Files to Review

1. **[README.md](README.md)** - Comprehensive overview
2. **[docs/tutorials/getting-started.md](docs/tutorials/getting-started.md)** - Detailed tutorial
3. **[ai-context/memory-bank/best-practices.md](ai-context/memory-bank/best-practices.md)** - Best practices
4. **[docs/standards/infrastructure-code.md](docs/standards/infrastructure-code.md)** - Coding standards

## Using AI Context

### Before Starting Work:
1. Review relevant persona in `ai-context/personas/`
2. Check memory bank for similar work
3. Use CoT template for complex decisions
4. Reference few-shot examples for patterns

### While Working:
- Update `ai-context/memory-bank/project-context.md`
- Document decisions in `architectural-decisions.md`
- Add solutions to `common-issues.md`

### Claude Code Integration:
```
/analyze-infra          # Analyze infrastructure code
/create-runbook         # Generate operational runbook
/security-audit         # Perform security review
```

## Common Tasks

### Create Terraform Infrastructure
```bash
cd projects/my-project
cp -r ../../templates/terraform/vpc .
cd vpc
terraform init
terraform plan
terraform apply
```

### Run Ansible Playbook
```bash
cd projects/server-config
ansible-playbook -i inventory/hosts.ini playbooks/site.yml
```

### Deploy to Kubernetes
```bash
kubectl apply -f templates/kubernetes/deployment.yaml
```

### Build Docker Image
```bash
cd projects/my-app
docker build -t myapp:v1.0.0 -f ../../templates/docker/Dockerfile .
```

## Best Practices

✅ **Always use version control** - Commit early and often
✅ **Never commit secrets** - Use secret managers
✅ **Test before production** - Use dev/staging environments
✅ **Document decisions** - Update memory bank and ADRs
✅ **Follow standards** - See docs/standards/
✅ **Tag resources** - Include Environment, ManagedBy, Owner
✅ **Implement monitoring** - Set up alerts from the start
✅ **Plan for disaster recovery** - Document and test procedures

## Getting Help

1. **Check Documentation**: Start with [docs/tutorials/getting-started.md](docs/tutorials/getting-started.md)
2. **Review Memory Bank**: See [ai-context/memory-bank/](ai-context/memory-bank/)
3. **Use Claude Code**: Run `/analyze-infra` or other commands
4. **Consult Examples**: Check [ai-context/few-shot-examples/](ai-context/few-shot-examples/)

## Next Steps

- [ ] Push to GitHub
- [ ] Install required tools (Terraform, Ansible, etc.)
- [ ] Configure cloud credentials (AWS/Azure/GCP)
- [ ] Review [getting started tutorial](docs/tutorials/getting-started.md)
- [ ] Create your first project
- [ ] Set up CI/CD (optional)
- [ ] Configure branch protection on GitHub
- [ ] Add collaborators if working in a team

## Framework Features

### Infrastructure as Code
- Terraform modules for AWS, Azure, GCP
- Ansible roles for configuration management
- Kubernetes manifests with security best practices
- Docker multi-stage builds

### Security
- .gitignore prevents committing secrets
- Security-first templates
- CoT template for security reviews
- Compliance considerations built-in

### AI Integration
- Claude Code rules and commands
- Persona-driven development
- Structured decision-making
- Pattern library for consistency

### Collaboration
- Git workflow established
- Coding standards documented
- VSCode workspace for team consistency
- Memory bank for shared knowledge

## Support

This framework is designed to grow with your needs:
- Add new templates as you develop patterns
- Expand memory bank with lessons learned
- Create custom Claude commands for your workflows
- Build reusable modules and roles

**Happy engineering! 🚀**

---

**Created**: 2025-11-30
**Version**: 1.0.0
**Author**: PIPERSEC
