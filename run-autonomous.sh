#!/bin/bash
set -e

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Show usage if no arguments
if [ -z "$1" ]; then
    echo "Usage:"
    echo "  ./run-autonomous.sh <github-url> \"<prompt>\" [branch]"
    echo "  ./run-autonomous.sh <local-path> \"<prompt>\""
    echo ""
    echo "Examples:"
    echo "  ./run-autonomous.sh https://github.com/eli_the_cat/my-project \"Fix bugs and push\""
    echo "  ./run-autonomous.sh https://github.com/eli_the_cat/my-project \"Fix bugs\" dev"
    echo "  ./run-autonomous.sh ~/repos/my-project \"Fix bugs\""
    echo ""
    echo "This runs Claude with --dangerously-skip-permissions (no confirmation prompts)."
    exit 1
fi

# Detect if first arg is a URL or a path
if [[ "$1" == http* ]] || [[ "$1" == git@* ]]; then
    # GitHub URL mode
    REPO_URL="$1"
    PROMPT="$2"
    BRANCH="${3:-}"  # Optional branch
    
    if [ -z "$PROMPT" ]; then
        echo "Error: No prompt provided"
        echo "Usage: ./run-autonomous.sh <github-url> \"<prompt>\" [branch]"
        exit 1
    fi
    
    echo "=== Starting Claude Code (Autonomous) ==="
    echo ""
    echo "Mode:         GitHub clone (your local files are NOT touched)"
    echo "Repository:   $REPO_URL"
    if [ -n "$BRANCH" ]; then
        echo "Branch:       $BRANCH"
    fi
    echo "Git identity: eli_the_cat"
    echo "Prompt:       $PROMPT"
    echo ""
    echo "Claude will run WITHOUT permission prompts."
    echo ""
    
    if [ -n "$BRANCH" ]; then
        CLONE_CMD="git clone --branch $BRANCH $REPO_URL /workspace"
    else
        CLONE_CMD="git clone $REPO_URL /workspace"
    fi
    
    docker run -it --rm \
        -v "$SCRIPT_DIR/auth/claude":/home/claude/.claude \
        -v "$SCRIPT_DIR/auth/claude.json":/home/claude/.claude.json \
        -v "$SCRIPT_DIR/auth/gh":/home/claude/.config/gh \
        -v "$SCRIPT_DIR/auth/ssh":/home/claude/.ssh:ro \
        -v "$SCRIPT_DIR/auth/gitconfig":/home/claude/.gitconfig:ro \
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
            claude --dangerously-skip-permissions -p \"$PROMPT\"
        "
else
    # Local path mode
    PROJECT_PATH="$1"
    PROMPT="$2"
    
    if [ -z "$PROMPT" ]; then
        echo "Error: No prompt provided"
        echo "Usage: ./run-autonomous.sh <local-path> \"<prompt>\""
        exit 1
    fi
    
    # Convert to absolute path
    PROJECT_PATH=$(cd "$PROJECT_PATH" 2>/dev/null && pwd || echo "$PROJECT_PATH")
    
    if [ ! -d "$PROJECT_PATH" ]; then
        echo "Error: Directory not found: $PROJECT_PATH"
        exit 1
    fi
    
    echo "=== Starting Claude Code (Autonomous) ==="
    echo ""
    echo "Mode:         Local mount (files on your computer will be modified)"
    echo "Project:      $PROJECT_PATH"
    echo "Git identity: eli_the_cat"
    echo "Prompt:       $PROMPT"
    echo ""
    echo "Claude will run WITHOUT permission prompts."
    echo ""
    
    docker run -it --rm \
        -v "$PROJECT_PATH":/workspace \
        -v "$SCRIPT_DIR/auth/claude":/home/claude/.claude \
        -v "$SCRIPT_DIR/auth/claude.json":/home/claude/.claude.json \
        -v "$SCRIPT_DIR/auth/gh":/home/claude/.config/gh \
        -v "$SCRIPT_DIR/auth/ssh":/home/claude/.ssh:ro \
        -v "$SCRIPT_DIR/auth/gitconfig":/home/claude/.gitconfig:ro \
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
            claude --dangerously-skip-permissions -p \"$PROMPT\"
        "
fi

echo ""
echo "=== Claude Code finished ==="
