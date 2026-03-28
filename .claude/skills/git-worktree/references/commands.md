# wtp Commands Reference

Complete reference for all wtp (Worktree Plus) commands.

---

## wtp add

Creates a new worktree. Runs post-create hooks from `.wtp.yml`.

### Syntax

```bash
wtp add <branch-name>                    # Checkout existing branch
wtp add -b <new-branch>                  # Create new branch from HEAD
wtp add -b <new-branch> <start-point>    # Create from specific commit/branch
wtp add -b <new-branch> origin/main      # Create tracking remote branch
```

### Options

| Option | Description |
|--------|-------------|
| `-b <name>` | Create a new branch instead of checking out existing |

### Examples

```bash
# Work on an existing feature branch
wtp add feature/auth-improvements

# Start a new feature from main
wtp add -b feature/new-dashboard origin/main

# Start from a specific commit
wtp add -b hotfix/urgent-fix abc123
```

### Worktree Location

Worktrees are created at: `../project-worktrees/<branch-name>`

For branch `feature/my-feature`, the path is:
`../project-worktrees/feature/my-feature`

---

## wtp remove

Deletes a worktree and optionally its branch.

### Syntax

```bash
wtp remove <worktree-name>
wtp remove --force <worktree-name>
wtp remove --with-branch <worktree-name>
wtp remove --with-branch --force-branch <worktree-name>
```

### Options

| Option | Description |
|--------|-------------|
| `--force` | Remove even with uncommitted changes |
| `--with-branch` | Also delete the branch (only if merged) |
| `--force-branch` | Force delete branch regardless of merge status |

### Examples

```bash
# Remove worktree, keep branch
wtp remove feature/old-work

# Remove worktree and merged branch
wtp remove --with-branch feature/completed

# Force remove everything (careful!)
wtp remove --with-branch --force-branch feature/abandoned
```

---

## wtp list

Shows all worktrees with their branches and commit info.

### Syntax

```bash
wtp list
```

### Output Example

```
main                 abc1234 [/Users/you/Dev/your-project]
feature/auth         def5678 [/Users/you/Dev/project-worktrees/feature/auth]
feature/dashboard    ghi9012 [/Users/you/Dev/project-worktrees/feature/dashboard]
```

---

## wtp cd

Navigate to a worktree. Requires shell integration.

### Syntax

```bash
wtp cd <worktree-name>    # Go to specific worktree
wtp cd @                  # Return to main worktree
wtp cd                    # Also returns to main worktree
```

### Examples

```bash
# Jump to feature branch worktree
wtp cd feature/auth

# Return to main
wtp cd @
```

### Tab Completion

With shell integration, press Tab to autocomplete worktree names:
```bash
wtp cd feat<TAB>
# Completes to: wtp cd feature/auth
```

---

## wtp shell-init

Initialize shell integration for navigation and completion.

### Syntax

```bash
wtp shell-init <shell>
```

### Supported Shells

- `bash`
- `zsh`
- `fish`

### Usage

Add to your shell config file:

```bash
# ~/.zshrc
eval "$(wtp shell-init zsh)"

# ~/.bashrc
eval "$(wtp shell-init bash)"

# ~/.config/fish/config.fish
wtp shell-init fish | source
```

---

## wtp hook

Enable shell navigation hook without completions.

### Syntax

```bash
wtp hook <shell>
```

Use this if you only want the `wtp cd` navigation without tab completion.

---

## wtp completion

Generate shell completion script.

### Syntax

```bash
wtp completion <shell>
```

Alternative to `shell-init` if you only want completions without navigation.
