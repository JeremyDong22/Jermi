<div align="center">

# Jermi

**A terminal file manager that doesn't lose your project root.**

A fork of [Yazi](https://github.com/sxyazi/yazi) with **anchored navigation** and **dynamic panes** — built for developers who want VSCode‑style file browsing in the terminal.

[Installation](#installation) · [Quick Start](#quick-start) · [Keybindings](#keybindings) · [How It Works](#how-it-works)

</div>

---

## Why Jermi?

As a developer in tmux + terminal land, I tried every file manager and they all had the same problem:

| Tool          | The pain                                                              |
| ------------- | --------------------------------------------------------------------- |
| **Ranger / lf** | Sliding window — go three folders deep and you forget where you started |
| **broot**     | Tree view is powerful but expanding/collapsing nodes feels clunky       |
| **Yazi**      | Fast, gorgeous, async… but still scrolls your project root off‑screen   |

I wanted **VSCode's file explorer in the terminal**: the project root pinned on the left, and the view *grows* as you go deeper instead of sliding.

So I forked Yazi. That's Jermi.

```
Traditional sliding window           Jermi anchored view
──────────────────────────────       ──────────────────────────────────────
src/  components/  Button.tsx        project/  src/  components/  Button.tsx
  ↑                                      ↑
  project root scrolled away             anchor stays pinned
```

---

## Key Features

### 1. Anchor‑based navigation
Your starting directory becomes the **anchor** — a fixed left boundary that never scrolls away.

### 2. Dynamic panes
Panes appear *as you go deeper*, not in a fixed slot count.

| Where you are        | Panes shown                                |
| -------------------- | ------------------------------------------ |
| At anchor            | 2 panes (current + preview)                |
| 1 level deep         | 3 panes (anchor + current + preview)       |
| 2 levels deep        | 4 panes (anchor + parent + current + …)    |
| N levels deep        | N + 2 panes                                |

### 3. Shift+Arrow anchor control
- `Shift+Left`  — **expand** root (move anchor up to its parent)
- `Shift+Right` — **shrink** root (move anchor down to current directory)

Adjust your "project root" on the fly without restarting.

---

## Installation

There are two ways to install. **Pick one.**

> If you don't know which to pick: choose **Method 1**. It's faster and doesn't require Rust.

### Method 1 — Prebuilt Binary (Recommended)

#### Step 1 · Download

Go to **[Releases → nightly](https://github.com/JeremyDong22/Jermi/releases/tag/nightly)** and download the file matching your system:

| Your system                    | File to download                       |
| ------------------------------ | -------------------------------------- |
| macOS — Apple Silicon (M1/M2/M3/M4) | `yazi-aarch64-apple-darwin.zip`        |
| macOS — Intel                  | `yazi-x86_64-apple-darwin.zip`         |
| Linux — x86_64                 | `yazi-x86_64-unknown-linux-gnu.zip`    |
| Linux — ARM64                  | `yazi-aarch64-unknown-linux-gnu.zip`   |
| Linux — musl (Alpine, etc.)    | `yazi-x86_64-unknown-linux-musl.zip`   |
| Windows — x86_64               | `yazi-x86_64-pc-windows-msvc.zip`      |

#### Step 2 · Install

Open a terminal in the folder where you downloaded the zip, then **copy‑paste the block for your platform**:

<details>
<summary><b>macOS — Apple Silicon</b> (click to expand)</summary>

```bash
unzip yazi-aarch64-apple-darwin.zip
mkdir -p ~/.local/bin
cp yazi-aarch64-apple-darwin/yazi ~/.local/bin/jermi
chmod +x ~/.local/bin/jermi

# Required on Apple Silicon — clears the quarantine xattr and ad-hoc signs
# the binary so macOS (AMFI) doesn't kill it on launch.
xattr -c ~/.local/bin/jermi
codesign --force --sign - ~/.local/bin/jermi
```
</details>

<details>
<summary><b>macOS — Intel</b></summary>

```bash
unzip yazi-x86_64-apple-darwin.zip
mkdir -p ~/.local/bin
cp yazi-x86_64-apple-darwin/yazi ~/.local/bin/jermi
chmod +x ~/.local/bin/jermi
xattr -c ~/.local/bin/jermi
codesign --force --sign - ~/.local/bin/jermi
```
</details>

<details>
<summary><b>Linux</b> (x86_64 / ARM64 / musl)</summary>

Replace `<file>` with the zip you downloaded.

```bash
unzip <file>.zip
mkdir -p ~/.local/bin
cp <file>/yazi ~/.local/bin/jermi
chmod +x ~/.local/bin/jermi
```
</details>

<details>
<summary><b>Windows</b></summary>

```powershell
Expand-Archive yazi-x86_64-pc-windows-msvc.zip -DestinationPath .
Copy-Item yazi-x86_64-pc-windows-msvc\yazi.exe $HOME\bin\jermi.exe
```

Make sure `$HOME\bin` is in your `PATH`.
</details>

#### Step 3 · Add to PATH and run

```bash
# zsh (default on macOS)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Then launch:

```bash
jermi
```

If you see file panes — you're done. 

---

### Method 2 — Build from Source

Requires the [Rust toolchain](https://rustup.rs).

```bash
git clone https://github.com/JeremyDong22/Jermi.git
cd Jermi
./install.sh
```

`install.sh` will:
1. Build the release binary with `cargo build --release`
2. Copy it to `~/.local/bin/jermi`
3. On macOS, automatically run the `xattr` + `codesign` step

Then add `~/.local/bin` to your PATH (see Step 3 above) and run `jermi`.

---

### Troubleshooting

<details>
<summary><b><code>zsh: killed jermi</code> on Apple Silicon</b></summary>

macOS killed the binary because of a quarantine attribute. Re‑run:

```bash
xattr -c ~/.local/bin/jermi
codesign --force --sign - ~/.local/bin/jermi
```
</details>

<details>
<summary><b><code>jermi: command not found</code></b></summary>

`~/.local/bin` isn't in your `PATH`. Run Step 3 above, then **open a new terminal window**.
</details>

<details>
<summary><b>Build fails with "empty directory" errors</b></summary>

If your repo lives in `~/Desktop` or `~/Documents` (iCloud‑synced), iCloud may create empty `yazi-* 2/` shadow directories that break the build:

```bash
rm -rf *" 2"*
```

Long term: move the repo out of iCloud‑synced paths.
</details>

---

## Quick Start

```bash
cd ~/your-project
jermi
```

That directory becomes the anchor. Navigate with `j`/`k`/`h`/`l` (or arrow keys). The root pane stays pinned no matter how deep you go.

---

## Keybindings

| Key                       | Action                                |
| ------------------------- | ------------------------------------- |
| `h` / `Left`              | Go to parent directory                |
| `l` / `Right` / `Enter`   | Enter directory / open file           |
| `j` / `Down`              | Move cursor down                      |
| `k` / `Up`                | Move cursor up                        |
| `Shift+Left`              | **Expand anchor** (move to parent)    |
| `Shift+Right`             | **Shrink anchor** (move to current)   |
| `q`                       | Quit                                  |

All other Yazi keybindings still work — see the [Yazi docs](https://yazi-rs.github.io/docs/quick-start).

---

## How It Works

1. **Anchor** — the startup directory is saved as the "anchor" and defines the leftmost visible boundary.
2. **`Leave` blocked at anchor** — pressing `h`/`Left` at the anchor does nothing. You can't go above your project root.
3. **`pane_urls` is auto‑derived** — every `cd` rebuilds the chain `[anchor, …, target]` automatically; nothing is pushed/popped manually.
4. **`Shift+Arrow` adjusts the anchor** — move the boundary up or down without restarting.

---

## Built on Yazi

Jermi inherits everything that makes Yazi great:

- Async I/O — instant directory loads
- Built‑in image preview (Kitty, iTerm2, Sixel, …)
- Lua plugin system
- Syntax highlighting
- And much more

---

## License

MIT — same as Yazi.

## Credits

- [Yazi](https://github.com/sxyazi/yazi) — the incredible terminal file manager this is forked from
- [@sxyazi](https://github.com/sxyazi) — creator of Yazi
