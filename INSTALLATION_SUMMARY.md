# Development Environment Installation Summary

**Date**: 2025-11-30
**Status**: ✅ Complete

## Installed Tools

### Infrastructure as Code
- ✅ **Terraform** v1.5.7
  - Location: `/opt/homebrew/bin/terraform`
  - Usage: `terraform init`, `terraform plan`, `terraform apply`
  - Note: Version 1.14.0 available (optional upgrade)

### Configuration Management
- ✅ **Ansible** [core 2.20.0]
  - Location: `./bin/ansible` (virtual environment)
  - Usage: `ansible-playbook -i inventory playbook.yml`

- ✅ **Ansible Lint** v25.11.1
  - Location: `./bin/ansible-lint` (virtual environment)
  - Usage: `ansible-lint playbook.yml`

### Container & Orchestration
- ✅ **Docker** v29.1.1
  - Location: `/opt/homebrew/bin/docker`
  - Usage: `docker build`, `docker run`, `docker compose`
  - Note: Docker Desktop may need to be running for daemon access

- ✅ **kubectl** v1.34.2
  - Location: `/opt/homebrew/bin/kubectl`
  - Usage: `kubectl apply -f manifest.yaml`
  - Note: Requires kubeconfig setup to connect to clusters

- ✅ **Helm** v4.0.1
  - Location: `/opt/homebrew/bin/helm`
  - Usage: `helm install <name> <chart>`

### Cloud CLI Tools
- ✅ **AWS CLI** v2.32.6
  - Location: `/opt/homebrew/bin/aws`
  - Usage: `aws configure`, `aws s3 ls`, etc.
  - Status: **Needs Configuration**

### Utility Tools
- ✅ **jq** v1.7.1 (JSON processor)
  - Location: `/usr/bin/jq`
  - Usage: `cat file.json | jq '.key'`

- ✅ **yq** v4.49.2 (YAML processor)
  - Location: `/opt/homebrew/bin/yq`
  - Usage: `cat file.yaml | yq '.key'`

- ✅ **tree** v2.2.1 (directory visualization)
  - Location: `/opt/homebrew/bin/tree`
  - Usage: `tree -L 2`

- ✅ **GitHub CLI** v2.83.1
  - Location: `/opt/homebrew/bin/gh`
  - Status: Authenticated as PIPERSEC

## Next Configuration Steps

### 1. Configure AWS CLI

Run the following to set up your AWS credentials:

```bash
aws configure
```

You'll be prompted for:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., `us-east-1`)
- Default output format (recommend `json`)

**Alternative**: Use AWS SSO
```bash
aws configure sso
```

### 2. Set Up Docker Desktop (if using GUI)

If you want to use Docker Desktop GUI:
1. Download from https://www.docker.com/products/docker-desktop
2. Install and launch
3. Verify: `docker ps`

Or use Docker daemon directly (already installed).

### 3. Configure kubectl (when ready to use Kubernetes)

To connect kubectl to a cluster:

**For local development (Minikube/Kind)**:
```bash
# Install minikube
brew install minikube

# Start local cluster
minikube start

# Verify
kubectl get nodes
```

**For AWS EKS**:
```bash
aws eks update-kubeconfig --name <cluster-name> --region <region>
```

**For Azure AKS**:
```bash
az aks get-credentials --resource-group <rg> --name <cluster>
```

**For Google GKE**:
```bash
gcloud container clusters get-credentials <cluster-name> --zone <zone>
```

### 4. Optional: Install Additional Cloud CLIs

**Azure CLI**:
```bash
brew install azure-cli
az login
```

**Google Cloud SDK**:
```bash
brew install google-cloud-sdk
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### 5. Set Up Git Credentials (Optional)

Configure git user details globally:
```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

Or keep repo-specific (already set for this repo as PIPERSEC).

## Tool Verification Commands

Run these to verify everything works:

```bash
# Infrastructure
terraform version
ansible --version
ansible-lint --version

# Containers
docker --version
kubectl version --client
helm version

# Cloud
aws --version
gh --version

# Utilities
jq --version
yq --version
tree --version
```

## Python Virtual Environment

This project uses a Python 3.13 virtual environment located at:
- **Path**: `/Users/jcox/Repos/Default/envs/sysops`
- **Activation**: `source bin/activate`
- **Installed packages**: ansible, ansible-lint, and dependencies

To install additional Python packages:
```bash
source bin/activate
pip install <package-name>
```

## VSCode Integration

The workspace is configured with tasks for:
- Terraform: Format, Validate, Plan
- Ansible: Lint, Syntax Check
- Docker: Build
- Kubernetes: Apply, Validate
- Python: Format, Lint

**Access tasks**: `Cmd+Shift+P` → "Tasks: Run Task"

## Recommended Extensions

The following VSCode extensions are recommended (see [.vscode/extensions.json](.vscode/extensions.json)):
- HashiCorp Terraform
- Red Hat Ansible
- Microsoft Python
- YAML Support
- Docker
- Kubernetes
- AWS Toolkit
- GitLens

Install all: Open VSCode, `Cmd+Shift+P` → "Extensions: Show Recommended Extensions"

## Quick Start Examples

### Create a Terraform VPC
```bash
cd projects
mkdir my-vpc && cd my-vpc
cp -r ../../templates/terraform/vpc .
cd vpc
terraform init
terraform plan
```

### Run an Ansible Playbook
```bash
cd projects
mkdir server-setup && cd server-setup
# Create your inventory and playbook
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --check
```

### Build and Run a Docker Container
```bash
cd projects/my-app
docker build -t myapp:v1 -f ../../templates/docker/Dockerfile .
docker run -p 8080:8080 myapp:v1
```

### Deploy to Kubernetes
```bash
kubectl apply -f templates/kubernetes/deployment.yaml
kubectl get pods
```

## Troubleshooting

### Docker daemon not running
```bash
# Check status
docker ps

# If error, start Docker Desktop or:
open -a Docker
```

### AWS credentials not configured
```bash
aws configure list
aws sts get-caller-identity  # Verify credentials work
```

### kubectl can't connect to cluster
```bash
kubectl config view  # Check current context
kubectl config get-contexts  # List available contexts
kubectl config use-context <context-name>  # Switch context
```

## Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Ansible Documentation](https://docs.ansible.com)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- [Docker Documentation](https://docs.docker.com)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli)
- [Helm Documentation](https://helm.sh/docs)

## Summary

Your development environment is now fully configured for:
- ✅ Infrastructure provisioning (Terraform)
- ✅ Configuration management (Ansible)
- ✅ Container development (Docker)
- ✅ Kubernetes orchestration (kubectl, Helm)
- ✅ Cloud operations (AWS CLI)
- ✅ Version control and collaboration (Git, GitHub CLI)
- ✅ Code quality (ansible-lint, formatters)

**Next steps**: Configure cloud credentials and start your first project!
