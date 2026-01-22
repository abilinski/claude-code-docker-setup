#!/bin/bash
set -e

echo "=== Claude Code Docker Setup for eli_the_cat ==="
echo ""

# Create directory structure
echo "Creating directory structure..."
mkdir -p auth/claude
mkdir -p auth/gh
mkdir -p auth/ssh

# Create gitconfig
echo "Creating git config for eli_the_cat..."
cat > auth/gitconfig << 'EOF'
[user]
    name = eli_the_cat
    email = eli_the_cat@users.noreply.github.com
[init]
    defaultBranch = main
[push]
    autoSetupRemote = true
EOF

# Create claude.json (critical for skipping onboarding)
echo "Creating Claude config file..."
cat > auth/claude.json << 'EOF'
{
  "hasCompletedOnboarding": true,
  "theme": "dark"
}
EOF

echo ""
echo "=== Directory Structure Created ==="
echo ""
echo "  auth/"
echo "  ├── claude/       <- Claude Code credentials"
echo "  ├── claude.json   <- Claude config (skips onboarding)"
echo "  ├── gh/           <- GitHub CLI credentials"
echo "  ├── ssh/          <- SSH keys (optional)"
echo "  └── gitconfig     <- Git config as eli_the_cat"
echo ""

# Build the Docker image
echo "Building Docker image..."
echo "(This will take 15-30 minutes the first time — lots of R packages to compile)"
echo ""
docker compose build

echo ""
echo "=== Setup Complete ==="
echo ""
echo "SOFTWARE INSTALLED:"
echo "  ✓ Python 3 + pandas, numpy, matplotlib, seaborn, scikit-learn, statsmodels"
echo "  ✓ R + 50 packages (econometrics, tidyverse, spatial, etc.)"
echo "  ✓ Git + GitHub CLI"
echo "  ✓ Claude Code"
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. AUTHENTICATE CLAUDE CODE (one-time):"
echo "   ./authenticate-claude.sh"
echo ""
echo "2. AUTHENTICATE GITHUB (one-time):"
echo "   ./authenticate-github.sh"
echo ""
echo "3. RUN CLAUDE:"
echo "   ./run.sh https://github.com/you/repo           # GitHub mode (safer)"
echo "   ./run.sh ~/path/to/project                     # Local mode"
echo "   ./run-autonomous.sh <url-or-path> \"prompt\"    # Hands-off mode"
echo ""
