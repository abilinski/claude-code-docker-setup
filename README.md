# Claude Code in Docker: A Complete Guide

> **Who this is for:** Researchers and academics in quantitative fields who write statistical code in R or Python but aren't software engineers. You're comfortable running scripts and using the command line, but Docker may be new territory.
>
> **How this was made:** This guide and setup were largely generated with Claude Opus 4.5 through conversation. You can customize the specifications for your own needs, but it took some wrangling and debugging to get the authentication working reliably — sharing in case it saves others time.
>
> **Why this guide?** There are plenty of Docker + Claude Code setups on the internet, many aimed at professional software developers. This guide is hopefully right-sized for academics: enough isolation to protect sensitive research data, pre-installed packages you actually use (R with fixest, tidyverse, etc.), and straightforward scripts that don't require DevOps expertise to understand.
>
> **Just want the essentials?** See [QUICKSTART.md](QUICKSTART.md) for a condensed reference with just the commands and configuration details.

---

## Table of Contents

1. [What Is This?](#what-is-this)
2. [The Big Picture: Local vs Docker Installation](#the-big-picture-local-vs-docker-installation)
3. [One-Time Setup](#one-time-setup)
4. [Two Ways to Work: GitHub vs Local](#two-ways-to-work-github-vs-local)
5. [Two Interaction Styles: Interactive vs Autonomous](#two-interaction-styles-interactive-vs-autonomous)
6. [Putting It Together: Four Workflows](#putting-it-together-four-workflows)
7. [Working with Git and GitHub](#working-with-git-and-github)
8. [Running Multiple Projects at Once](#running-multiple-projects-at-once)
9. [What Software Is Available](#what-software-is-available)
10. [Troubleshooting](#troubleshooting)

---

## What Is This?

**Claude Code** is an AI assistant that can read, write, and run code. Think of it as having a very capable research assistant who can:

- Analyze data files
- Write and fix code
- Run statistical analyses
- Create visualizations
- Commit changes to GitHub

**Docker** is a tool that creates isolated "containers" — like a virtual computer inside your computer. The AI runs *inside* this container, which means:

- Claude Code is never installed directly on your computer
- The AI can only see files you explicitly share with it
- If anything goes wrong, it's contained in the sandbox

---

## The Big Picture: Local vs Docker Installation

You can install Claude Code in two ways. This guide uses the Docker approach for better security and isolation.

### Option 1: Local Installation (NOT this guide)

If you install Claude Code directly on your computer:

```
┌─────────────────────────────────────────────────────────────┐
│                     YOUR COMPUTER                           │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │              Claude Code (installed)                │   │
│   │                                                     │   │
│   │   Can potentially access:                           │   │
│   │   • All your files                                  │   │
│   │   • Documents, Downloads, Desktop                   │   │
│   │   • Other projects                                  │   │
│   │   • System files                                    │   │
│   │   • Environment variables, credentials              │   │
│   │   • Network connections                             │   │
│   │   • Other applications' data                        │   │
│   │                                                     │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   ⚠️  AI has broad access to your system                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### How Local Permissions Actually Work

Claude Code has a permission system, but it's important to understand its limitations:

**Read access:** By default, Claude Code can read any file your user account can read — including files outside your project folder — often without prompting. As one security researcher noted: "It has read permission to any file that the user running claude code has permission to, and it might be able to add the content of the file to the current context without prompting." ([Source: Pete Freitag's security analysis](https://www.petefreitag.com/blog/claude-code-permissions/))

**Write access:** Claude Code defaults to "read-only until approval" and will ask before editing files. However, the official documentation notes that "Write access restriction: Claude Code can only write to the folder where it was started and its subfolders" — but this only applies to the Edit tool, not to bash commands. ([Source: Anthropic Security Documentation](https://docs.anthropic.com/en/docs/claude-code/security))

**The practical reality:**
- Claude will typically *ask* before writing or executing commands
- But read operations on sensitive files (like `.env` files or SSH keys) may happen silently
- Permission deny rules have had bugs and may not work as expected
- If you approve bash commands, Claude has your full user permissions

**Bottom line:** The permission system provides some protection, but it's software-level controls that can have bugs. Docker provides OS-level isolation that's much harder to bypass.

### Option 2: Docker Installation (This guide)

With Docker, Claude Code runs in an isolated container:

```
┌─────────────────────────────────────────────────────────────┐
│                     YOUR COMPUTER                           │
│                                                             │
│   Your files:               The container:                  │
│   ┌───────────────┐        ┌───────────────────────────┐   │
│   │ Documents     │        │   DOCKER CONTAINER        │   │
│   │ Downloads     │        │                           │   │
│   │ Photos        │   🚫   │   Claude Code runs here   │   │
│   │ Other repos   │◄──────►│                           │   │
│   │ SSH keys      │ blocked│   Can ONLY see:           │   │
│   │ Passwords     │        │   • Files you share       │   │
│   │ Email         │        │   • GitHub credentials    │   │
│   └───────────────┘        │     (that you provide)    │   │
│                            │   • Internet (for GitHub) │   │
│   Only what you                                         │   │
│   explicitly share: ──────────────────┐                 │   │
│   ┌───────────────┐                   │                 │   │
│   │ One project   │   mounted    │   │                 │   │
│   │ folder        │──────────────┼───►                 │   │
│   └───────────────┘              ▼                     │   │
│                            └───────────────────────────┘   │
│                                                             │
│   ✅ AI only sees what you explicitly give it               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Why This Matters for Researchers

If you work with **sensitive data** — human subjects data, proprietary datasets, pre-publication research, data under IRB protocols, or anything covered by data use agreements — the Docker approach provides meaningful protection:

| Concern | Local Install | Docker Install |
|---------|--------------|----------------|
| AI accidentally reads sensitive files in another folder | Possible | Not possible |
| AI accesses data you haven't approved | Possible | Only if you mount it |
| Clear audit trail of what AI can access | Difficult | Easy — only mounted folders |
| Compliance with data use agreements | Harder to demonstrate | Clear boundaries |
| Risk if AI misbehaves | Broad system access | Contained to sandbox |

**This doesn't mean Docker is perfect** — if you mount a folder containing sensitive data, Claude can see it. But you have explicit control over what's shared, rather than implicit access to everything.

### What Can Claude See? Comparison

| | Local Installation | Docker Installation |
|---|---|---|
| Your home directory | ✅ Yes | ❌ No |
| Documents, Downloads, Desktop | ✅ Yes | ❌ No |
| Other project folders | ✅ Yes | ❌ No |
| SSH keys (~/.ssh) | ✅ Yes | ❌ No (unless you share them) |
| Environment variables | ✅ All of them | ❌ Only what you pass |
| Browser data | ✅ Potentially | ❌ No |
| The specific project you're working on | ✅ Yes | ✅ Yes (you mount it) |
| GitHub credentials | ✅ Yes | ✅ Yes (you provide them) |
| Internet access | ✅ Yes | ✅ Yes |

### What Persists Between Sessions?

In this Docker setup, some things are saved and available every time you start a new container:

| What | Where It's Stored | Persists? |
|------|-------------------|-----------|
| Claude login credentials | `auth/claude/` | ✅ Yes |
| GitHub login | `auth/gh/` | ✅ Yes |
| **Custom agents** you create | `auth/claude/` | ✅ Yes |
| **Conversation history** | `auth/claude/` | ✅ Yes |
| Claude settings/preferences | `auth/claude.json` | ✅ Yes |
| `CLAUDE.md` project instructions | In your repo | ✅ Yes (if committed) |
| Packages installed at runtime | Container memory | ❌ No (lost on exit) |

**About Agents:** Claude Code lets you create custom "agents" — reusable instruction sets for specific tasks. In this setup, agents are saved in the `auth/claude/` folder and persist between sessions.

**About CLAUDE.md:** You can create a `CLAUDE.md` file in any project repository with instructions that Claude will automatically follow when working on that project. For example:

```markdown
# CLAUDE.md

## Project Context
This is a replication package for a diff-in-diff analysis of minimum wage effects.

## Coding Standards
- Use tidyverse style for R code
- All regressions should use fixest
- Include robust standard errors clustered at the state level
- Save tables in both .tex and .csv formats

## File Structure
- /data/raw/ - Original data files (do not modify)
- /data/clean/ - Processed data
- /code/ - Analysis scripts
- /output/ - Tables and figures
```

Since `CLAUDE.md` lives in your repository, it's automatically available whenever you work on that project.

---

## What the Setup Creates

Before diving into the setup steps, here's what the `setup.sh` script does when you run it:

### Directory Structure

```
claude-docker-setup/
├── auth/                    ← Created by setup.sh
│   ├── claude/              ← Claude Code credentials (after authentication)
│   ├── claude.json          ← Config file to skip onboarding prompts
│   ├── gh/                  ← GitHub CLI credentials (after authentication)
│   ├── oauth_token          ← Your long-lived access token
│   └── gitconfig            ← Git identity configuration
├── Dockerfile               ← Instructions for building the container
├── docker-compose.yml       ← Container configuration
├── setup.sh                 ← First-time setup script
├── authenticate-claude.sh   ← Claude login script
├── authenticate-github.sh   ← GitHub login script
├── run.sh                   ← Interactive mode launcher
├── run-autonomous.sh        ← Autonomous mode launcher
└── GUIDE.md                 ← This documentation
```

### The Docker Image

The `setup.sh` script builds a Docker image containing all the software you need. This takes 15-30 minutes the first time (R packages need to compile), but only happens once.

**What gets installed:**

| Category | What's Included |
|----------|-----------------|
| Base system | Ubuntu Linux, Node.js 20 |
| Claude Code | The AI assistant itself |
| Python 3 | Plus pandas, numpy, matplotlib, seaborn, scipy, statsmodels, scikit-learn, jupyter, requests |
| R | Plus 50 packages (see [Appendix: R Packages](#appendix-r-packages)) |
| Git tools | Git, GitHub CLI |
| System libraries | GDAL, GEOS, PROJ (for spatial data), GSL (for statistics) |

The complete list of R packages is in the appendix at the end of this guide.

## One-Time Setup

You only need to do this once:

### Step 1: Run the setup script

Open Terminal and navigate to this folder:
```bash
cd /path/to/claude-docker-setup
```

Make the scripts executable and run setup:
```bash
chmod +x *.sh
./setup.sh
```

**What this does:**
- Creates folders for storing credentials
- Builds the Docker image with all the software (takes 15-30 minutes)

### Step 2: Authenticate Claude

```bash
./authenticate-claude.sh
```

**What this does:**
- Opens a browser window for you to log into your Claude account
- Saves a token so you don't have to log in every time

### Step 3: Authenticate GitHub

```bash
./authenticate-github.sh
```

**What this does:**
- Logs you into GitHub via the command line
- Allows Claude to push code changes on your behalf

**After setup, your folder looks like this:**
```
claude-docker-setup/
├── auth/                    ← Your saved credentials (don't delete!)
│   ├── claude/              ← Claude login tokens
│   ├── claude.json          ← Claude settings
│   ├── gh/                  ← GitHub login
│   ├── oauth_token          ← Long-lived access token
│   └── gitconfig            ← Git identity settings
├── run.sh                   ← Script to start Claude
├── run-autonomous.sh        ← Script to start Claude in hands-off mode
└── ... other files ...
```

---

## Two Ways to Work: GitHub vs Local

### Option A: GitHub Mode (Recommended)

```
┌──────────────┐         ┌─────────────────┐         ┌──────────────┐
│              │  clone  │                 │  push   │              │
│    GitHub    │ ──────► │    Container    │ ──────► │    GitHub    │
│    (cloud)   │         │  Claude works   │         │   (updated)  │
│              │         │     here        │         │              │
└──────────────┘         └─────────────────┘         └──────────────┘
                                                            │
                                                            │ You pull
                                                            │ when ready
                                                            ▼
                                                     ┌──────────────┐
                                                     │  Your local  │
                                                     │    files     │
                                                     └──────────────┘
```

**How it works:**
1. You give Claude a GitHub URL
2. Claude downloads (clones) the project inside the container
3. Claude makes changes
4. Claude uploads (pushes) changes back to GitHub
5. Your local files are **never touched**
6. When you're ready, you can download (pull) the changes

**Why use this mode:**
- Safest option — your local files can't be accidentally modified
- You can review changes on GitHub before accepting them
- Easy to undo if something goes wrong

**Command:**
```bash
./run.sh https://github.com/yourusername/your-repo
```

### Option B: Local Mode

```
┌─────────────────────────────────────────────────────────────┐
│                     YOUR COMPUTER                           │
│                                                             │
│   ┌─────────────────┐         ┌─────────────────────┐       │
│   │                 │ mounted │                     │       │
│   │  Your project   │◄───────►│     Container       │       │
│   │    folder       │  both   │   Claude works      │       │
│   │                 │  ways   │      here           │       │
│   └─────────────────┘         └─────────────────────┘       │
│                                                             │
│   Changes happen directly to your files!                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**How it works:**
1. You give Claude a path to a folder on your computer
2. That folder is "mounted" into the container (shared)
3. Claude can read and write files directly
4. Changes happen immediately on your computer

**Why use this mode:**
- Faster for quick edits
- No need to push/pull from GitHub
- Good for projects not on GitHub

**Command:**
```bash
./run.sh ~/Documents/my-project
```

**⚠️ Warning:** In local mode, Claude modifies your actual files. Make sure you have backups or use version control.

---

## Two Interaction Styles: Interactive vs Autonomous

### Interactive Mode

You have a conversation with Claude. You type requests, Claude responds, and asks for permission before doing things.

```
You:     "Can you look at the data.csv file and tell me what's in it?"
Claude:  "I see a CSV with 1,000 rows and 5 columns: id, name, date, value, category..."
You:     "Run a regression of value on category"
Claude:  "I'll create an R script for that. [Shows code] Should I run it?"
You:     "Yes"
Claude:  "Here are the results..."
```

**Command:**
```bash
./run.sh <github-url-or-local-path>
```

### Autonomous Mode

You give Claude a task upfront, and it works without asking for permission at each step. Good for well-defined tasks.

```
You run:  ./run-autonomous.sh https://github.com/me/repo "Analyze data.csv, 
          run a regression of value on category, save results to output.txt, 
          commit and push"
          
Claude:   [Works through the task without interrupting you]
          [Commits and pushes when done]
```

**Command:**
```bash
./run-autonomous.sh <github-url-or-local-path> "Your instructions here"
```

**⚠️ Warning:** In autonomous mode, Claude won't ask before making changes. Be specific in your instructions.

---

## Putting It Together: Four Workflows

Here's a summary of all four combinations:

### 1. GitHub + Interactive (Safest)

```bash
./run.sh https://github.com/yourusername/your-repo
```

- Chat back and forth with Claude
- Claude asks before doing things
- Changes go to GitHub, not your local files
- You review and pull when ready

**Best for:** Exploring a project, learning, careful work

### 2. GitHub + Autonomous

```bash
./run-autonomous.sh https://github.com/yourusername/your-repo "Your task here"
```

- Give Claude a task, let it work
- Changes go to GitHub
- Review the commits on GitHub when done

**Best for:** Well-defined tasks like "run all the tests" or "format the code"

### 3. Local + Interactive

```bash
./run.sh ~/Documents/my-project
```

- Chat back and forth with Claude
- Claude asks before doing things
- Changes happen directly to your files

**Best for:** Quick edits, projects not on GitHub

### 4. Local + Autonomous (Most Risky)

```bash
./run-autonomous.sh ~/Documents/my-project "Your task here"
```

- Give Claude a task, let it work
- Changes happen directly to your files
- No confirmation prompts

**Best for:** Batch processing, but **make sure you have backups**

---

## Working with Git and GitHub

### Understanding Git Basics

**Git** is version control — it tracks changes to files over time.

**GitHub** is a website that hosts Git projects and lets you collaborate.

Key terms:
- **Repository (repo):** A project folder tracked by Git
- **Commit:** A saved snapshot of changes
- **Push:** Upload commits to GitHub
- **Pull:** Download commits from GitHub
- **Clone:** Make a copy of a repo

### In GitHub Mode

**Claude does this automatically:**

1. **Clone:** Downloads the repo into the container
2. **Edit:** Makes changes to files
3. **Commit:** Saves the changes with a message
4. **Push:** Uploads to GitHub

**You do this when ready:**

```bash
cd ~/your-local-copy-of-repo
git pull
```

This downloads Claude's changes to your computer.

### Reviewing Changes on GitHub

After Claude pushes, go to your repository on github.com:

1. Click on "Commits" to see what changed
2. Click on a commit to see exactly what lines were modified
3. Green = added, Red = removed

### If You Don't Like the Changes

On GitHub:
1. Go to the commit you want to undo
2. Click "Revert" to create a new commit that undoes it

Or locally:
```bash
git revert <commit-hash>
git push
```

### Working on a Branch

To keep Claude's changes separate until you review them:

```bash
./run.sh https://github.com/you/repo experimental-branch
```

Claude works on `experimental-branch`. Your `main` branch is untouched.

---

## Running Multiple Projects at Once

Each command opens a separate container. You can run several at the same time in different terminal windows:

```
┌─────────────────────────────────────────────────────────────┐
│                     YOUR COMPUTER                           │
│                                                             │
│  Terminal 1              Terminal 2            Terminal 3   │
│  ┌───────────┐          ┌───────────┐        ┌───────────┐  │
│  │ Container │          │ Container │        │ Container │  │
│  │ Project A │          │ Project B │        │ Project C │  │
│  └───────────┘          └───────────┘        └───────────┘  │
│                                                             │
│  All running simultaneously, isolated from each other       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Example:**

```bash
# Terminal 1
./run.sh https://github.com/you/project-a

# Terminal 2  
./run.sh https://github.com/you/project-b

# Terminal 3
./run-autonomous.sh https://github.com/you/project-c "Run tests"
```

---

## What Software Is Available

Inside the container, Claude has access to:

### Python 3

Common packages pre-installed:
- **pandas** — data manipulation
- **numpy** — numerical computing
- **matplotlib, seaborn** — visualization
- **scipy** — scientific computing
- **statsmodels** — statistical models
- **scikit-learn** — machine learning
- **jupyter** — notebooks

### R

50 packages pre-installed, including:

| Category | Packages |
|----------|----------|
| Data wrangling | tidyverse, data.table, haven, readxl, openxlsx, janitor |
| Econometrics | fixest, did, lfe, estimatr, plm, AER, ivreg, rdrobust |
| Modeling | lme4, survival, caret, randomForest |
| Tables | modelsummary, stargazer, kableExtra |
| Visualization | ggplot2 (via tidyverse), patchwork, cowplot, ggthemes |
| Spatial | sf, terra |

### Other Tools

- **Git** — version control
- **GitHub CLI** — interact with GitHub
- **Standard Unix tools** — grep, sed, awk, etc.

### Installing Additional Packages

Claude can install more packages at runtime:

```r
# R
install.packages("new_package")
```

```python
# Python
pip install new_package
```

Note: These installations disappear when the container stops. To make them permanent, you'd need to edit the Dockerfile.

---

## Troubleshooting

### "Claude keeps asking me to log in"

The authentication fix requires three pieces:
1. `auth/oauth_token` — your long-lived token
2. `auth/claude.json` — with `hasCompletedOnboarding: true`
3. `auth/claude/.credentials.json` — formatted credentials

Re-run `./authenticate-claude.sh` to set these up correctly.

### "Permission denied" when running scripts

```bash
chmod +x *.sh
```

### "GitHub says I'm not logged in"

```bash
./authenticate-github.sh
```

### "Command not found: docker"

You need to install Docker Desktop:
- Mac: https://docs.docker.com/desktop/install/mac-install/
- Windows: https://docs.docker.com/desktop/install/windows-install/

### "The container is slow to start"

First run in a while? Docker might be loading the image. Subsequent runs are faster.

### "I want to start over"

```bash
# Remove all auth credentials
rm -rf auth/

# Re-run setup
./setup.sh
./authenticate-claude.sh
./authenticate-github.sh
```

### "Claude can't push to GitHub"

Check that:
1. You authenticated with `./authenticate-github.sh`
2. You have write access to the repository
3. The repository URL is correct

---

## Quick Reference

| I want to... | Command |
|-------------|---------|
| Start Claude on a GitHub repo | `./run.sh https://github.com/user/repo` |
| Start Claude on a local folder | `./run.sh ~/path/to/folder` |
| Give Claude a task to do alone | `./run-autonomous.sh <url-or-path> "task"` |
| Work on a specific branch | `./run.sh https://github.com/user/repo branch-name` |
| Exit Claude | Type `/exit` or press Ctrl+D |
| Exit the container | Type `exit` |

---

## Getting Help

- **Claude itself** — Ask Claude! It can explain what it's doing.
- **This guide** — Covers the Docker setup
- **Claude Code docs** — https://docs.anthropic.com/en/docs/claude-code

---

*Last updated: January 2026*

---

## Appendix: R Packages

The Docker image includes 50 R packages commonly used in quantitative research. They're organized by category:

### Data Manipulation
| Package | Description |
|---------|-------------|
| tidyverse | Collection including ggplot2, dplyr, tidyr, readr, purrr, tibble, stringr, forcats |
| data.table | Fast data manipulation for large datasets |
| haven | Read SPSS, Stata, and SAS files |
| readxl | Read Excel files |
| openxlsx | Read and write Excel files |
| janitor | Data cleaning utilities |
| lubridate | Date and time manipulation |
| here | Project-relative file paths |
| fs | File system operations |
| jsonlite | JSON parsing |
| glue | String interpolation |
| httr2 | HTTP requests |

### Econometrics & Causal Inference
| Package | Description |
|---------|-------------|
| fixest | Fast fixed effects estimation |
| did | Difference-in-differences |
| lfe | Linear fixed effects (older, widely used) |
| estimatr | Robust standard errors |
| sandwich | Heteroskedasticity-consistent covariance |
| clubSandwich | Cluster-robust variance estimation |
| plm | Panel data models |
| AER | Applied econometrics |
| ivreg | Instrumental variables regression |
| rdrobust | Regression discontinuity |
| DRDID | Doubly robust DiD |
| synthdid | Synthetic difference-in-differences |
| gsynth | Generalized synthetic control |
| Synth | Synthetic control method |

### Statistical Modeling
| Package | Description |
|---------|-------------|
| lme4 | Mixed effects models |
| survival | Survival analysis |
| caret | Machine learning framework |
| randomForest | Random forest models |
| MASS | Modern Applied Statistics |
| Matrix | Sparse matrix operations |
| broom | Tidy model outputs |
| car | Companion to Applied Regression |

### Tables & Reporting
| Package | Description |
|---------|-------------|
| modelsummary | Publication-ready tables |
| stargazer | LaTeX/HTML regression tables |
| kableExtra | Enhanced tables for knitr |
| knitr | Dynamic report generation |
| rmarkdown | R Markdown documents |
| tinytex | Lightweight LaTeX distribution |

### Visualization
| Package | Description |
|---------|-------------|
| patchwork | Combine multiple ggplots |
| cowplot | Plot arrangements and annotations |
| ggrepel | Non-overlapping text labels |
| ggthemes | Additional ggplot themes |
| viridis | Color palettes |
| scales | Scale functions for visualization |
| gridExtra | Grid graphics utilities |

### Spatial Data
| Package | Description |
|---------|-------------|
| sf | Simple features for spatial data |
| terra | Raster and vector spatial data |

### Parallel Computing & Utilities
| Package | Description |
|---------|-------------|
| parallel | Built-in parallel processing |
| foreach | Looping construct for parallelization |
| doParallel | Parallel backend for foreach |
| future | Unified parallelization framework |
| devtools | Package development tools |
| Rcpp | R and C++ integration |

### Python Packages

The following Python packages are also pre-installed:

| Package | Description |
|---------|-------------|
| pandas | Data manipulation |
| numpy | Numerical computing |
| matplotlib | Plotting |
| seaborn | Statistical visualization |
| scipy | Scientific computing |
| statsmodels | Statistical models |
| scikit-learn | Machine learning |
| jupyter | Interactive notebooks |
| requests | HTTP library |

### Adding More Packages

Claude can install additional packages at runtime:

```r
# In R
install.packages("new_package")
```

```python
# In Python
pip install new_package
```

**Note:** Runtime installations disappear when the container stops. To make packages permanent, you would need to edit the Dockerfile and rebuild the image.
