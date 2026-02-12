# Jermi - Development Guide for Claude
<!-- v2 - Updated 2026-02-13: Full workspace architecture, crate dependency graph, LSP workflow -->

## Workflow Rules

### LSP-First Code Understanding
The `rust-analyzer-lsp` plugin is installed and provides automatic diagnostics for `.rs` files. **Before trying to understand code logic, always check rust-analyzer diagnostics first** — they surface type errors, lifetime issues, unused imports, and other structural problems that reveal how code fits together. The diagnostics appear automatically in system reminders when files are being edited. Use them to catch issues early and understand type relationships before deep-diving into source files.

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

### Pane URL Lifecycle
```
// At anchor (2-pane mode)
pane_urls = []

// First enter from anchor
pane_urls = [anchor, child]

// Enter deeper
pane_urls = [anchor, child, grandchild]

// Leave once
pane_urls = [anchor, child]

// Leave back to anchor
pane_urls = []  // 2-pane mode again
```

## Full Workspace Architecture

### Crate Dependency Graph

```
Foundation Layer (no internal deps):
  yazi-macro          Proc macros for module organization (mod_pub!, mod_flat!)
  yazi-codegen        Proc macros for commands (#[command]) and config (DeserializeOver1/2)
  yazi-shared         Core utilities: Event, Cmd, Url, debounce, throttle, natsort
  yazi-ffi            Foreign function interface (macOS CoreFoundation, IOKit)

Infrastructure Layer:
  yazi-term        → yazi-macro, yazi-shared
  yazi-fs          → yazi-ffi, yazi-macro, yazi-shared
  yazi-binding     → yazi-fs, yazi-macro, yazi-shared

Configuration Layer:
  yazi-config      → yazi-codegen, yazi-fs, yazi-macro, yazi-shared, yazi-term
  yazi-boot        → yazi-adapter, yazi-config, yazi-fs, yazi-macro, yazi-shared

Communication Layer:
  yazi-proxy       → yazi-config, yazi-macro, yazi-shared
  yazi-dds         → yazi-binding, yazi-boot, yazi-fs, yazi-macro, yazi-shared

Presentation Layer:
  yazi-adapter     → yazi-config, yazi-macro, yazi-shared, yazi-term
  yazi-widgets     → yazi-codegen, yazi-config, yazi-macro, yazi-plugin, yazi-proxy, yazi-shared
  yazi-plugin      → yazi-adapter, yazi-binding, yazi-boot, yazi-config, yazi-dds, yazi-fs, yazi-macro, yazi-proxy, yazi-shared, yazi-term

Execution Layer:
  yazi-scheduler   → yazi-config, yazi-dds, yazi-fs, yazi-macro, yazi-plugin, yazi-proxy, yazi-shared

Application Layer:
  yazi-core        → (all of the above)
  yazi-fm          → (all of the above) — main binary
  yazi-cli         → yazi-boot, yazi-dds, yazi-fs, yazi-macro, yazi-shared — `ya` CLI tool
```

### Crate Responsibilities

| Crate | Role |
|-------|------|
| **yazi-macro** | `mod_pub!()`, `mod_flat!()` for module organization |
| **yazi-codegen** | `#[command]` proc macro, `DeserializeOver1/2` for layered TOML config |
| **yazi-shared** | `Event`, `Cmd`, `CmdCow`, `Data`, `Url`, `Urn`, natsort, debounce, throttle, `Layer` enum |
| **yazi-ffi** | macOS: CoreFoundation, Disk Arbitration, IOKit bindings |
| **yazi-fs** | `File`, `Cha` (characteristics), `Files` collection, `Folder`, sorting, filtering, VFS |
| **yazi-binding** | Lua userdata bindings for `Cha`, `File`, `Url`, `Error` |
| **yazi-term** | TTY management, cursor control, stdin/stdout handling (macOS uses `/dev/tty`) |
| **yazi-boot** | CLI arg parsing (clap), `Boot` struct, shell completions |
| **yazi-config** | TOML config parsing: keymap, theme, opener, flavors, presets, migration |
| **yazi-adapter** | Image protocol adapters: Kitty, iTerm2, Sixel, Chafa; emulator/tmux/WSL detection |
| **yazi-widgets** | Input widget (Normal/Insert/Replace modes), built on ratatui |
| **yazi-proxy** | Decoupled command emission: `MgrProxy`, `TabProxy`, `TasksProxy` via `emit!()` |
| **yazi-dds** | Pub/Sub (LOCAL + REMOTE): Body types (Cd, Load, Hover, Rename, Yank, Move, Trash, Delete), Pump batching, multi-instance IPC |
| **yazi-scheduler** | Priority task queue (HIGH/NORMAL/LOW), micro (5) + macro (10) worker pools, progress tracking |
| **yazi-plugin** | Lua runtime (mlua), preset components, `ya`/`ui`/`fs`/`ps`/`rt`/`th` globals, plugin loader, composer (Lua→ratatui) |
| **yazi-core** | `Tab`, `Mgr`, `Tabs`, `Tasks`, `Spot`, `Pick`, `Input`, `Confirm`, `Help`, `Which`, `Cmp` — all app logic |
| **yazi-fm** | `App` event loop, `Executor` command dispatch, `Router` key routing, `Root` widget, signal handling |
| **yazi-cli** | `ya` command: external control of yazi instances via DDS |

### Key Data Structures

```rust
// yazi-core/src/tab/tab.rs
pub struct Tab {
    id: Id,
    mode: Mode,
    current: Folder,
    parent: Option<Folder>,
    history: History,
    selected: Selected,
    anchor: Option<Url>,      // Jermi: startup directory boundary
    pane_urls: Vec<Url>,      // Jermi: navigation path from anchor
    preview: Preview,
    spot: Spot,
    finder: Option<Finder>,
}

// yazi-core/src/mgr/mgr.rs
pub struct Mgr {
    tabs: Tabs,
    yanked: Yanked,
    watcher: Watcher,
    mimetype: Mimetype,
}

// yazi-fm/src/context.rs
pub struct Ctx {
    mgr: Mgr,
    tasks: Tasks,
    pick: Pick,
    input: Input,
    confirm: Confirm,
    help: Help,
    cmp: Cmp,
    which: Which,
    notify: Notify,
}

// yazi-fs/src/files.rs
pub struct Files {
    hidden: Vec<File>,
    items: Vec<File>,
    ticket: Id,
    version: u64,
    revision: u64,
    sizes: HashMap<UrnBuf, u64>,
    sorter: FilesSorter,
    filter: Option<Filter>,
}
```

### Event System

**Flow**: Input → `Event::Key` → Router (keymap lookup) → `Cmd` → Event channel (unbounded MPSC) → App event loop (batch) → Executor (dispatch) → Sets `NEED_RENDER` flag

```rust
// yazi-shared/src/event/event.rs
pub enum Event {
    Call(CmdCow),         // Single command
    Seq(Vec<CmdCow>),     // Command sequence
    Render,               // Render request
    Key(KeyEvent),        // Keyboard input
    Mouse(MouseEvent),    // Mouse input
    Resize,               // Terminal resize
    Paste(String),        // Clipboard paste
    Quit(EventQuit),      // Application exit
}
```

**Proxy pattern**: Proxies (`MgrProxy`, `TabProxy`, etc.) emit commands via `emit!()` macro, preventing circular dependencies between crates.

**DDS Pub/Sub**: LOCAL (Lua plugins) + REMOTE (cross-instance) subscriptions. Pump batches high-frequency events (500ms window) for move/trash/delete.

### Rendering Pipeline

1. Event sets `NEED_RENDER` atomic flag
2. App event loop calls `app.render()`
3. Lua `Root:redraw()` builds component tree
4. Components: `Root` → `Tabs` → `Tab` → `Pane*/Current/Preview/Rail`
5. `Composer` converts Lua tables → ratatui widgets
6. ratatui draws to terminal buffer

**Dynamic pane layout modes** (in `tab.lua`):
- At anchor (`pane_urls == []`): 2 panes — Current (1x) + Preview (1x)
- Navigated (`pane_urls.len() > 0`): N+1 panes — Pane* + Preview
- Default (no anchor): 3 panes — Parent + Current + Preview (ratio-based)

### Lua Plugin ↔ Rust Integration

**Rust → Lua**: `yazi-binding` exposes `Cha`, `File`, `Url`, `Error` as Lua userdata. `yazi-plugin` registers globals (`ui`, `ya`, `fs`, `ps`, `rt`, `th`) and loads presets.

**Lua → Rust**: `ya.manager_emit()` sends commands back. `Composer` (`yazi-plugin/src/composer.rs`) converts Lua UI tables to ratatui elements.

**Plugin types**: Micro (fast async, worker pool) and Macro (slow blocking, shown in task list).

### Async Scheduler

**Worker pools**: 5 micro workers (fast) + 10 macro workers (slow)

**Task types**: File ops (copy/move/delete/trash/link), Plugin execution, Prework (fetch/load/size), Process (open/block/background)

**Lifecycle**: Create → `Ongoing.add()` → Dispatch (priority queue) → Worker executes → `TaskProg` messages → Hook callback → Remove

## Architecture: Rust Core

### Tab Commands (`yazi-core/src/tab/commands/`)
- `cd.rs`: Navigation logic, updates `pane_urls` based on `OptSource`
- `leave.rs`: Blocks at anchor
- `anchor.rs`: Shift+Arrow anchor movement
- `enter.rs`: Pushes to `pane_urls`

### Lua UI (`yazi-plugin/preset/components/`)
- `tab.lua`: Layout logic, creates panes based on `pane_urls` count
- `pane.lua`: Renders earlier panes from history
- `current.lua`: Active folder with full features
- `parent.lua`: Parent folder pane
- `rail.lua`: Border lines between panes

### Executor (`yazi-fm/src/executor.rs`)
- Command dispatcher — new commands must be registered here
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
| `yazi-core/src/mgr/mgr.rs` | Manager: tabs, yanked, watcher, mimetype |
| `yazi-core/src/mgr/commands/refresh.rs` | Folder loading (includes pane_urls) |
| `yazi-fm/src/main.rs` | Entry point, initialization sequence |
| `yazi-fm/src/app/app.rs` | Event loop, render coordination |
| `yazi-fm/src/executor.rs` | Command dispatch with layer routing |
| `yazi-fm/src/context.rs` | `Ctx` — top-level application state |
| `yazi-shared/src/event/event.rs` | Core event types |
| `yazi-proxy/src/mgr.rs` | Manager proxy commands |
| `yazi-plugin/preset/components/tab.lua` | Pane layout logic |
| `yazi-plugin/preset/components/pane.lua` | Earlier pane rendering |
| `yazi-plugin/src/composer.rs` | Lua tables → ratatui widgets |
| `yazi-scheduler/src/scheduler.rs` | Async task orchestration |
| `yazi-dds/src/pubsub.rs` | Event pub/sub system |
| `yazi-config/preset/keymap-default.toml` | Default keybindings |

## Gotchas

1. **Command not working?** Check if registered in `executor.rs`
2. **Pane blank?** Folder not loaded — ensure `refresh.rs` triggers for `pane_urls`
3. **Padding inconsistent?** All panes should use `pad(ui.Pad.x(1))`
4. **Mouse click resets panes?** Avoid `reveal` command, use `cd` for directories
5. **New crate not compiling?** Check workspace `Cargo.toml` members and dependency graph above
6. **Lua changes not visible?** Preset Lua files are embedded at compile time — rebuild required
7. **Event not dispatched?** Trace: Proxy `emit!()` → Event channel → Executor `on!()` match
