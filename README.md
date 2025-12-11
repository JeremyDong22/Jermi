# Jermi - Anchored File Manager

A fork of [Yazi](https://github.com/sxyazi/yazi) with **dynamic panes** and **anchor-based navigation** - designed for developers who want VSCode-like file browsing in the terminal.

## The Story

As a developer entering the tmux + terminal world, I tried various file managers:

- **Ranger/lf** - The sliding window navigation felt disorienting. When exploring deep into a project, I'd often lose track of where I started.
- **broot/btm** - Tree views are powerful but too rigid. Expanding/collapsing nodes felt clunky compared to just navigating.
- **Yazi** - Fast, beautiful, async... but still had the sliding window problem.

I wanted something that works like **VSCode's file explorer**:
- Your project root stays visible on the left
- You can navigate deep into folders without losing context
- The view expands naturally as you go deeper

So I forked Yazi and created **Jermi** with these features.

## Key Features

### Anchor-Based Navigation
When you open Jermi, your starting directory becomes the **anchor** - a fixed left boundary that never scrolls away.

```
Traditional sliding window:        Jermi anchored view:

src/  components/  Button.tsx      project/  src/  components/  Button.tsx
  ↑                                    ↑
  You lose the project root!           Anchor stays visible!
```

### Dynamic Panes
As you navigate deeper, panes are added dynamically:
- **At anchor**: 2 panes (current + preview)
- **1 level deep**: 3 panes (anchor + current + preview)
- **2 levels deep**: 4 panes (anchor + parent + current + preview)
- And so on...

### Shift+Arrow Anchor Control
- **Shift+Left**: Expand root - move anchor to parent directory
- **Shift+Right**: Shrink root - move anchor to current directory

This lets you dynamically adjust your "project root" while browsing!

### Auto-Resizing Preview
When pane layout changes (entering/leaving directories, adjusting anchor), the preview automatically resizes to fit the new layout. Image previews seamlessly adapt to the available space - no manual refresh needed.

## Installation

### Pre-built Binary (Linux x86_64)

Download the latest release:

```bash
# Download and extract
wget https://github.com/JeremyDong22/Jermi/releases/download/v1.0.0/jermi-x86_64-unknown-linux-gnu.zip
unzip jermi-x86_64-unknown-linux-gnu.zip
cd jermi-x86_64-unknown-linux-gnu

# Run directly
./yazi

# Or install system-wide
sudo cp yazi ya /usr/local/bin/
sudo cp completions/* /usr/share/bash-completion/completions/
```

You can also run it as `jermi` if installed.

### From Source

```bash
git clone https://github.com/JeremyDong22/Jermi.git
cd Jermi
./install.sh
```

Make sure `~/.local/bin` is in your PATH:
```bash
export PATH="${HOME}/.local/bin:${PATH}"
```

Then run:
```bash
jermi
```

### Requirements

- For pre-built binary: A terminal with true color support (recommended)
- For building from source: Rust toolchain + terminal with true color support

## Keybindings

| Key | Action |
|-----|--------|
| `h` / `Left` | Go to parent directory |
| `l` / `Right` / `Enter` | Enter directory / Open file |
| `j` / `Down` | Move cursor down |
| `k` / `Up` | Move cursor up |
| `Shift+Left` | Expand anchor (move to parent) |
| `Shift+Right` | Shrink anchor (move to current) |
| `q` | Quit |

All other Yazi keybindings work as expected. See [Yazi documentation](https://yazi-rs.github.io/docs/quick-start) for more.

## How It Works

1. **Anchor**: The startup directory is saved as the "anchor" - it defines the leftmost visible boundary
2. **Leave blocked at anchor**: When you're at the anchor, pressing `h`/`Left` does nothing (you can't go "above" your project root)
3. **Dynamic pane_urls**: As you `Enter` directories, each path is tracked in `pane_urls` and rendered as a pane
4. **Shift+Arrow control**: Dynamically move the anchor to explore different scopes

## Based on Yazi

Jermi inherits all of Yazi's amazing features:
- Blazing fast async I/O
- Built-in image preview (Kitty, iTerm2, Sixel, etc.)
- Lua plugin system
- Syntax highlighting
- And much more...

## License

MIT License - Same as Yazi.

## Credits

- [Yazi](https://github.com/sxyazi/yazi) - The incredible terminal file manager this is forked from
- [sxyazi](https://github.com/sxyazi) - Creator of Yazi
