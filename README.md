# SysOps Engineering Framework

A comprehensive framework for systems engineering, infrastructure automation, and DevOps practices. This repository provides standardized templates, tools, and AI-assisted workflows for building and maintaining production infrastructure.

## Overview

This framework is designed to help systems engineers:
- Organize infrastructure projects with consistent standards
- Leverage AI assistance with context-aware tooling
- Maintain best practices and reusable templates
- Collaborate effectively with shared conventions
- Scale infrastructure operations efficiently

## Repository Structure

```
sysops/
├── projects/                    # Active project work
├── templates/                   # Reusable IaC templates
│   ├── terraform/              # Terraform modules
│   ├── ansible/                # Ansible roles
│   ├── kubernetes/             # K8s manifests
│   └── docker/                 # Dockerfiles
├── docs/                       # Documentation
│   ├── architecture/           # Architecture diagrams and docs
│   ├── runbooks/              # Operational runbooks
│   ├── standards/             # Coding and infrastructure standards
│   └── tutorials/             # How-to guides
├── config/                     # Tool configurations
│   ├── ansible/               # Ansible configs
│   ├── terraform/             # Terraform configs
│   ├── kubernetes/            # K8s configs
│   └── docker/                # Docker configs
├── ai-context/                 # AI assistant context
│   ├── personas/              # Expert personas
│   ├── memory-bank/           # Persistent context
│   ├── cot-templates/         # Chain of Thought templates
│   └── few-shot-examples/     # Code examples
├── scripts/                    # Utility scripts
├── tools/                      # Custom tooling
├── .claude/                    # Claude Code configuration
│   ├── rules.md               # Claude rules for this project
│   └── commands/              # Custom slash commands
└── bin/                        # Python virtual environment binaries
```

## Getting Started

### Prerequisites

- Python 3.13+ (virtual environment included)
- Git
- VSCode (recommended)
- AWS CLI, Azure CLI, or GCP SDK (depending on your cloud)
- Terraform >= 1.0
- Ansible >= 2.9
- Docker
- kubectl (for Kubernetes work)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/sysops.git
   cd sysops
   ```

2. **Activate the Python virtual environment:**
   ```bash
   source bin/activate
   ```

3. **Install additional Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure your cloud credentials:**
   ```bash
   # AWS
   aws configure

   # Azure
   az login

   # GCP
   gcloud auth login
   ```

5. **Install recommended VSCode extensions** (see `.vscode/extensions.json`)

## Core Concepts

### AI Context System

This framework includes an AI context system to help maintain consistency and leverage best practices:

#### Personas
Located in [ai-context/personas/](ai-context/personas/), these define expert perspectives:
- **Systems Engineer**: Infrastructure and automation expertise
- **DevOps Architect**: CI/CD and platform engineering
- **Security Engineer**: Security and compliance focus

#### Memory Bank
The [ai-context/memory-bank/](ai-context/memory-bank/) stores persistent context:
- **Project Context**: Current state and objectives
- **Architectural Decisions**: ADRs and rationale
- **Best Practices**: Accumulated knowledge
- **Common Issues**: Known problems and solutions
- **Preferences**: Team standards and conventions

#### Chain of Thought Templates
[ai-context/cot-templates/](ai-context/cot-templates/) provide structured thinking approaches:
- **Infrastructure Design**: Systematic architecture planning
- **Troubleshooting**: Debugging methodology
- **Security Review**: Comprehensive security assessment

#### Few-Shot Examples
[ai-context/few-shot-examples/](ai-context/few-shot-examples/) demonstrate patterns:
- Terraform modules
- Ansible playbooks
- Python automation scripts
- Kubernetes manifests

### Claude Code Integration

This repository is optimized for use with Claude Code:

- **Rules**: [.claude/rules.md](.claude/rules.md) defines project-specific guidelines
- **Custom Commands**: [.claude/commands/](.claude/commands/) provides slash commands
  - `/analyze-infra`: Analyze infrastructure code
  - `/create-runbook`: Generate operational runbooks
  - `/security-audit`: Perform security audits

## Usage

### Starting a New Project

1. **Create project directory:**
   ```bash
   mkdir -p projects/my-new-project
   cd projects/my-new-project
   ```

2. **Copy relevant templates:**
   ```bash
   # For Terraform project
   cp -r ../../templates/terraform/vpc .

   # For Ansible project
   cp -r ../../templates/ansible/roles/common roles/
   ```

3. **Update AI context:**
   - Add project details to [ai-context/memory-bank/project-context.md](ai-context/memory-bank/project-context.md)
   - Document architectural decisions in [ai-context/memory-bank/architectural-decisions.md](ai-context/memory-bank/architectural-decisions.md)

### Working with Templates

#### Terraform
```bash
cd templates/terraform/vpc
terraform init
terraform plan
terraform apply
```

See [docs/standards/infrastructure-code.md](docs/standards/infrastructure-code.md) for standards.

#### Ansible
```bash
cd templates/ansible
ansible-playbook -i inventory/hosts.ini playbooks/site.yml
```

#### Kubernetes
```bash
kubectl apply -f templates/kubernetes/deployment.yaml
```

### Creating Runbooks

Use the Claude Code command:
```
/create-runbook <operation-name>
```

Or manually create in [docs/runbooks/](docs/runbooks/).

### Security Audits

Use the Claude Code command:
```
/security-audit
```

Results will be saved in `docs/security/`.

## Development Workflow

### Git Workflow

1. Create feature branch:
   ```bash
   git checkout -b feature/my-feature
   ```

2. Make changes and commit:
   ```bash
   git add .
   git commit -m "feat(terraform): add VPC module for multi-region setup"
   ```

3. Push and create PR:
   ```bash
   git push origin feature/my-feature
   ```

### Commit Message Format

Follow conventional commits:
```
<type>(<scope>): <subject>

<body>

<footer>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Example:
```
feat(ansible): add nginx role with SSL support

Implement Ansible role for nginx configuration with
automatic SSL certificate management and security hardening.

Closes #123
```

## Best Practices

### Infrastructure as Code
- Version control everything
- Use remote state with locking
- Implement proper tagging
- Test before applying to production
- Document all modules and roles

### Security
- Never commit secrets
- Use secret management tools
- Implement least privilege access
- Regular security scanning
- Enable audit logging

### Documentation
- Maintain up-to-date README files
- Create runbooks for operations
- Document architectural decisions
- Include usage examples
- Keep diagrams current

### Testing
- Use staging environments
- Implement automated testing
- Validate before deployment
- Monitor after changes
- Have rollback procedures

## Common Tasks

### Infrastructure Provisioning
```bash
# Initialize Terraform
cd projects/my-project
terraform init

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan
```

### Configuration Management
```bash
# Run Ansible playbook
ansible-playbook -i inventory/hosts.ini playbooks/site.yml

# Check mode (dry run)
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --check

# With tags
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags webserver
```

### Container Management
```bash
# Build Docker image
docker build -t myapp:v1.0.0 .

# Run container
docker run -d -p 8080:8080 myapp:v1.0.0

# Push to registry
docker push registry/myapp:v1.0.0
```

### Kubernetes Operations
```bash
# Apply manifests
kubectl apply -f k8s/

# Check deployment
kubectl get deployments
kubectl get pods

# View logs
kubectl logs -f deployment/myapp

# Port forward for testing
kubectl port-forward deployment/myapp 8080:8080
```

## Troubleshooting

### Common Issues

See [ai-context/memory-bank/common-issues.md](ai-context/memory-bank/common-issues.md) for detailed troubleshooting guides.

### Getting Help

1. Check relevant documentation in `docs/`
2. Review memory bank for similar issues
3. Use Claude Code with `/analyze-infra` command
4. Consult runbooks in `docs/runbooks/`

## Contributing

### Adding Templates

1. Create template in appropriate directory
2. Include README with usage instructions
3. Add examples
4. Document variables/parameters
5. Submit PR for review

### Updating Documentation

1. Keep documentation close to code
2. Update memory bank with lessons learned
3. Add runbooks for new operations
4. Document architectural decisions

### Improving AI Context

1. Update personas as roles evolve
2. Add new CoT templates for common scenarios
3. Contribute few-shot examples
4. Keep best practices current

## Resources

### Internal Documentation
- [Infrastructure Standards](docs/standards/infrastructure-code.md)
- [Architecture Documentation](docs/architecture/)
- [Runbooks](docs/runbooks/)
- [Tutorials](docs/tutorials/)

### External Resources
- [Terraform Documentation](https://www.terraform.io/docs)
- [Ansible Documentation](https://docs.ansible.com)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- [Docker Documentation](https://docs.docker.com)
- [AWS Documentation](https://docs.aws.amazon.com)

## License

This framework is provided as-is for systems engineering work.

## Acknowledgments

Built with Claude Code for efficient AI-assisted infrastructure development.
