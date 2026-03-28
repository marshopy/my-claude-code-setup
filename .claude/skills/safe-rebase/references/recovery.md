# Recovery from Failed Rebase

## Quick Recovery Options

| Situation | Recovery Command |
|-----------|-----------------|
| Rebase in progress | `git rebase --abort` |
| Rebase completed but wrong | `git reset --hard ORIG_HEAD` |
| Have backup branch | `git checkout backup-<timestamp>` |
| No backup, need reflog | `git reflog` + `git reset --hard <hash>` |

---

## Recovery Scenarios

### Scenario 1: Abort In-Progress Rebase

If you're in the middle of a rebase and want to cancel:

```bash
# Check if rebase is in progress
ls .git/rebase-merge 2>/dev/null && echo "Rebase in progress"

# Abort and return to original state
git rebase --abort

# Verify you're back to normal
git status
```

### Scenario 2: Undo Completed Rebase

If rebase finished but you want to undo it:

```bash
# Git stores the pre-rebase HEAD in ORIG_HEAD
git reset --hard ORIG_HEAD

# Verify restoration
git log --oneline -5
```

**Note:** `ORIG_HEAD` is only valid immediately after rebase. Use backup branch for later recovery.

### Scenario 3: Recover from Backup Branch

If you followed the workflow and created a backup:

```bash
# List backup branches
git branch | grep backup

# Compare current state with backup
git diff backup-<timestamp>..HEAD

# If backup is better, restore from it:
git checkout backup-<timestamp>
git checkout -b my-feature-recovered
```

### Scenario 4: Recover Using Reflog

Git's reflog tracks all HEAD movements. Use it when no backup exists:

```bash
# View reflog (shows recent HEAD positions)
git reflog -20

# Output looks like:
# a1b2c3d HEAD@{0}: rebase (finish): returning to refs/heads/my-branch
# e4f5g6h HEAD@{1}: rebase (continue): my commit message
# i7j8k9l HEAD@{2}: rebase (start): checkout origin/main
# m1n2o3p HEAD@{3}: commit: my original commit  <-- THIS ONE

# Reset to the pre-rebase state
git reset --hard HEAD@{3}
```

---

## Finding Lost Commits

### Using git reflog

```bash
# Search for specific commit message
git reflog | grep "your commit message"

# See full commit details
git show <hash>
```

### Using git fsck

For truly lost commits (not in reflog):

```bash
# Find dangling commits
git fsck --lost-found

# Examine each found commit
git show <dangling-commit-hash>
```

---

## Partial Recovery

### Recover Specific Files from a Commit

```bash
# Get file from specific commit
git checkout <commit-hash> -- path/to/file

# Or from backup branch
git checkout backup-<timestamp> -- path/to/file
```

### Cherry-Pick Lost Commits

If you can find the lost commit hash:

```bash
# Apply the commit to current branch
git cherry-pick <commit-hash>
```

---

## Prevention Checklist

To avoid needing recovery:

1. **Always commit before rebase**
   ```bash
   git add -A && git commit -m "WIP: checkpoint"
   ```

2. **Always create backup branch**
   ```bash
   git branch backup-$(date +%Y%m%d-%H%M%S)
   ```

3. **Never stash + drop**
   ```bash
   # WRONG - can lose work
   git stash && git rebase && git stash pop && git stash drop

   # RIGHT - commit instead
   git commit -m "WIP" && git rebase
   ```

4. **Use --force-with-lease not --force**
   ```bash
   git push --force-with-lease  # Safer
   ```

---

## When Recovery Fails

If none of the above works:

1. Check if commits exist in remote:
   ```bash
   git fetch origin
   git log origin/my-branch --oneline
   ```

2. Ask teammates if they have the commits

3. Check IDE local history (VS Code, IntelliJ track changes)

4. Last resort: re-implement from memory/documentation
