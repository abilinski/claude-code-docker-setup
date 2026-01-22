#!/bin/bash
set -e

echo "=== Authenticating GitHub CLI ==="
echo ""
echo "This will log you into GitHub so Claude can push as eli_the_cat."
echo "Your credentials will be stored in ./auth/gh/"
echo ""
echo "When prompted:"
echo "  - Choose 'GitHub.com'"
echo "  - Choose 'HTTPS' (recommended) or 'SSH'"
echo "  - Authenticate with browser or paste a token"
echo ""

docker compose run --rm claude bash -c "gh auth login"

echo ""
echo "GitHub authentication complete! Credentials saved to ./auth/gh/"
echo ""
echo "Verifying..."
docker compose run --rm claude bash -c "gh auth status"
