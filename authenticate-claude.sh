#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Authenticating Claude Code ==="
echo ""
echo "This will set up Claude authentication that persists between sessions."
echo ""

# Step 1: Create the critical .claude.json file
echo "Step 1: Creating config file..."
cat > "$SCRIPT_DIR/auth/claude.json" << 'EOF'
{
  "hasCompletedOnboarding": true,
  "theme": "dark"
}
EOF
echo "✓ Created auth/claude.json"
echo ""

# Step 2: Get long-lived token
echo "Step 2: Generating long-lived OAuth token..."
echo ""
echo "This will open a browser for authentication."
echo "Select 'Claude account with subscription' when prompted."
echo ""
read -p "Press ENTER to continue..."

# Run claude setup-token in container and capture output
TOKEN=$(docker run -it --rm \
    -v "$SCRIPT_DIR/auth/claude":/home/claude/.claude \
    -v "$SCRIPT_DIR/auth/claude.json":/home/claude/.claude.json \
    claude-code-docker \
    bash -c "claude setup-token 2>&1" | grep -o 'sk-ant-oat01-[^ ]*' | head -1 | tr -d '\r')

if [ -z "$TOKEN" ]; then
    echo ""
    echo "Could not automatically capture token."
    echo "Please copy the token from above (starts with sk-ant-oat01-...)"
    echo ""
    read -p "Paste your token here: " TOKEN
fi

# Clean the token (remove any trailing whitespace/newlines)
TOKEN=$(echo "$TOKEN" | tr -d '[:space:]')

if [ -z "$TOKEN" ]; then
    echo "ERROR: No token provided. Please run this script again."
    exit 1
fi

# Step 3: Save token to file
echo "$TOKEN" > "$SCRIPT_DIR/auth/oauth_token"
echo ""
echo "✓ Token saved to auth/oauth_token"

# Step 4: Create credentials file
echo ""
echo "Step 3: Creating credentials file..."
mkdir -p "$SCRIPT_DIR/auth/claude"
cat > "$SCRIPT_DIR/auth/claude/.credentials.json" << EOF
{
  "claudeAiOauth": {
    "accessToken": "$TOKEN",
    "refreshToken": "$TOKEN",
    "expiresAt": 9999999999999,
    "scopes": ["user:inference", "user:profile"]
  }
}
EOF
echo "✓ Created auth/claude/.credentials.json"

# Step 5: Set permissions
chmod 600 "$SCRIPT_DIR/auth/oauth_token"
chmod 600 "$SCRIPT_DIR/auth/claude/.credentials.json"

echo ""
echo "=== Authentication Complete ==="
echo ""
echo "Your token (save this somewhere safe!):"
echo "$TOKEN"
echo ""
echo "You can now run:"
echo "  ./run.sh https://github.com/your/repo"
echo ""
