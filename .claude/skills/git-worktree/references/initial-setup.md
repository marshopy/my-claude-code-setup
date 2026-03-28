# wtp Initial Setup

Complete guide for installing wtp and configuring shell integration.

---

## Installation

### Homebrew (Recommended)

```bash
brew install satococoa/tap/wtp
```

### Verify Installation

```bash
wtp --version
# Should output: wtp version X.X.X
```

---

## Shell Integration

Shell integration enables two features:
1. **`wtp cd`** - Navigate between worktrees
2. **Tab completion** - Autocomplete worktree names

### Zsh (Default on macOS)

Add to `~/.zshrc`:

```bash
eval "$(wtp shell-init zsh)"
```

Then reload:
```bash
source ~/.zshrc
```

### Bash

Add to `~/.bashrc`:

```bash
eval "$(wtp shell-init bash)"
```

Then reload:
```bash
source ~/.bashrc
```

### Fish

Add to `~/.config/fish/config.fish`:

```fish
wtp shell-init fish | source
```

Then reload:
```bash
source ~/.config/fish/config.fish
```

---

## Verify Setup

### Test Navigation

```bash
# Create a test worktree
wtp add -b test-setup

# Navigate to it
wtp cd test-setup

# Check you're in the right place
pwd
# Should show: /path/to/project-worktrees/test-setup

# Return to main
wtp cd @

# Clean up
wtp remove --with-branch test-setup
```

### Test Tab Completion

```bash
wtp cd <TAB>
# Should show available worktrees
```

---

## Troubleshooting Installation

### "command not found: wtp"

Homebrew bin not in PATH. Add to shell config:
```bash
export PATH="/opt/homebrew/bin:$PATH"
```

### "wtp cd" does nothing

Shell integration not loaded. Check:
1. `eval "$(wtp shell-init zsh)"` is in `~/.zshrc`
2. You reloaded the shell: `source ~/.zshrc`
3. Open a new terminal window

### Tab completion not working

Try regenerating completions:
```bash
# Remove old completions
rm -f ~/.zsh/completions/_wtp

# Reload shell
exec zsh
```

---

## Team Onboarding Checklist

- [ ] Install wtp: `brew install satococoa/tap/wtp`
- [ ] Add shell integration to config file
- [ ] Reload shell or open new terminal
- [ ] Test with `wtp add -b test && wtp cd test && wtp remove --with-branch test`
