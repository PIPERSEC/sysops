# Setting Up GitHub Repository

This guide will help you push your SysOps framework to GitHub.

## Option 1: Using GitHub CLI (Recommended)

### Step 1: Install GitHub CLI

**macOS:**
```bash
brew install gh
```

**Linux (Debian/Ubuntu):**
```bash
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

**Other platforms:**
See [GitHub CLI installation guide](https://github.com/cli/cli#installation)

### Step 2: Authenticate

```bash
gh auth login
```

Follow the prompts to authenticate with GitHub.

### Step 3: Run Setup Script

```bash
./scripts/setup-github.sh
```

The script will:
- Prompt for repository name (default: sysops)
- Ask for a description
- Ask about repository visibility (public/private)
- Create the repository on GitHub
- Add it as a remote
- Push your code

## Option 2: Manual Setup via GitHub Web Interface

### Step 1: Create Repository on GitHub

1. Go to [GitHub](https://github.com)
2. Click the "+" icon in the top right
3. Select "New repository"
4. Fill in:
   - **Repository name**: `sysops` (or your preferred name)
   - **Description**: "Systems Engineering Framework with AI-assisted workflows"
   - **Visibility**: Choose Public or Private
   - **DO NOT** initialize with README, .gitignore, or license (we already have these)
5. Click "Create repository"

### Step 2: Add Remote and Push

GitHub will show you instructions. Use the "push an existing repository" commands:

```bash
# Add GitHub as remote origin
git remote add origin https://github.com/PIPERSEC/sysops.git

# Push to GitHub
git push -u origin main
```

If you prefer SSH:

```bash
# Add GitHub as remote origin (SSH)
git remote add origin git@github.com:PIPERSEC/sysops.git

# Push to GitHub
git push -u origin main
```

### Step 3: Verify

Visit your repository at `https://github.com/PIPERSEC/sysops` to verify everything uploaded correctly.

## Post-Setup Configuration

### Branch Protection (Recommended)

1. Go to your repository on GitHub
2. Click "Settings" > "Branches"
3. Under "Branch protection rules", click "Add rule"
4. For branch name pattern, enter: `main`
5. Enable:
   - ✅ Require a pull request before merging
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - ✅ Include administrators
6. Click "Create"

### Add Repository Topics

Add topics to help others discover your repository:

1. Go to your repository on GitHub
2. Click the gear icon next to "About"
3. Add topics: `systems-engineering`, `devops`, `infrastructure-as-code`, `terraform`, `ansible`, `kubernetes`, `ai-assisted`

### Enable GitHub Actions (Optional)

Create `.github/workflows/validate.yml` for CI/CD:

```yaml
name: Validate Infrastructure Code

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  terraform:
    name: Validate Terraform
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0

      - name: Terraform Format Check
        run: terraform fmt -check -recursive
        working-directory: templates/terraform

      - name: Terraform Init
        run: terraform init
        working-directory: templates/terraform/vpc

      - name: Terraform Validate
        run: terraform validate
        working-directory: templates/terraform/vpc

  ansible:
    name: Validate Ansible
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install Ansible
        run: pip install ansible ansible-lint

      - name: Ansible Lint
        run: ansible-lint templates/ansible/

  markdown:
    name: Lint Markdown
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Markdown Lint
        uses: nosborn/github-action-markdown-cli@v3.2.0
        with:
          files: .
          config_file: .markdownlint.json
```

## Cloning to Other Machines

Once pushed to GitHub, you can clone on other machines:

```bash
# Clone the repository
git clone https://github.com/PIPERSEC/sysops.git
cd sysops

# Activate virtual environment
source bin/activate

# Install dependencies (if any)
pip install -r requirements.txt
```

## Keeping Your Repository Updated

### Regular Workflow

```bash
# Make changes to your files
# ...

# Stage changes
git add .

# Commit with descriptive message
git commit -m "feat(terraform): add RDS module template"

# Push to GitHub
git push
```

### Syncing from Other Machines

```bash
# Pull latest changes
git pull

# If you have local changes, use rebase
git pull --rebase
```

## Collaboration

### Adding Collaborators

1. Go to your repository on GitHub
2. Click "Settings" > "Collaborators"
3. Click "Add people"
4. Enter GitHub username
5. Select permission level
6. Send invitation

### Working with Pull Requests

When working in a team:

```bash
# Create feature branch
git checkout -b feature/new-k8s-template

# Make changes and commit
git add .
git commit -m "feat(k8s): add StatefulSet template"

# Push branch
git push -u origin feature/new-k8s-template

# Create pull request on GitHub
gh pr create --title "Add StatefulSet template" --body "Adds Kubernetes StatefulSet template for databases"
```

## Troubleshooting

### Authentication Issues

**HTTPS:**
Use a personal access token instead of password:
1. Go to GitHub Settings > Developer settings > Personal access tokens
2. Generate new token with `repo` scope
3. Use token as password when pushing

**SSH:**
Ensure SSH key is added to GitHub:
```bash
# Generate SSH key if needed
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy public key
cat ~/.ssh/id_ed25519.pub

# Add to GitHub: Settings > SSH and GPG keys > New SSH key
```

### Large File Issues

If you accidentally committed large files:

```bash
# Remove from git but keep locally
git rm --cached large_file.bin

# Add to .gitignore
echo "large_file.bin" >> .gitignore

# Commit the change
git commit -m "chore: remove large file from git"
```

### Reset to GitHub State

```bash
# Discard local changes and match GitHub
git fetch origin
git reset --hard origin/main
```

## Next Steps

- ✅ Repository created and pushed
- ⬜ Set up branch protection
- ⬜ Configure GitHub Actions
- ⬜ Add collaborators
- ⬜ Create project board for tracking work
- ⬜ Set up GitHub Pages for documentation (optional)

Congratulations! Your SysOps framework is now on GitHub and ready for collaborative development.
