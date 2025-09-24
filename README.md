# WRDS DevShell

A portable development tools bundle for WRDS using Nix devshell and nix-portable.

## Overview

This project creates a single, portable executable containing all essential development tools needed for working on WRDS. The bundle is built using Nix and can run on any Linux system without requiring Nix or any other dependencies to be installed.

## Tools Included

- **tabiew** (`tw`) - View and query CSV/TSV files
- **bat** - Cat with syntax highlighting
- **ripgrep** (`rg`) - Fast recursive grep
- **fd** - Fast file finder
- **fzf** - Fuzzy finder
- **xan** - CSV processing tool
- **eza** - Modern ls replacement
- **zoxide** - Smarter cd
- **jq** - JSON processor
- **dust** - Disk usage analyzer
- **btop** - System monitor
- **yazi** - Terminal file manager

## Quick Start

1. **Build and Deploy:**
   ```bash
   ./deploy.sh
   ```

2. **Use on WRDS:**
   ```bash
   # Enter the devshell (all tools available)
   ~/bin/wrds-tools

   # Run individual tools
   ~/bin/wrds-tools --run tw data.csv
   ~/bin/wrds-tools --run rg "pattern" .
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
- Nix package manager
- rclone configured for WRDS
- SSH access to WRDS

### WRDS (Target)
- Any recent Linux distribution
- No additional dependencies needed

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