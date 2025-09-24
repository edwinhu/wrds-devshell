# WRDS DevShell

A portable development tools bundle for WRDS using Nix devshell and nix-portable.

## Overview

This project creates a single, portable executable containing all essential development tools needed for working on WRDS. The bundle is built using Nix and can run on any Linux system without requiring Nix or any other dependencies to be installed.

## Tools Included

### Data Processing
- **tabiew** (`tw`) - View and query CSV/TSV files
- **xan** - CSV processing tool
- **jq** - JSON processor

### File & Search
- **bat** - Cat with syntax highlighting
- **ripgrep** (`rg`) - Fast recursive grep
- **fd** - Fast file finder
- **fzf** - Fuzzy finder
- **eza** - Modern ls replacement
- **yazi** - Terminal file manager
- **dust** - Disk usage analyzer
- **p7zip** - Archive utility
- **stow** - Symlink manager
- **tailspin** (`tspin`) - Log file highlighter with colors

### System & Environment
- **btop** - System monitor
- **zoxide** - Smarter cd
- **direnv** - Environment variable management
- **parallel** - Run commands in parallel

### Development
- **gh** - GitHub CLI

### Shell & Prompt
- **starship** - Cross-shell prompt
- **zsh** - Z shell

### Documentation & Help
- **tldr** - Simplified man pages

### Document Processing
- **poppler** - PDF utilities
- **resvg** - SVG renderer
- **tectonic** - LaTeX engine

### Sync & Backup
- **rclone** - Cloud storage sync

### Data Science Tools
- **pixi** - Cross-platform conda package manager
- **pixi-pack** - Pack pixi environments for distribution

## Architecture

This project uses a **hybrid approach** combining Nix and Pixi:

1. **Nix DevShell**: Provides portable CLI tools and pixi itself
2. **Pixi Environment**: Handles data science packages (Python, Jupyter, SAS kernel, euporie)
3. **Dual Deployment**:
   - CLI tools → single portable executable via nix-portable
   - Data science → packed environment via pixi-pack

## Quick Start

**One-command deployment:**
```bash
./deploy.sh
```

This will:
1. Build both CLI tools and data science environments
2. Upload everything to WRDS
3. Set up both environments automatically

**Use on WRDS:**
```bash
# CLI Tools (available in PATH via ~/.local/bin)
wrds-tools                        # Enter devshell with all tools
wrds-tools --run tw file.csv      # Run individual tools

# Data Science (automatically installed)
euporie console     # Jupyter console with SAS kernel
euporie notebook    # Jupyter notebook interface
python              # Python with all dependencies
```

## Manual Steps

### Build Only
```bash
./build.sh
```
This creates `wrds-devshell.portable` - a single executable file.

### Deploy to WRDS
```bash
# Copy the bundle
rclone copy wrds-devshell.portable wrds:bin/

# Make executable and add to PATH
ssh wrds 'chmod +x ~/bin/wrds-devshell.portable && ln -sf ~/bin/wrds-devshell.portable ~/bin/wrds-tools'
```

## Development

### Modifying Tools

Edit `devshell.toml` to add, remove, or modify tools:

```toml
[[commands]]
package = "package-name"
name = "alias-name"  # optional
help = "Description"
category = "category"
```

### Testing Locally

```bash
# Enter the devshell locally (requires Nix)
nix develop

# Test specific tools
nix develop --command tw --help
```

## How It Works

1. **devshell.toml** defines the tools and environment
2. **flake.nix** creates a Nix devshell from the TOML config
3. **nix-portable** bundles the devshell into a single executable
4. The bundle is deployed to WRDS via rclone

## Requirements

### Local Machine
- Nix package manager with flakes enabled
- rclone configured for WRDS
- SSH access to WRDS
- **Linux system** or remote Linux builders for creating portable bundles

### WRDS (Target)
- Any recent Linux distribution
- No additional dependencies needed

## Important Note

The `nix bundle` command with nix-portable currently only works on Linux systems. If you're building from macOS, you have these options:

1. **Use GitHub Actions** (recommended): Set up CI to build the bundle automatically
2. **Use remote builders**: Configure Nix to use remote Linux builders
3. **Use Docker/Lima**: Run the build inside a Linux container
4. **Build on WRDS directly**: Clone the repo on WRDS and build there

## File Structure

```
wrds-devshell/
├── flake.nix          # Nix flake configuration
├── devshell.toml      # Tool definitions
├── build.sh           # Build the portable bundle
├── deploy.sh          # Build and deploy to WRDS
└── README.md          # This file
```

## Troubleshooting

### Build Issues
- Ensure you have Nix with flakes enabled
- Check that all packages in devshell.toml exist in nixpkgs

### Deployment Issues
- Verify rclone is configured for WRDS: `rclone config`
- Test SSH access: `ssh wrds echo "Connection OK"`

### Runtime Issues on WRDS
- Ensure the bundle is executable: `chmod +x ~/bin/wrds-devshell.portable`
- Check that ~/bin is in PATH: `echo $PATH`