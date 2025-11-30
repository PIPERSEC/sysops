#!/bin/bash
# Setup GitHub repository for SysOps framework

set -euo pipefail

echo "========================================="
echo "GitHub Repository Setup for SysOps"
echo "========================================="
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) is not installed."
    echo ""
    echo "To install GitHub CLI:"
    echo "  macOS: brew install gh"
    echo "  Linux: See https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
    echo ""
    echo "After installing, run: gh auth login"
    echo ""
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "You need to authenticate with GitHub first."
    echo "Run: gh auth login"
    exit 1
fi

# Get repository details
read -p "Enter repository name (default: sysops): " REPO_NAME
REPO_NAME=${REPO_NAME:-sysops}

read -p "Enter repository description: " REPO_DESC
REPO_DESC=${REPO_DESC:-"Systems Engineering Framework with AI-assisted workflows"}

read -p "Make repository private? (y/N): " PRIVATE
PRIVATE=${PRIVATE:-N}

if [[ "$PRIVATE" =~ ^[Yy]$ ]]; then
    VISIBILITY="--private"
else
    VISIBILITY="--public"
fi

echo ""
echo "Creating GitHub repository..."
echo "Name: $REPO_NAME"
echo "Description: $REPO_DESC"
echo "Visibility: $VISIBILITY"
echo ""

# Create repository
gh repo create "$REPO_NAME" \
    --description "$REPO_DESC" \
    $VISIBILITY \
    --source=. \
    --remote=origin \
    --push

echo ""
echo "========================================="
echo "Repository created successfully!"
echo "========================================="
echo ""
echo "Repository URL: https://github.com/$(gh api user --jq .login)/$REPO_NAME"
echo ""
echo "Next steps:"
echo "1. Visit your repository on GitHub"
echo "2. Review the README and documentation"
echo "3. Set up branch protection rules (recommended)"
echo "4. Add collaborators if needed"
echo ""
