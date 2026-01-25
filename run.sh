#!/bin/bash
set -e

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Show usage if no arguments
if [ -z "$1" ]; then
    echo "Usage:"
    echo "  ./run.sh <github-url> [branch]     # Clone from GitHub"
    echo "  ./run.sh <local-path>              # Mount local folder"
    echo ""
    echo "Examples:"
    echo "  ./run.sh https://github.com/eli_the_cat/my-project"
    echo "  ./run.sh https://github.com/eli_the_cat/my-project dev"
    echo "  ./run.sh ~/repos/my-project"
    exit 1
fi

# Detect if first arg is a URL or a path
if [[ "$1" == http* ]] || [[ "$1" == git@* ]]; then
    # GitHub URL mode
    REPO_URL="$1"
    BRANCH="${2:-}"  # Optional branch, empty if not provided
    
    echo "=== Starting Claude Code (Interactive) ==="
    echo ""
    echo "Mode:         GitHub clone (your local files are NOT touched)"
    echo "Repository:   $REPO_URL"
    if [ -n "$BRANCH" ]; then
        echo "Branch:       $BRANCH"
    fi
    echo "Git identity: eli_the_cat"
    echo ""
    
    if [ -n "$BRANCH" ]; then
        CLONE_CMD="git clone --branch $BRANCH $REPO_URL /workspace"
    else
        CLONE_CMD="git clone $REPO_URL /workspace"
    fi
    
    # Create outputs folder if it doesn't exist
    mkdir -p "$SCRIPT_DIR/outputs"
    
    docker run -it --rm \
        -p 3000:3000 \
        -p 5173:5173 \
        -p 8080:8080 \
        -v "$SCRIPT_DIR/auth/claude":/home/claude/.claude \
        -v "$SCRIPT_DIR/auth/claude.json":/home/claude/.claude.json \
        -v "$SCRIPT_DIR/auth/gh":/home/claude/.config/gh \
        -v "$SCRIPT_DIR/auth/ssh":/home/claude/.ssh:ro \
        -v "$SCRIPT_DIR/outputs":/home/claude/outputs \
        -e GIT_AUTHOR_NAME=eli_the_cat \
        -e GIT_AUTHOR_EMAIL=eli_the_cat@users.noreply.github.com \
        -e GIT_COMMITTER_NAME=eli_the_cat \
        -e GIT_COMMITTER_EMAIL=eli_the_cat@users.noreply.github.com \
        -e CLAUDE_CODE_OAUTH_TOKEN="$(cat "$SCRIPT_DIR/auth/oauth_token" 2>/dev/null || echo '')" \
        claude-code-docker \
        bash -c "
            git config --global user.name 'eli_the_cat' &&
            git config --global user.email 'eli_the_cat@users.noreply.github.com' &&
            echo 'Cloning repository...' &&
            $CLONE_CMD &&
            cd /workspace &&
            echo '' &&
            echo 'Ready! Repository cloned. Changes will be pushed to GitHub.' &&
            echo 'Figures saved to ~/outputs/ will appear in your local outputs/ folder.' &&
            echo '' &&
            claude
        "
else
    # Local path mode
    PROJECT_PATH="$1"
    
    # Convert to absolute path
    if [ -d "$PROJECT_PATH" ]; then
        PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"
    else
        echo "Error: Directory not found: $PROJECT_PATH"
        exit 1
    fi
    
    echo "=== Starting Claude Code (Interactive) ==="
    echo ""
    echo "Mode:         Local mount (files on your computer will be modified)"
    echo "Project:      $PROJECT_PATH"
    echo "Git identity: eli_the_cat"
    echo ""
    
    docker run -it --rm \
        -p 3000:3000 \
        -p 5173:5173 \
        -p 8080:8080 \
        -v "$PROJECT_PATH:/workspace" \
        -v "$SCRIPT_DIR/auth/claude:/home/claude/.claude" \
        -v "$SCRIPT_DIR/auth/claude.json:/home/claude/.claude.json" \
        -v "$SCRIPT_DIR/auth/gh:/home/claude/.config/gh" \
        -v "$SCRIPT_DIR/auth/ssh:/home/claude/.ssh:ro" \
        -e GIT_AUTHOR_NAME=eli_the_cat \
        -e GIT_AUTHOR_EMAIL=eli_the_cat@users.noreply.github.com \
        -e GIT_COMMITTER_NAME=eli_the_cat \
        -e GIT_COMMITTER_EMAIL=eli_the_cat@users.noreply.github.com \
        -e CLAUDE_CODE_OAUTH_TOKEN="$(cat "$SCRIPT_DIR/auth/oauth_token" 2>/dev/null || echo '')" \
        claude-code-docker \
        bash -c "
            git config --global user.name 'eli_the_cat' &&
            git config --global user.email 'eli_the_cat@users.noreply.github.com' &&
            git config --global --add safe.directory /workspace &&
            claude
        "
fi
