# Claude Code Docker Setup — Quick Reference

> **New to Docker or want more explanation?** See the main [README.md](README.md) for a complete guide with diagrams, security explanations, and step-by-step instructions.
>
> **This document is for:** Users already comfortable with Docker who want a condensed reference.

---

Run Claude Code entirely in Docker — nothing installed on your host except Docker itself. All commits and pushes are attributed to `eli_the_cat`.

**Included software:**
- Python 3 + pandas, numpy, matplotlib, seaborn, scipy, statsmodels, scikit-learn
- R + 50 packages (see below)
- Git + GitHub CLI
- Claude Code

**R packages:**
- *Data:* tidyverse, data.table, haven, readxl, openxlsx, janitor, lubridate, here, fs, jsonlite, glue, httr2
- *Econometrics:* fixest, did, lfe, estimatr, sandwich, clubSandwich, plm, AER, ivreg, rdrobust, DRDID, synthdid, gsynth, Synth
- *Modeling:* lme4, survival, caret, randomForest, MASS, Matrix, broom, car
- *Tables:* modelsummary, stargazer, kableExtra, knitr, rmarkdown, tinytex
- *Plots:* patchwork, cowplot, ggrepel, ggthemes, viridis, scales, gridExtra
- *Spatial:* sf, terra
- *Utilities:* parallel, foreach, doParallel, future, devtools, Rcpp

## Quick Start

```bash
# 1. First-time setup (creates directories, builds image)
chmod +x *.sh
./setup.sh

# 2. Authenticate Claude Code (one-time, opens browser)
./authenticate-claude.sh

# 3. Authenticate GitHub (one-time, interactive)
./authenticate-github.sh

# 4. Run Claude!
./run.sh https://github.com/you/your-repo                        # Interactive
./run-autonomous.sh https://github.com/you/your-repo "Fix bugs"  # Autonomous
```

## Two Modes

**GitHub mode (recommended):** Clone from GitHub, work in container, push back. Your local files are never touched.
```bash
./run.sh https://github.com/eli_the_cat/my-project
./run.sh https://github.com/eli_the_cat/my-project dev    # specific branch
```

**Local mode:** Mount a local folder. Claude edits files directly on your computer.
```bash
./run.sh ~/repos/my-project
```

## Running Multiple Projects Simultaneously

Each command runs in its own container:

```bash
# Terminal 1
./run.sh https://github.com/eli_the_cat/project-a

# Terminal 2
./run.sh https://github.com/eli_the_cat/project-b

# Terminal 3
./run-autonomous.sh https://github.com/eli_the_cat/project-c "Run tests"
```

## Directory Structure

```
.
├── Dockerfile                 # Container definition
├── docker-compose.yml         # Container configuration (used for build)
├── setup.sh                   # First-time setup
├── authenticate-claude.sh     # Claude Code login
├── authenticate-github.sh     # GitHub CLI login
├── run.sh                     # Interactive mode
├── run-autonomous.sh          # Autonomous mode
└── auth/                      # Credentials (gitignored)
    ├── claude/                # Claude Code auth tokens
    ├── gh/                    # GitHub CLI credentials
    └── gitconfig              # Git config for eli_the_cat
```

## How It Works

1. **Isolation**: Claude Code runs inside a Docker container. It cannot access your computer except what you explicitly give it.

2. **GitHub mode**: Claude clones the repo inside the container, works there, and pushes. Your local files are untouched.

3. **Local mode**: Your folder is mounted into the container. Claude can read/write those files directly.

4. **Git Identity**: All commits are made as `eli_the_cat <eli_the_cat@users.noreply.github.com>`.

5. **Autonomous Mode**: The `--dangerously-skip-permissions` flag lets Claude run without asking for confirmation.

## Usage

```bash
# GitHub mode (your local files stay untouched)
./run.sh <github-url> [branch]
./run-autonomous.sh <github-url> "<prompt>" [branch]

# Local mode (edits files on your computer)
./run.sh <local-path>
./run-autonomous.sh <local-path> "<prompt>"
```

## Autonomous Examples

```bash
# Clone, fix bugs, push — your local files untouched
./run-autonomous.sh https://github.com/eli_the_cat/app "Review and fix any bugs, then push"

# Work on a specific branch
./run-autonomous.sh https://github.com/eli_the_cat/app "Add unit tests" feature-branch

# Data analysis (local mode)
./run-autonomous.sh ~/data/analysis "Load data.csv, run regression in R, save results"
```

## How GitHub Mode Works

```
1. You run:  ./run.sh https://github.com/eli_the_cat/my-project

2. Container starts, clones the repo:
   ┌─────────────────────────┐
   │  DOCKER CONTAINER       │
   │                         │
   │  git clone <url>        │
   │  Claude edits files     │
   │  git commit             │
   │  git push               │
   └─────────────────────────┘

3. Changes appear on GitHub

4. When you're ready, pull to your local machine:
   git pull
```

Your local files are never touched until you explicitly pull.

## Security Notes

- **Container isolation**: Claude runs in a container with limited access
- **Credentials stay local**: Auth tokens are in `./auth/`, never baked into the image
- **Project is writable**: Unlike some setups, your project IS writable (Claude needs this to make changes)
- **Review before pushing**: Consider running without auto-push first, review changes, then push manually

## Troubleshooting

**"Claude not authenticated"**
```bash
./authenticate-claude.sh
```

**"gh: not logged in"**
```bash
./authenticate-github.sh
```

**"Permission denied" on scripts**
```bash
chmod +x *.sh
```

**Git "unsafe repository" error**
The run scripts add `/workspace` to safe directories automatically. If you still see this, the gitconfig might not be mounting correctly.

**Want to use SSH instead of HTTPS for GitHub?**
1. Put your SSH key in `./auth/ssh/id_ed25519` (and `id_ed25519.pub`)
2. Run: `chmod 600 ./auth/ssh/id_ed25519`
3. Edit docker-compose.yml to use SSH URLs, or configure git inside the container
