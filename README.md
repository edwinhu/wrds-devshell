# WRDS DevShell

A portable development environment for WRDS using a hybrid Nix + Pixi approach.

## Overview

This project creates portable development environments for WRDS (Wharton Research Data Services) that run without requiring any dependencies on the target system. It uses a hybrid approach combining Nix for CLI tools and Pixi for data science packages.

## Architecture

**Hybrid Approach:**
1. **CLI Tools Bundle**: Nix DevShell → nix-portable → single 167MB executable
2. **Data Science Environment**: Pixi → pixi-pack → conda-style portable environment
3. **Build System**: Lima VM for cross-platform Linux builds on macOS

## Tools Included

### CLI Tools Bundle (wrds-devshell.portable)
- **tabiew** (`tw`) - View and query CSV/TSV files
- **bat** - Cat with syntax highlighting
- **ripgrep** (`rg`) - Fast recursive text search
- **fd** - Fast file finder
- **fzf** - Fuzzy finder
- **eza** - Modern ls replacement
- **zoxide** - Smarter cd command
- **jq** - JSON processor
- **zsh** - Advanced shell
- **rclone** - Cloud storage sync

### Data Science Environment (environment.sh)
- **euporie** - Enhanced Jupyter console/notebook interface
- **sas_kernel** - SAS kernel for Jupyter
- **Python** - Full Python environment with data science stack
- **zsh** - Shell environment

## Quick Start

**One-command deployment:**
```bash
./deploy.sh
```

This builds and deploys both environments to WRDS automatically.

**Use on WRDS:**
```bash
# CLI Tools (in ~/.local/bin)
wrds-tools                    # Enter devshell with all tools
wrds-tools tw file.csv        # Run tabiew directly
tw file.csv                   # Direct access (tools are in PATH)

# Data Science
euporie console               # Jupyter console with SAS kernel
euporie notebook              # Jupyter notebook interface
python-wrds                   # Python environment
```

## Build System

### Automatic Lima VM (macOS)
The build system automatically uses Lima (Linux on Mac) VMs to create Linux binaries:

- **Automatic**: `./build.sh` detects macOS and uses Lima VM
- **No setup required**: VM starts automatically with Determinate Systems Nix
- **Cross-architecture**: Builds for both x86_64 and aarch64 Linux

### Manual Build
```bash
# Build both environments
./build.sh

# Build only CLI tools
nix bundle --bundler github:DavHau/nix-portable .#devShells.default.default -o wrds-devshell

# Build only data science
pixi install  # Generate lock file
pixi-pack --platform linux-64 --create-executable
```

## Deployment Options

### Full Deployment (Recommended)
```bash
./deploy.sh                   # Builds and deploys both environments
```

### CLI Tools Only
```bash
./build.sh                    # Creates wrds-devshell.portable
rclone copy wrds-devshell.portable wrds:
ssh wrds 'mv wrds-devshell.portable ~/.local/bin/wrds-tools && chmod +x ~/.local/bin/wrds-tools'
```

### Data Science Only
```bash
./deploy-data-science-only.sh
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
- **Any**: Nix with flakes enabled
- rclone configured for WRDS
- SSH access to WRDS

### WRDS (Target)
- Any Linux distribution
- No dependencies required
- ~/.local/bin in PATH (usually automatic)

## File Structure

```
wrds-devshell/
├── flake.nix                    # Nix flake for CLI tools
├── devshell.toml               # CLI tool definitions
├── pixi.toml                   # Data science dependencies
├── build.sh                    # Build both environments (Lima VM on macOS)
├── deploy.sh                   # Build and deploy everything
├── deploy-data-science-only.sh # Deploy only data science
├── nix-builder.yaml           # Lima VM configuration
└── README.md                   # This file
```

## Deployment Details

**CLI Tools Installation:**
- Deployed to: `~/.local/bin/wrds-tools`
- All tools accessible directly (tw, rg, bat, etc.)
- Single 167MB executable

**Data Science Installation:**
- Environment: `~/.local/wrds-data-science/`
- Activation: `source ~/.local/bin/activate-wrds-data-science`
- Direct tools: `euporie`, `python-wrds` in PATH

## Troubleshooting

### Build Issues
```bash
# Check Lima VM status
limactl list

# Restart Lima VM
limactl stop default && limactl start default

# Check Nix in VM
lima nix --version
```

### Deployment Issues
```bash
# Test connections
rclone ls wrds:
ssh wrds echo "OK"

# Check deployed tools
ssh wrds 'ls -la ~/.local/bin/'
ssh wrds 'wrds-tools --help'
```

### Runtime Issues
```bash
# Check PATH on WRDS
ssh wrds 'echo $PATH | tr : \\n | grep local'

# Test individual tools
ssh wrds 'tw --version'
ssh wrds 'euporie --version'
```

## Build Times
- **First build**: 10-15 minutes (downloads all dependencies)
- **Incremental builds**: 2-3 minutes (cached dependencies)
- **VM startup**: 30-60 seconds (automatic)

The Lima VM approach provides reliable cross-platform builds while maintaining the simplicity of single-command deployment.