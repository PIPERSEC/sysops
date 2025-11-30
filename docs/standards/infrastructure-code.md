# Infrastructure as Code Standards

## General Principles

### Version Control
- All infrastructure code must be version controlled
- Use meaningful commit messages
- Require code review for infrastructure changes
- Tag releases appropriately

### Documentation
- Every module/role must have a README
- Document variables, inputs, and outputs
- Include usage examples
- Maintain architecture diagrams

### Testing
- Test infrastructure code before applying to production
- Use staging/development environments
- Implement automated testing where possible
- Validate syntax and formatting

## Terraform Standards

### Project Structure
```
terraform-project/
├── main.tf              # Main configuration
├── variables.tf         # Input variables
├── outputs.tf          # Output values
├── versions.tf         # Terraform and provider versions
├── terraform.tfvars    # Variable values (not committed)
├── backend.tf          # Backend configuration
├── modules/            # Custom modules
│   └── module-name/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
└── environments/       # Environment-specific configs
    ├── dev/
    ├── staging/
    └── prod/
```

### Naming Conventions
- Use lowercase with hyphens for resource names
- Prefix resources with project/environment identifier
- Use descriptive names that indicate purpose
- Example: `prod-web-server`, `dev-database-subnet`

### Best Practices
- Use remote state with locking (S3 + DynamoDB)
- Implement workspaces for environment separation
- Use modules for reusable components
- Pin provider versions
- Use data sources instead of hardcoding
- Implement proper tagging strategy
- Use `terraform fmt` before committing
- Run `terraform validate` in CI/CD
- Use `terraform plan` before apply
- Never commit `.tfstate` files

### Variables
- Define all variables in `variables.tf`
- Provide descriptions for all variables
- Set sensible defaults where appropriate
- Use validation blocks for critical variables
- Group related variables together

### Outputs
- Export useful values as outputs
- Provide descriptions for all outputs
- Mark sensitive outputs appropriately

### Modules
- Keep modules focused and single-purpose
- Version modules using Git tags
- Include comprehensive README
- Provide examples in module documentation

## Ansible Standards

### Project Structure
```
ansible-project/
├── ansible.cfg         # Ansible configuration
├── inventory/          # Inventory files
│   ├── hosts.ini
│   └── group_vars/
│       └── all.yml
├── playbooks/          # Playbooks
│   └── site.yml
├── roles/              # Roles
│   └── role-name/
│       ├── tasks/
│       ├── handlers/
│       ├── templates/
│       ├── files/
│       ├── vars/
│       ├── defaults/
│       └── meta/
└── collections/        # Ansible collections
```

### Naming Conventions
- Use snake_case for variables
- Use descriptive role names
- Prefix internal variables with role name
- Use meaningful task names

### Best Practices
- Use roles for organization
- Keep playbooks simple, put logic in roles
- Use handlers for service restarts
- Implement proper error handling
- Use `ansible-vault` for secrets
- Tag tasks for selective execution
- Use `check` mode for dry runs
- Run `ansible-lint` before committing
- Use `become` only when necessary
- Avoid `command` and `shell` modules when alternatives exist

### Variables
- Define defaults in `defaults/main.yml`
- Override in `group_vars` and `host_vars`
- Use Ansible Vault for sensitive data
- Document all variables in README

### Idempotency
- Ensure all tasks are idempotent
- Use appropriate modules (package vs apt/yum)
- Check state before making changes
- Use `changed_when` and `failed_when` appropriately

## Kubernetes Standards

### Manifest Structure
```
k8s-project/
├── base/               # Base configurations
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/           # Environment-specific
    ├── dev/
    ├── staging/
    └── prod/
```

### Naming Conventions
- Use lowercase with hyphens
- Follow pattern: `<app>-<component>-<resource-type>`
- Example: `web-app-frontend-deployment`

### Best Practices
- Use namespaces for isolation
- Define resource requests and limits
- Implement health checks (liveness and readiness)
- Use ConfigMaps for configuration
- Use Secrets for sensitive data
- Implement RBAC properly
- Use labels consistently
- Implement pod security policies
- Use Helm or Kustomize for templating
- Version container images explicitly (no `latest`)

### Labels
Required labels:
```yaml
labels:
  app: application-name
  version: v1.0.0
  component: backend
  managed-by: kubectl
```

### Security
- Run containers as non-root
- Use read-only root filesystem
- Drop unnecessary capabilities
- Implement pod security standards
- Scan images for vulnerabilities
- Use network policies

## Docker Standards

### Dockerfile Best Practices
- Use official base images
- Use specific tags, not `latest`
- Implement multi-stage builds
- Minimize layers
- Order instructions by change frequency
- Run as non-root user
- Use .dockerignore
- Implement health checks
- Don't install unnecessary packages
- Clean up in same layer

### Image Naming
Format: `registry/organization/image-name:tag`
- Use semantic versioning for tags
- Include git commit SHA as alternative tag
- Example: `myregistry.com/myapp/api:v1.2.3`

### Security
- Scan images regularly
- Keep base images updated
- Don't store secrets in images
- Use minimal base images (alpine, distroless)
- Sign images

## General Security Standards

### Secrets Management
- Never commit secrets to version control
- Use secret management tools (Vault, AWS Secrets Manager)
- Rotate secrets regularly
- Use environment-specific secrets
- Implement least privilege access

### Access Control
- Implement RBAC
- Use service accounts appropriately
- Audit access regularly
- Enable MFA where possible

### Compliance
- Tag resources for cost allocation
- Implement audit logging
- Regular security scanning
- Follow industry standards (CIS benchmarks)
- Document compliance requirements
