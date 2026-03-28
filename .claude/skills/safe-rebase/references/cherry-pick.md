# Cherry-Pick as Rebase Alternative

## When to Use Cherry-Pick Instead of Rebase

Use cherry-pick when:
- You only need specific commits (not the whole branch)
- Rebase has too many conflicts
- You want more control over which commits to apply
- The branch history is complex or has merge commits

---

## Cherry-Pick Workflow

### Workflow Checklist

```
Cherry-Pick Progress:
- [ ] Step 1: Commit all uncommitted changes
- [ ] Step 2: Create backup branch
- [ ] Step 3: Identify commits to cherry-pick
- [ ] Step 4: Create new branch from target
- [ ] Step 5: Cherry-pick commits one by one
- [ ] Step 6: Resolve conflicts (if any)
- [ ] Step 7: Verify work is preserved
- [ ] Step 8: Push and create PR
```

### Step 1: Commit All Changes

```bash
git add -A
git commit -m "WIP: checkpoint before cherry-pick"
```

### Step 2: Create Backup

```bash
git branch backup-$(date +%Y%m%d-%H%M%S)
```

### Step 3: Identify Commits

```bash
# List commits on your branch not in main
git log origin/main..HEAD --oneline

# Output example:
# a1b2c3d feat: add user dashboard
# e4f5g6h fix: resolve login issue
# i7j8k9l refactor: clean up auth module

# Note the hashes you want to cherry-pick
```

### Step 4: Create New Branch from Target

```bash
# Start fresh from latest main
git fetch origin
git checkout -b my-feature-rebased origin/main
```

### Step 5: Cherry-Pick Commits

```bash
# Cherry-pick in chronological order (oldest first)
git cherry-pick i7j8k9l  # First commit
git cherry-pick e4f5g6h  # Second commit
git cherry-pick a1b2c3d  # Third commit

# Or cherry-pick a range
git cherry-pick i7j8k9l^..a1b2c3d
```

### Step 6: Handle Conflicts

If conflicts occur during cherry-pick:

```bash
# See status
git status

# Resolve conflicts in each file
# (edit files, remove conflict markers)

# Stage resolved files
git add <resolved-file>

# Continue cherry-pick
git cherry-pick --continue

# Or abort if needed
git cherry-pick --abort
```

### Step 7: Verify

```bash
# Compare with original branch
git diff backup-<timestamp>..HEAD

# Ensure all expected commits are present
git log --oneline -10
```

### Step 8: Push and PR

```bash
# Push new branch
git push -u origin my-feature-rebased

# Create PR
gh pr create --title "My Feature" --body "Rebased via cherry-pick"
```

---

## Cherry-Pick Options

### Skip Commit (keep changes uncommitted)

```bash
git cherry-pick --no-commit <hash>
# Changes are staged but not committed
# Useful for combining multiple commits
```

### Preserve Original Author

```bash
git cherry-pick -x <hash>
# Adds "(cherry picked from commit ...)" to message
```

### Edit Commit Message

```bash
git cherry-pick -e <hash>
# Opens editor to modify commit message
```

---

## Common Scenarios

### Scenario: Cherry-pick only specific commits

```bash
# Only want commits a1b2c3d and e4f5g6h, skip i7j8k9l
git cherry-pick e4f5g6h
git cherry-pick a1b2c3d
```

### Scenario: Squash multiple commits into one

```bash
# Cherry-pick without committing
git cherry-pick --no-commit <hash1>
git cherry-pick --no-commit <hash2>
git cherry-pick --no-commit <hash3>

# Create single commit
git commit -m "feat: combined feature implementation"
```

### Scenario: Cherry-pick from another branch

```bash
# Get commit hash from other branch
git log other-branch --oneline -5

# Cherry-pick to current branch
git cherry-pick <hash-from-other-branch>
```

---

## Cherry-Pick vs Rebase Comparison

| Aspect | Rebase | Cherry-Pick |
|--------|--------|-------------|
| Scope | Entire branch | Specific commits |
| Control | Less granular | Full control |
| Conflicts | All at once | One commit at a time |
| History | Cleaner linear | Same result, more manual |
| Use case | Standard update | Complex scenarios |

---

## Troubleshooting

### "Commit already exists"

If the commit was already merged:
```bash
# Skip the duplicate commit
git cherry-pick --skip
```

### "Empty commit"

If changes already exist in target:
```bash
# Allow empty commit (for tracking)
git cherry-pick --allow-empty <hash>

# Or skip
git cherry-pick --skip
```

### "Cannot cherry-pick merge commit"

For merge commits, specify parent:
```bash
# -m 1 means keep changes from first parent
git cherry-pick -m 1 <merge-commit-hash>
```

Or consider rebasing the original branch's non-merge commits instead.
