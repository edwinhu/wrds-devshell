# WRDS DevShell Project Context

This project creates portable development environments for WRDS (Wharton Research Data Services) using a hybrid Nix + Pixi approach.

## Project Overview

**Goal**: Deploy modern CLI tools and data science environments to WRDS without requiring system dependencies.

**Architecture**:
- **CLI Tools**: Nix → nix-portable → single executable (25 tools)
- **Data Science**: Pixi → pixi-pack → self-extracting archive
- **Build System**: x86_64 Lima VM for cross-compilation on macOS

## Core Workflow

```bash
# Build both environments
./build.sh

# Deploy to WRDS
./deploy.sh
```

**CRITICAL**: These scripts MUST work. The entire system depends on them.

## CLI Tools (25 total in devshell.toml)

### Essential Tools
- **tw (tabiew)** - View CSV/TSV files
- **bat** - Syntax highlighting cat
- **rg (ripgrep)** - Fast text search
- **fd** - Fast file finder
- **fzf** - Fuzzy finder
- **eza** - Modern ls replacement
- **zoxide** - Smart cd command
- **starship** - Cross-shell prompt
- **direnv** - Environment management

### Development Tools
- **gh** - GitHub CLI
- **jq** - JSON processor (updated from system 1.6 → 1.7.1)
- **zsh** - Advanced shell
- **parallel** - GNU parallel execution

### System Tools
- **btop** - Resource monitor
- **dust** - Disk usage analyzer
- **yazi** - Terminal file manager
- **stow** - Symlink farm manager

### Document/Media Tools
- **tectonic** - Modern LaTeX engine
- **poppler** - PDF manipulation
- **resvg** - SVG renderer
- **tldr** - Simplified man pages

### Compression/Data Tools
- **p7zip** - 7-Zip compression
- **rclone** - Cloud storage sync (updated from system 1.70.3 → 1.71.0)
- **xan** - CSV toolkit
- **tailspin** - Log file highlighter

## Data Science Tools (pixi.toml)

- **euporie** 2.8.13 - Enhanced Jupyter console/notebook
- **sas_kernel** - SAS kernel for Jupyter
- **jupyter** - Standard Jupyter console and notebook
- **pixi-pack** - Package pixi environments for deployment
- **Python 3.13.7** - Full Python environment

## Build System

### x86_64 Lima VM (macOS)
- **VM Name**: `nix-x86_64-builder`
- **Purpose**: Cross-compile x86_64 Linux binaries on Apple Silicon
- **Config**: `nix-x86_64-builder.yaml`
- **Auto-managed**: build.sh starts/manages VM automatically

### Build Process
1. **CLI Tools**: Uses Lima VM on macOS or direct build on Linux with Nix + nix-portable bundler
2. **Data Science**: Uses pixi + pixi-pack to create self-extracting archive
3. **Output**: `wrds-devshell.portable` (~649MB) + `environment.sh` (~197MB)

## Deployment Process

### File Transfer
- Uses rclone for efficient file transfer
- Handles large files with resume capability
- Uploads to WRDS home directory, then moves to final location

### Shell Integration
- Adds `~/.local/wrds-data-science/bin` to PATH via `~/.shell_env`
- CLI tools available via `~/.local/bin/wrds-tools`
- All tools available after shell reload

## File Structure

```
wrds-devshell/
├── devshell.toml          # 25 CLI tools definition
├── pixi.toml             # Data science packages
├── flake.nix             # Nix configuration
├── build.sh              # MUST WORK - builds both environments
├── deploy.sh             # MUST WORK - deploys to WRDS
├── nix-x86_64-builder.yaml  # Lima VM config
└── README.md             # User documentation
```

## Critical Requirements

### build.sh MUST:
1. Detect OS (macOS uses Lima VM, Linux builds directly)
2. Build nix-portable bundle with all 25 CLI tools
3. Build pixi data science environment with pixi-pack
4. Extract executable from nix bundle output
5. Complete successfully with proper error handling

### deploy.sh MUST:
1. Check for existing build artifacts (does NOT build)
2. Upload files via rclone
3. Install CLI tools to ~/.local/bin/wrds-tools
4. Install data science to ~/.local/wrds-data-science/
5. Add wrds-data-science/bin to PATH in ~/.shell_env
6. Single SSH session for all remote commands

## Current Status

### Working
- ✅ All 25 CLI tools in devshell.toml
- ✅ Data science environment with jupyter, euporie, pixi-pack
- ✅ Shell integration via ~/.shell_env
- ✅ Lima VM x86_64 builds on macOS
- ✅ Direct builds on Linux servers
- ✅ Simplified build and deploy workflow
- ✅ Rclone-based deployment

### Recent Improvements
- ✅ Removed unused nix-builder.yaml
- ✅ Simplified build.sh and deploy.sh scripts
- ✅ Separated build and deploy (build when configs change, deploy to upload)
- ✅ Added jupyter and pixi-pack to data science tools
- ✅ PATH configuration via ~/.shell_env instead of symlinks

## Key Technical Details

### Architecture Mismatch
- **Problem**: Apple Silicon (aarch64) vs WRDS (x86_64)
- **Solution**: x86_64 Lima VM with QEMU emulation

### Tool Sources
- **devshell.toml**: Must include ALL 25 CLI tools from ../pixi.toml
- **Versions**: Use latest versions, not system packages (jq 1.7.1, rclone 1.71.0)

### Deployment Target
- **Location**: WRDS Linux servers
- **Integration**: Tools must work immediately on SSH login
- **Size**: CLI bundle ~629MB, Data science ~160MB
- **Space**: Recently cleaned 3.5GB, should have room now

## Success Criteria

When working properly:
```bash
# On development machine
./build.sh      # Creates wrds-devshell.portable + environment.sh
./deploy.sh     # Uploads and installs both to WRDS

# On WRDS after deployment
ssh wrds
# All 25 CLI tools work immediately:
btop           # Resource monitor
gh --version   # GitHub CLI
yazi          # File manager
tw data.csv   # View CSV files
euporie console # Jupyter with SAS
```

**The build.sh and deploy.sh scripts are the core of this project and MUST work reliably.**