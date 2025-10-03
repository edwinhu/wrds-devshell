# WRDS DevShell

A portable development environment for WRDS using a hybrid Nix + Pixi approach.

## Overview

This project creates portable development environments for WRDS (Wharton Research Data Services) that run without requiring any dependencies on the target system. It uses a hybrid approach combining **Nix** for CLI tools and **Pixi** for data science packages.

## Complete Workflow

### 🏗️ Development Setup (macOS)

```bash
# Project structure
~/projects/wrds/wrds-devshell/
├── devshell.toml          # CLI tools definition (Nix)
├── pixi.toml             # Data science packages (Conda)
├── flake.nix             # Nix configuration
├── build.sh              # Build both environments
└── deploy.sh             # Deploy to WRDS
```

There are also flake and pixi lockfiles to pin dependencies.

### 📦 Build Process

```bash
./build.sh
```

**What happens:**

1. **CLI Tools (Nix)**: Uses x86_64 Lima VM on macOS or builds directly on Linux
   - Reads `devshell.toml` (25 CLI tools including databases)
   - Creates `wrds-devshell.portable` (~649MB) - single self-contained executable

2. **Data Science (Pixi)**: Uses pixi-pack to create self-extracting archive
   - Reads `pixi.toml` (euporie, jupyter, sas_kernel, pixi-pack, python)
   - Creates `environment.sh` (~197MB) - self-extracting archive

### 🚀 Deployment Process

```bash
./deploy.sh
```

**What happens:**

1. **Upload**: Transfers files to WRDS via rclone
2. **Install CLI tools**: Moves to `~/.local/bin/wrds-tools`
3. **Install data science**: Extracts to `~/.local/wrds-data-science/`
4. **PATH setup**: Adds `~/.local/wrds-data-science/bin` to `~/.shell_env`

**Note**: Run `./build.sh` first when configs change. `./deploy.sh` only uploads existing artifacts.

### 🔧 Runtime on WRDS

**Automatic setup** via `~/.shell_env` (sourced on login):

```bash
# PATH includes data science tools
export PATH="$HOME/.local/wrds-data-science/bin:$PATH"
```

**Available after shell reload:**

```bash
ssh wrds
source ~/.shell_env  # Or start new shell

# All tools work:
wrds-tools             # Enter devshell with all CLI tools
fzf                    # Fuzzy finder
rg "pattern" .         # Search
fd filename            # Find files
bat file.txt          # Syntax highlighting
tw data.csv           # View CSV files
sqlite3 database.db   # SQLite database CLI
duckdb                # DuckDB analytical database
euporie console       # Jupyter with SAS
jupyter console       # Standard Jupyter
pixi-pack             # Package pixi environments
```

## Tools Included

### CLI Tools Bundle (devshell.toml)

- **tabiew** (`tw`) - View and query CSV/TSV files
- **bat** - Cat with syntax highlighting
- **ripgrep** (`rg`) - Fast recursive text search
- **fd** - Fast file finder
- **fzf** - Fuzzy finder
- **eza** - Modern ls replacement
- **zoxide** - Smarter cd command
- **jq** - JSON processor (1.7.1, updated from system 1.6)
- **zsh** - Advanced shell
- **starship** - Cross-shell prompt
- **rclone** - Cloud storage sync (1.71.0, updated from system 1.70.3)
- **direnv** - Environment variable management
- **sqlite3** - SQLite database engine CLI (3.50.2)
- **duckdb** - In-process SQL OLAP database CLI (1.3.2)

### Data Science Environment (pixi.toml)

- **euporie** - Enhanced Jupyter console/notebook interface
- **sas_kernel** - SAS kernel for Jupyter
- **Python 3.13.7** - Full Python environment with data science stack

## Key Benefits

1. **Portable**: No dependencies on WRDS system packages
2. **Modern**: Latest versions of all tools
3. **Instant**: All tools available immediately on login
4. **Cross-platform**: Builds on macOS, runs on Linux
5. **Reproducible**: Declarative configuration files
6. **Efficient**: Single executables, no complex installation

## Quick Start

**One-command deployment:**

```bash
./deploy.sh
```

This builds and deploys both environments to WRDS automatically.

## Update Workflow

```bash
# 1. Modify tools
vim devshell.toml      # Add/remove CLI tools
vim pixi.toml          # Add/remove data science packages

# 2. Build and deploy
./build.sh && ./deploy.sh

# 3. Tools immediately available on WRDS
```

## Build System

### x86_64 Lima VM (macOS)

The build system uses a dedicated x86_64 Lima VM for cross-compilation:

- **VM**: `nix-x86_64-builder` with x86_64 emulation
- **Automatic**: `./build.sh` starts VM and builds Linux binaries
- **Architecture**: Ensures x86_64 Linux compatibility for WRDS servers

### Manual Build Commands

```bash
# Build both environments
./build.sh

# Build only CLI tools (requires x86_64 Linux or Lima VM)
nix bundle --bundler github:DavHau/nix-portable .#devShells.x86_64-linux.default -o wrds-devshell

# Build only data science
pixi-pack --platform linux-64 --create-executable
```

## Development

### Adding CLI Tools

Edit `devshell.toml`:

```toml
[[commands]]
package = "package-name"
name = "alias-name"     # optional
help = "Description"
category = "category"
```

### Adding Data Science Packages

Edit `pixi.toml`:

```toml
[dependencies]
new-package = ">=1.0"
```

### Local Testing

```bash
# Test CLI tools
nix develop                   # Requires Nix locally
nix develop --command tw --help

# Test data science
pixi shell                    # Requires pixi locally
pixi run python
```

## System Requirements

### Build Machine

- **macOS**: Lima VM (automatically managed)
- **Linux**: Native Nix builds
- **Required**: Nix with flakes enabled, pixi, SSH access to WRDS

### WRDS (Target)

- Any Linux distribution
- No dependencies required
- `~/.local/bin` in PATH (automatic)

## File Structure

```
wrds-devshell/
├── flake.nix                    # Nix flake for CLI tools
├── devshell.toml               # CLI tool definitions
├── pixi.toml                   # Data science dependencies
├── build.sh                    # Build both environments
├── deploy.sh                   # Build and deploy everything
├── nix-x86_64-builder.yaml    # Lima VM configuration
└── README.md                   # This file
```

## Deployment Details

**On WRDS after deployment:**

- **CLI Tools**: `~/.local/bin/wrds-tools` + individual tools in PATH
- **Data Science**: `~/.local/wrds-data-science/` + symlinks (`euporie`, `python-wrds`)
- **Integration**: `~/.wrds-setup` sourced on login for automatic tool initialization
- **Size**: 626MB CLI bundle + 193MB data science bundle

## Troubleshooting

### Build Issues

```bash
# Check x86_64 Lima VM status
limactl list nix-x86_64-builder

# Restart Lima VM
limactl stop nix-x86_64-builder && limactl start nix-x86_64-builder

# Check Nix in VM
limactl shell nix-x86_64-builder -- nix --version
```

### Deployment Issues

```bash
# Test SSH connection
ssh wrds echo "OK"

# Check deployed tools
ssh wrds 'ls -la ~/.local/bin/'
ssh wrds 'tw --version'
```

### Runtime Issues

```bash
# Check tool availability
ssh wrds 'which fzf starship zoxide direnv tw sqlite3 duckdb'
ssh wrds 'euporie --version && python-wrds --version'
ssh wrds 'sqlite3 --version && duckdb --version'
```

## Architecture Notes

The hybrid approach combines the best of both ecosystems:

- **Nix**: Hermetic, reproducible CLI tools with precise dependency management
- **Pixi**: Python ecosystem compatibility for data science workflows
- **nix-portable**: Single-file deployment without Nix installation on target
- **Lima VM**: Cross-platform Linux builds from macOS development environment

This provides modern, portable development tools that work immediately on any Linux system without dependencies.

