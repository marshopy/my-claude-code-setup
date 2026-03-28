# Merge Conflict Resolution

## Understanding Conflict Markers

When Git cannot auto-merge, it adds conflict markers:

```
<<<<<<< HEAD
Your changes (current branch being rebased)
=======
Their changes (from the branch you're rebasing onto)
>>>>>>> commit-hash
```

## Conflict Resolution Workflow

### Step 1: Identify Conflicted Files

```bash
git status
# Shows: "both modified: filename.ts"
```

### Step 2: Understand Both Versions

Before editing, understand what each side represents:

```bash
# See your version (what you changed)
git show HEAD:<path-to-file>

# See their version (what's in target branch)
git show REBASE_HEAD:<path-to-file>
```

### Step 3: Resolve Each Conflict

Open the file and find conflict markers. For each conflict:

1. **Read both versions** - Understand what each change does
2. **Decide the resolution:**
   - Keep your changes only
   - Keep their changes only
   - Combine both changes
   - Write a completely new version

3. **Remove conflict markers** - Delete the `<<<<<<<`, `=======`, and `>>>>>>>` lines
4. **Verify the result** - Ensure the code is syntactically valid

### Step 4: Stage and Continue

```bash
# Stage resolved file
git add <resolved-file>

# Continue rebase (repeat for each commit)
git rebase --continue
```

---

## Common Resolution Patterns

### Pattern: Keep Your Changes

When your version is correct and should replace theirs:

```bash
# Accept your version for a specific file
git checkout --ours <file>
git add <file>
```

### Pattern: Keep Their Changes

When their version is correct:

```bash
# Accept their version for a specific file
git checkout --theirs <file>
git add <file>
```

### Pattern: Combine Both Changes

Most common case - both sides have valid changes:

**Before:**
```typescript
<<<<<<< HEAD
import { FeatureA } from './feature-a';
=======
import { FeatureB } from './feature-b';
>>>>>>> origin/main
```

**After:**
```typescript
import { FeatureA } from './feature-a';
import { FeatureB } from './feature-b';
```

### Pattern: Rewrite Section

When neither version is complete:

**Before:**
```typescript
<<<<<<< HEAD
const config = { timeout: 5000 };
=======
const config = { retries: 3 };
>>>>>>> origin/main
```

**After:**
```typescript
const config = { timeout: 5000, retries: 3 };
```

---

## Tool-Assisted Resolution

### Using VS Code

1. Open conflicted file
2. Click "Accept Current/Incoming/Both Changes" above each conflict
3. Or use Command Palette: "Merge Conflict: Accept..."

### Using git mergetool

```bash
# Configure a merge tool (one-time)
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait $MERGED'

# Launch merge tool
git mergetool
```

---

## Complex Conflict Scenarios

### Scenario: File Renamed on Both Sides

```bash
# Check rename detection
git status
# Shows: "renamed: old-name.ts -> new-name.ts"

# May need to manually specify the correct name
git add <correct-name>
git rm <wrong-name>
```

### Scenario: File Deleted on One Side

```bash
# If you want to keep the file
git add <file>

# If you want to delete the file
git rm <file>
```

### Scenario: Many Conflicts in One File

Consider aborting and splitting your changes:

```bash
# Abort current rebase
git rebase --abort

# Create smaller commits that are easier to rebase
# Then rebase again
```

---

## Validation After Resolution

Always verify after resolving conflicts:

```bash
# Check syntax (for TypeScript)
pnpm nx typecheck <project>

# Run tests
pnpm nx test <project>

# Compare with backup to ensure nothing lost
git diff backup-<timestamp>..HEAD
```

---

## When to Abort

Abort the rebase if:
- Conflicts are too complex to understand
- You're unsure which version is correct
- Too many files have conflicts
- You need to discuss with teammates

```bash
git rebase --abort
# Branch returns to pre-rebase state
```

Your backup branch remains available for reference or recovery.
