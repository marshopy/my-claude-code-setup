---
name: git-worktree
description: Manage git worktrees with wtp (Worktree Plus) for working on multiple branches simultaneously. Use when creating worktrees, navigating between them, customizing the .wtp.yml config, or troubleshooting worktree issues. Covers wtp commands, shell integration, and configuration.
---

# Git Worktree Management with wtp

## Overview

This skill covers using [wtp](https://github.com/satococoa/wtp) (Worktree Plus) for managing git worktrees. wtp automates worktree creation with post-create hooks that copy files and run setup commands.

## When to Use This Skill

- Creating a new worktree to work on a feature branch
- Navigating between multiple worktrees
- Customizing the `.wtp.yml` configuration
- Adding new post-create hooks (copy files, run commands)
- Troubleshooting worktree or wtp issues

---

## Quick Reference

| Task | Command |
|------|---------|
| Create worktree (existing branch) | `wtp add <branch>` |
| Create worktree (new branch) | `wtp add -b <new-branch>` |
| Create from remote | `wtp add -b <branch> origin/main` |
| List worktrees | `wtp list` |
| Navigate to worktree | `wtp cd <branch>` |
| Return to main worktree | `wtp cd @` or `wtp cd` |
| Remove worktree | `wtp remove <branch>` |
| Remove with branch | `wtp remove --with-branch <branch>` |

---

## What Happens on `wtp add`

The `.wtp.yml` config runs hooks automatically. Typical hooks:

1. **Copy `.env*` files** - All `.env` files from main worktree
2. **Copy `.claude/` folder** - Settings, skills, agents
3. **Run version manager setup** - e.g., `nvm use`
4. **Install dependencies** - e.g., `npm install` / `pnpm install`
5. **Run project-specific setup** - e.g., `uv sync`, Docker build

Customize hooks in `.wtp.yml` to match your project's setup steps.

---

## Detailed Guides

| Task | Guide |
|------|-------|
| Install wtp and shell integration | [references/initial-setup.md](./references/initial-setup.md) |
| All wtp commands and options | [references/commands.md](./references/commands.md) |
| Customize .wtp.yml config | [references/config-file.md](./references/config-file.md) |

---

## File Locations

| Purpose | Location |
|---------|----------|
| wtp config | `.wtp.yml` (repo root) |
| Worktrees directory | `../project-worktrees/` (configurable in `.wtp.yml`) |

---

## Troubleshooting

### "branch not found"

Use `-b` flag to create a new branch:
```bash
wtp add -b my-new-branch
```

### Hooks failing

Check the hook output - wtp shows which hook failed. Common issues:
- Missing `.env` file in main worktree (safe to ignore)
- nvm not installed or configured
- Network issues during `pnpm install`

### Worktree already exists

Remove and recreate:
```bash
wtp remove my-branch
wtp add -b my-branch
```

### Shell integration not working

Re-add to shell config:
```bash
# For zsh
echo 'eval "$(wtp shell-init zsh)"' >> ~/.zshrc
source ~/.zshrc
```
