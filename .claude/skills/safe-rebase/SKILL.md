---
name: safe-rebase
description: Safe git rebase and conflict resolution workflow. Use when rebasing branches onto main/other branches, resolving merge conflicts, or updating feature branches. CRITICAL - preserves uncommitted work, commits before rebasing, and uses proper git operations (no reimplementation).
---

# Safe Git Rebase Workflow

## Overview

This skill provides a **safe** rebase workflow that prevents data loss. It addresses common pitfalls where uncommitted work is lost through improper stash handling or where developers "reimplement" changes instead of properly rebasing.

## When to Use This Skill

- Rebasing a feature branch onto main
- Updating a branch after main has new commits
- Resolving merge conflicts during rebase
- Recovering from a failed rebase
- Creating PRs after rebasing

## Critical Rules

**NEVER do these:**
- `git stash` followed by `git stash drop` (loses uncommitted work)
- Reimplementing changes instead of rebasing
- Force pushing without verification
- Rebasing shared/main branches

**ALWAYS do these:**
- Commit tracked changes BEFORE rebasing (`git add -u`, never `git add -A`)
- Create a backup branch before risky operations
- Use `git rebase --abort` if conflicts are too complex
- Verify work is preserved after rebase

---

## Quick Reference

| Task | Command |
|------|---------|
| Check status | `git status` |
| Commit tracked changes | `git add -u && git commit -m "WIP: checkpoint before rebase"` |
| Create backup branch | `git branch backup-$(date +%Y%m%d-%H%M%S)` |
| Fetch latest | `git fetch origin` |
| Rebase onto main | `git rebase origin/main` |
| Continue after fix | `git rebase --continue` |
| Abort rebase | `git rebase --abort` |
| Push rebased branch | `git push --force-with-lease` |

---

## Workflow Checklist

Copy this checklist and track progress:

```
Safe Rebase Progress:
- [ ] Step 1: Verify current state (git status, git log)
- [ ] Step 2: Commit tracked changes (git add -u, not -A)
- [ ] Step 3: Create backup branch
- [ ] Step 4: Fetch latest from remote
- [ ] Step 5: Perform rebase
- [ ] Step 6: Resolve conflicts (if any)
- [ ] Step 7: Verify work is preserved
- [ ] Step 8: Push to remote
- [ ] Step 9: Create/update PR
```

---

## Detailed Workflow

### Step 1: Verify Current State

```bash
# Check for uncommitted changes
git status

# View recent commits on this branch
git log --oneline -10

# View what branch you're on
git branch --show-current
```

**STOP if:** You see uncommitted changes. Go to Step 2 first.

### Step 2: Commit Tracked Changes

**This is the most critical step.** Never rebase with uncommitted changes.

```bash
# Stage only tracked files (modified + deleted) — NOT untracked files
git add -u

# Create a checkpoint commit (can amend message later)
git commit -m "WIP: checkpoint before rebase"
```

**Why `git add -u` instead of `git add -A`?**
- `git add -A` stages untracked files, which may include generated files, local experiments, or files not meant to be committed
- `git add -u` only stages changes to files already tracked by git
- Untracked files are safe during rebase — they stay in the working directory untouched
- A commit creates a recoverable point in history
- You can squash or amend it later

### Step 3: Create Backup Branch

Before any potentially destructive operation, create a backup:

```bash
# Create timestamped backup branch
git branch backup-$(date +%Y%m%d-%H%M%S)

# Verify backup exists
git branch | grep backup
```

### Step 4: Fetch Latest from Remote

```bash
git fetch origin
```

### Step 5: Perform Rebase

```bash
# Rebase onto origin/main
git rebase origin/main
```

**If no conflicts:** Skip to Step 7.

**If conflicts:** Continue to Step 6.

### Step 6: Resolve Conflicts

See [references/conflict-resolution.md](./references/conflict-resolution.md) for detailed conflict resolution.

**Quick conflict resolution:**

```bash
# See which files have conflicts
git status

# For each conflicted file:
# 1. Open the file
# 2. Look for conflict markers (<<<<<<<, =======, >>>>>>>)
# 3. Edit to resolve (keep both changes merged properly)
# 4. Stage the resolved file
git add <resolved-file>

# Continue rebase
git rebase --continue
```

**If conflicts are too complex:**

```bash
# Abort and return to pre-rebase state
git rebase --abort

# Your backup branch is still safe
```

### Step 7: Verify Work is Preserved

**Critical verification step:**

```bash
# Compare against backup to ensure no work was lost
git diff backup-<timestamp>..HEAD

# If diff shows missing changes, something went wrong
# Recover from backup branch
```

### Step 8: Push to Remote

```bash
# Use --force-with-lease (safer than --force)
# Fails if remote has new commits you haven't seen
git push --force-with-lease
```

**Never use `git push --force` on shared branches.**

### Step 9: Create/Update PR

```bash
# If PR doesn't exist, create it
gh pr create --title "Your PR Title" --body "$(cat <<'EOF'
## Summary
- Brief description of changes

## Test plan
- How to verify the changes
EOF
)"

# If PR exists, it auto-updates after push
gh pr view --web
```

---

## Detailed Guides

| Task | Guide |
|------|-------|
| Resolve merge conflicts | [references/conflict-resolution.md](./references/conflict-resolution.md) |
| Recover from failed rebase | [references/recovery.md](./references/recovery.md) |
| Cherry-pick alternative | [references/cherry-pick.md](./references/cherry-pick.md) |

---

## Common Scenarios

### Scenario: Rebase with uncommitted changes

**Wrong approach:**
```bash
git stash                    # Stashes changes
git rebase origin/main       # Rebase
git stash pop                # May fail with conflicts
git stash drop               # DANGER: May lose work if pop failed!
```

**Correct approach:**
```bash
git add -u
git commit -m "WIP: checkpoint before rebase"
git branch backup-$(date +%Y%m%d-%H%M%S)
git rebase origin/main
# Resolve conflicts if any
git push --force-with-lease
```

### Scenario: Rebase failed halfway through

```bash
# Check current state
git status

# If in middle of rebase:
git rebase --abort

# Return to your backup branch if needed
git checkout backup-<timestamp>
```

### Scenario: Update PR branch that's behind main

```bash
# Commit any tracked changes first (not untracked files)
git add -u && git commit -m "WIP: checkpoint"

# Create backup
git branch backup-$(date +%Y%m%d-%H%M%S)

# Fetch and rebase
git fetch origin
git rebase origin/main

# Push updated branch
git push --force-with-lease
```

---

## Troubleshooting

### "You have unstaged changes"

Always commit tracked changes before rebasing:
```bash
git add -u
git commit -m "WIP: checkpoint before rebase"
```

### "Conflict in file X"

See [references/conflict-resolution.md](./references/conflict-resolution.md).

### "Failed to push: remote has work you don't have"

Someone pushed to the remote. Fetch and handle:
```bash
git fetch origin
# Either integrate their changes or coordinate with them
```

### "Lost my changes after rebase"

If you created a backup branch:
```bash
# List backup branches
git branch | grep backup

# Checkout your backup
git checkout backup-<timestamp>

# Create new branch from backup
git checkout -b my-feature-recovered
```
