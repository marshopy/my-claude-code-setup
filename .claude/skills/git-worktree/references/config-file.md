# .wtp.yml Configuration

Complete guide for customizing the wtp configuration file.

---

## File Location

The config file is at the repository root: `.wtp.yml`

This file is committed to git so the whole team shares the same setup.

---

## Config Structure

```yaml
version: "1.0"

defaults:
  base_dir: "../project-worktrees"

hooks:
  post_create:
    - type: copy
      from: "..."
      to: "..."
    - type: command
      command: "..."
```

---

## Defaults Section

### base_dir

Where worktrees are created, relative to repo root.

```yaml
defaults:
  base_dir: "../project-worktrees"
```

For branch `feature/auth`, creates:
`../project-worktrees/feature/auth`

---

## Hooks Section

### post_create

Runs after worktree is created. Supports two hook types:

---

## Copy Hook

Copies files or directories from main worktree to new worktree.

### Single File

```yaml
- type: copy
  from: ".env"
  to: ".env"
```

### Directory

```yaml
- type: copy
  from: ".claude/"
  to: ".claude/"
```

### Notes

- `from` resolves relative to **main worktree**
- `to` resolves relative to **new worktree**
- Missing source files are silently skipped
- Directories are copied recursively

---

## Command Hook

Runs shell commands in the new worktree.

### Basic Command

```yaml
- type: command
  command: "pnpm install"
```

### With Environment Variables

```yaml
- type: command
  command: "npm install"
  env:
    NODE_ENV: "development"
```

### Multi-line Command

```yaml
- type: command
  command: |
    echo "Starting setup..."
    pnpm install
    echo "Done!"
```

### Notes

- Commands run in the new worktree directory
- Use `|` for multi-line scripts
- Exit code 0 = success, non-zero = failure (stops remaining hooks)

---

## Example Config

```yaml
version: "1.0"
defaults:
  base_dir: "../project-worktrees"

hooks:
  post_create:
    # Copy all .env files (wtp doesn't support wildcards, so use shell)
    - type: command
      command: |
        MAIN_WT="$(git worktree list | head -1 | awk '{print $1}')"
        NEW_WT="$(pwd)"
        cd "$MAIN_WT" && find . -name '.env*' -type f 2>/dev/null | while read f; do
          mkdir -p "$NEW_WT/$(dirname "$f")"
          cp "$f" "$NEW_WT/$f" 2>/dev/null || true
        done

    # Copy Claude Code config
    - type: copy
      from: ".claude/"
      to: ".claude/"

    # Language version setup (customize to your runtime)
    - type: command
      command: "source ~/.nvm/nvm.sh && nvm use"  # Node.js; replace with rbenv/pyenv as needed

    # Install dependencies (customize to your package manager)
    - type: command
      command: "npm install"  # or: pnpm install, yarn install, bundle install

    # Project-specific setup (optional)
    # - type: command
    #   command: "uv sync"  # Python dependencies
    # - type: command
    #   command: "make setup"  # Or any other setup step
```

---

## Adding New Hooks

### Copy a New Config File

```yaml
hooks:
  post_create:
    # ... existing hooks ...

    - type: copy
      from: ".my-config"
      to: ".my-config"
```

### Add a Setup Command

```yaml
hooks:
  post_create:
    # ... existing hooks ...

    - type: command
      command: "my-setup-script.sh"
```

### Copy Multiple Files with Shell

Since wtp doesn't support wildcards, use a command hook:

```yaml
- type: command
  command: |
    MAIN_WT="$(git worktree list | head -1 | awk '{print $1}')"
    NEW_WT="$(pwd)"
    # Copy all .config files
    cd "$MAIN_WT" && find . -name '*.config' -type f | while read f; do
      mkdir -p "$NEW_WT/$(dirname "$f")"
      cp "$f" "$NEW_WT/$f" 2>/dev/null || true
    done
```

---

## Best Practices

1. **Order matters** - Hooks run sequentially, put dependencies first
2. **Fail gracefully** - Use `|| true` for non-critical commands
3. **Keep it fast** - Long-running hooks slow down worktree creation
4. **Test changes** - Create a test worktree after modifying config
5. **Commit the config** - Don't gitignore `.wtp.yml`
