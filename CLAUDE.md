# Jermi - Development Guide for Claude

## Project Overview

Jermi is a fork of [Yazi](https://github.com/sxyazi/yazi) terminal file manager with **anchor-based navigation** and **dynamic panes**.

## The Core Idea: Anchor

**Anchor is the headline feature of this fork. Everything else — dynamic panes, the auto-derived `pane_urls` chain, `Leave` being blocked at the root, `Shift+Arrow` controls — is downstream of it.** When in doubt about whether a change is on-brand, ask: *does this preserve the anchor as a hard left boundary that the user can see, trust, and adjust at runtime?* If not, push back.

Why it matters in one line: every other TUI file manager (ranger, lf, broot, even upstream Yazi) gives you a **sliding window** that scrolls the project root off-screen the moment you go a few levels deep. Jermi pins it. That single decision is what makes the rest of the UX work — the breadcrumb *is* the layout, project boundary is a first-class object, and you never have to glance at the title bar to remember where you are.

Don't refactor the anchor out, don't add escape hatches that quietly cross it (e.g. silently `cd`-ing above it via reveal/back), and don't treat the 2-pane vs N-pane mode switch as a layout glitch — it's the whole point.

## Key Concepts

### Anchor System
- `anchor`: The startup directory, acts as fixed left boundary
- `pane_urls`: Vec of URLs tracking navigation path from anchor to current
- **`pane_urls` is auto-derived** from `anchor` + `target` on every `cd` call (v0.4, `cd.rs`). Don't push/pop it manually — change `cwd` and the chain rebuilds itself as `[anchor, ..., target]` if target is under anchor, or `[]` otherwise.
- When at anchor: 2 panes (current + preview)
- When navigated away: N panes (anchor...parents...current + preview)

### Navigation Behavior
- `Enter` into directory → `cd(Enter)` → chain extends by 1
- `Leave` (h/Left) → `cd(Leave)` → chain shrinks by 1 (cleared if back at anchor)
- `Leave` at anchor: blocked (can't go above project root)
- `Shift+Left`: expand anchor to parent
- `Shift+Right`: shrink anchor to current directory
- `cd` / `reveal` / mouse click: chain auto-rebuilt; **stays intact** as long as target is inside anchor subtree; only cleared when jumping outside

## Architecture

### Rust Core (`yazi-core/src/tab/`)
- `tab.rs`: Tab struct with `anchor: Option<Url>` and `pane_urls: Vec<Url>`
- `commands/cd.rs`: Navigation logic; auto-derives `pane_urls` from anchor + target
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
4. **Mouse click on directory in any pane?** Always use `cd`, not `reveal`. Applies to `pane.lua`, `parent.lua`. `reveal` is for files only.
5. **Don't mutate `pane_urls` manually** — it's derived in `cd.rs`. If you're tempted to push/pop, change `cwd` instead.
6. **Preview pane empty after entering a folder?** When pane count changes (anchor → dynamic, etc.), `LAYOUT.preview` gets a new rect during Lua redraw, but any peek that ran *before* the redraw captured the old rect into `lock.area`. `mgr::Preview::render` then skips drawing on the area mismatch. Fix lives in `yazi-fm/src/app/commands/render.rs`: capture `LAYOUT` before `term.draw` and re-peek with `force=true` if it changed during the frame.
7. **Build blocked by `yazi-* 2/` empty dirs?** iCloud sync artifacts from Desktop being in iCloud Drive. Clean with `rm -rf *" 2"*` (they're all untracked). Long-term: move project out of `~/Desktop/` and `~/Documents/`.
8. **`zsh: killed jermi` after fresh `cp`?** Apple Silicon AMFI kills binaries with `com.apple.provenance` xattr (set when copying from iCloud-synced paths). After each install:
   ```bash
   xattr -c ~/.local/bin/jermi && codesign --force --sign - ~/.local/bin/jermi
   ```
