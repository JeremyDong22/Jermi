# Jermi - Development Guide for Claude

## Project Overview

Jermi is a fork of [Yazi](https://github.com/sxyazi/yazi) terminal file manager with **anchor-based navigation** and **dynamic panes**.

## Key Concepts

### Anchor System
- `anchor`: The startup directory, acts as fixed left boundary
- `pane_urls`: Vec of URLs tracking navigation path from anchor to current
- When at anchor: 2 panes (current + preview)
- When navigated away: N panes (anchor...parents...current + preview)

### Navigation Behavior
- `Enter` into directory: pushes URL to `pane_urls`, adds pane
- `Leave` (h/Left): pops from `pane_urls`, removes pane
- `Leave` at anchor: blocked (can't go above project root)
- `Shift+Left`: expand anchor to parent
- `Shift+Right`: shrink anchor to current directory
- `cd`/`reveal`: resets `pane_urls` (jumps break the chain)

## Architecture

### Rust Core (`yazi-core/src/tab/`)
- `tab.rs`: Tab struct with `anchor: Option<Url>` and `pane_urls: Vec<Url>`
- `commands/cd.rs`: Navigation logic, updates `pane_urls` based on `OptSource`
- `commands/leave.rs`: Blocks at anchor
- `commands/anchor.rs`: Shift+Arrow anchor movement
- `commands/enter.rs`: Pushes to `pane_urls`

### Lua UI (`yazi-plugin/preset/components/`)
- `tab.lua`: Layout logic, creates panes based on `pane_urls` count
- `pane.lua`: Renders earlier panes from history
- `current.lua`: Active folder with full features
- `parent.lua`: Parent folder pane
- `rail.lua`: Border lines between panes

### Executor (`yazi-fm/src/executor.rs`)
- Command dispatcher - new commands must be registered here
- Pattern: `on!(ACTIVE, command_name)` for tab commands

## Common Modifications

### Adding a New Tab Command
1. Create `yazi-core/src/tab/commands/newcmd.rs`
2. Add to `yazi-core/src/tab/commands/mod.rs`
3. Register in `yazi-fm/src/executor.rs`: `on!(ACTIVE, newcmd);`
4. Add keybinding in `yazi-config/preset/keymap-default.toml`

### Modifying Pane Layout
Edit `yazi-plugin/preset/components/tab.lua`:
- `Tab:layout()`: constraint calculations
- `Tab:build()`: component instantiation

### Folder Loading
- `history.remove_or(&url)`: get or create folder in history
- `MgrProxy::refresh()`: trigger async folder loading
- Folders in `pane_urls` need to be loaded in `refresh.rs`

## Build & Test

```bash
# Build
cargo build --release

# Install as 'jermi'
./install.sh

# Run
jermi
# or
./target/release/yazi
```

## Important Files

| File | Purpose |
|------|---------|
| `yazi-core/src/tab/tab.rs` | Tab struct with anchor/pane_urls |
| `yazi-core/src/tab/commands/cd.rs` | Navigation, pane_urls updates |
| `yazi-core/src/tab/commands/anchor.rs` | Shift+Arrow anchor control |
| `yazi-core/src/mgr/commands/refresh.rs` | Folder loading (includes pane_urls) |
| `yazi-fm/src/executor.rs` | Command dispatch |
| `yazi-plugin/preset/components/tab.lua` | Pane layout logic |
| `yazi-plugin/preset/components/pane.lua` | Earlier pane rendering |
| `yazi-config/preset/keymap-default.toml` | Default keybindings |

## Gotchas

1. **Command not working?** Check if registered in `executor.rs`
2. **Pane blank?** Folder not loaded - ensure `refresh.rs` triggers for `pane_urls`
3. **Padding inconsistent?** All panes should use `pad(ui.Pad.x(1))`
4. **Mouse click resets panes?** Avoid `reveal` command, use `cd` for directories
