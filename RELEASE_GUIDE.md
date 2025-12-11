# Jermi Release Guide

## Automated Release System

Jermi now has an automated GitHub Actions workflow for building and releasing Linux x86_64 binaries, similar to Yazi's release system.

## How to Enable GitHub Actions (First Time Setup)

1. Go to https://github.com/JeremyDong22/Jermi/settings/actions
2. Under "Actions permissions", select "Allow all actions and reusable workflows"
3. Save the settings

## How to Create a Release

### Option 1: Tag-based Release (Recommended)

1. Create and push a version tag:
   ```bash
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```

2. GitHub Actions will automatically:
   - Build the Linux x86_64 binary
   - Create a draft release
   - Upload `jermi-x86_64-unknown-linux-gnu.zip`

3. Go to https://github.com/JeremyDong22/Jermi/releases
4. Edit the draft release and publish it

### Option 2: Manual Workflow Trigger

1. Go to https://github.com/JeremyDong22/Jermi/actions/workflows/draft.yml
2. Click "Run workflow"
3. Select the branch (e.g., `dynamic-panes`)
4. Click "Run workflow"

This will create a nightly build.

## Download Links

After publishing a release, users can download binaries at:
```
https://github.com/JeremyDong22/Jermi/releases/download/v1.0.0/jermi-x86_64-unknown-linux-gnu.zip
```

## What's Included in the Release

The zip file contains:
- `yazi` - Main Jermi binary
- `ya` - Jermi CLI helper
- `completions/` - Shell completions for bash, zsh, fish
- `README.md` - Project documentation
- `LICENSE` - License file

## Usage After Download

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

## Current Status

- ✅ GitHub Actions workflow configured
- ✅ Build script created (`scripts/build-jermi.sh`)
- ✅ Tag `v1.0.0` created and pushed
- ⏳ Waiting for GitHub Actions to be enabled in repository settings

## Next Steps

1. Enable GitHub Actions in repository settings (see above)
2. Manually trigger the workflow or wait for the next tag push
3. Verify the build completes successfully
4. Publish the draft release
