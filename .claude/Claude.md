# WRDS DevShell - Claude Code Instructions

## Critical: nix-portable Runtime Configuration

### The Problem

When deploying nix-portable bundles to WRDS, the default **bwrap** (bubblewrap) runtime fails with:

```
error: unable to exec '/home/nyu/eddyhu/.nix-portable/nix/store/.../bin/nix-store': No such file or directory
```

**Root cause**: bwrap requires user namespaces which are not available on WRDS servers.

**Solution**: Use **proot** runtime instead, which works without user namespaces.

### Proper Deployment Workflow

#### 1. Build Phase (on development machine)

```bash
./build.sh
```

This creates:
- `wrds-devshell.portable` (~664MB) - CLI tools bundle
- `environment.sh` (~204MB) - Data science environment

**Build locations**:
- **macOS**: Uses x86_64 Lima VM for cross-compilation
- **Linux**: Direct build on host

#### 2. Deploy Phase

```bash
./deploy.sh
```

This automatically:
1. Uploads files to WRDS via rclone
2. Installs CLI tools to `~/.local/bin/wrds-tools`
3. Installs data science to `~/.local/wrds-data-science/`
4. **Configures `NP_RUNTIME=proot` in `~/.shell_env`** (CRITICAL)
5. Adds data science PATH to `~/.shell_env`

#### 3. Testing Phase

**ALWAYS test with a fresh login shell** to ensure environment variables are loaded:

```bash
# Test individual tools
ssh wrds "bash -l -c '~/.local/bin/wrds-tools rga --version'"
ssh wrds "bash -l -c '~/.local/bin/wrds-tools fd --version'"
ssh wrds "bash -l -c '~/.local/bin/wrds-tools tw --version'"

# Test actual functionality
ssh wrds "bash -l -c 'cd /tmp && echo test > test.txt && gzip test.txt && ~/.local/bin/wrds-tools rga test test.txt.gz && rm test.txt.gz'"
```

**Why `bash -l -c`?**
- `-l` (login shell) sources `~/.shell_env` which sets `NP_RUNTIME=proot`
- Without it, tests may fail even though deployment is correct

### Manual Runtime Configuration

If `NP_RUNTIME=proot` is not in `~/.shell_env`, add it:

```bash
ssh wrds "echo '# nix-portable runtime configuration - use proot on WRDS
export NP_RUNTIME=proot' >> ~/.shell_env"
```

### Debugging Runtime Issues

#### Check current runtime:
```bash
ssh wrds "bash -l -c 'echo \$NP_RUNTIME'"
```

Should output: `proot`

#### Test with manual runtime override:
```bash
ssh wrds "NP_RUNTIME=proot ~/.local/bin/wrds-tools fd --version"
```

If this works but normal invocation fails, the environment variable isn't being set.

#### Check what runtime nix-portable detects:
```bash
ssh wrds "~/.local/bin/wrds-tools menu" | grep -i runtime
```

### Common Errors and Fixes

#### Error: "nix-store: No such file or directory"
- **Cause**: Using bwrap runtime on WRDS
- **Fix**: Set `NP_RUNTIME=proot` in `~/.shell_env`

#### Error: "command not found: rga"
- **Cause**: Trying to use `rga` directly instead of via `wrds-tools`
- **Fix**: Use `~/.local/bin/wrds-tools rga` (wrds-tools is a shell wrapper)

#### Error: Tests fail in SSH command but work interactively
- **Cause**: Not using login shell (`-l` flag)
- **Fix**: Use `ssh wrds "bash -l -c 'command'"` for testing

### File Locations on WRDS

```
~/.local/bin/wrds-tools           # CLI tools executable
~/.local/wrds-data-science/       # Data science environment
~/.shell_env                      # Environment configuration (contains NP_RUNTIME=proot)
~/.nix-portable/                  # nix-portable cache (auto-created)
```

### Available CLI Tools (28 total)

**Search Tools**:
- `tw` (tabiew) - View/query CSV files
- `rg` (ripgrep) - Fast text search
- `rga` (ripgrep-all) - Search in PDFs, DOCX, XLSX, archives, etc. **[Newly added]**
- `fd` - Fast file finder
- `fzf` - Fuzzy finder

**File Tools**:
- `bat` - Cat with syntax highlighting
- `eza` - Modern ls replacement
- `yazi` - Terminal file manager

**Development Tools**:
- `gh` - GitHub CLI
- `jq` - JSON processor (1.7.1, newer than system 1.6)
- `xan` - CSV toolkit

**System Tools**:
- `btop` - Resource monitor
- `dust` - Disk usage analyzer
- `zoxide` - Smart cd command
- `starship` - Cross-shell prompt
- `direnv` - Environment management

**Document/Media Tools**:
- `tectonic` - Modern LaTeX engine
- `poppler` - PDF manipulation
- `resvg` - SVG renderer
- `tldr` - Simplified man pages
- `tailspin` - Log file highlighter

**Compression/Sync Tools**:
- `p7zip` - 7-Zip compression
- `rclone` - Cloud storage sync (1.71.0, newer than system 1.70.3)
- `parallel` - GNU parallel execution
- `stow` - Symlink farm manager

**Shell**:
- `zsh` - Z shell

### Usage Examples

```bash
# Search inside PDF files
~/.local/bin/wrds-tools rga "regression analysis" report.pdf

# Search in compressed archives
~/.local/bin/wrds-tools rga "import pandas" project.tar.gz

# Find Python files modified in last 7 days
~/.local/bin/wrds-tools fd -e py -t f --changed-within 7d

# View CSV with interactive query interface
~/.local/bin/wrds-tools tw data.csv

# Monitor system resources
~/.local/bin/wrds-tools btop

# Analyze disk usage
~/.local/bin/wrds-tools dust -d 2 ~
```

### Adding New Tools

1. Add package to `devshell.toml`:
   ```toml
   [[commands]]
   package = "tool-name"
   name = "alias"  # optional
   help = "Description"
   category = "category-name"
   ```

2. Rebuild and deploy:
   ```bash
   ./build.sh
   ./deploy.sh
   ```

3. Test with login shell:
   ```bash
   ssh wrds "bash -l -c '~/.local/bin/wrds-tools tool-name --version'"
   ```

### Disk Space Management on WRDS

WRDS has a **10GB home directory quota**. Monitor usage:

```bash
ssh wrds "~/.local/bin/wrds-tools dust -r -d 2 ~"
```

**Large directories to watch**:
- `~/.nix-portable/` - nix-portable cache (can grow to 2-3GB)
- `~/.local/wrds-data-science/` - Data science environment (~200MB)
- `~/.local/bin/wrds-tools` - CLI tools (~664MB)
- `~/.npm/_cacache/` - npm cache (can be removed)

**Safe to remove**:
- Old `wrds-data-science-*` directories
- `~/.npm/_cacache/`
- `~/.cache/` subdirectories

### Integration with Emacs/Org-Babel

The data science environment includes:
- `euporie` 2.8.13 - Enhanced Jupyter console
- `sas_kernel` - SAS kernel for Jupyter
- `jupyter` - Standard Jupyter console/notebook
- Python 3.13.7

Access via:
```bash
source ~/.local/wrds-data-science/bin/activate
euporie console --kernel-name=python3
euporie console --kernel-name=sas
```

### References

- **nix-portable**: https://github.com/DavHau/nix-portable
- **bwrap vs proot**: bwrap requires user namespaces, proot uses ptrace
- **WRDS**: Wharton Research Data Services (wrds-www.wharton.upenn.edu)

### Troubleshooting Checklist

- [ ] Built on correct architecture (x86_64-linux)?
- [ ] Deployed with `./deploy.sh`?
- [ ] `NP_RUNTIME=proot` set in `~/.shell_env`?
- [ ] Testing with `bash -l -c` (login shell)?
- [ ] Using `~/.local/bin/wrds-tools` wrapper (not direct command)?
- [ ] Enough disk space on WRDS (check with `dust`)?
- [ ] Tools work with manual `NP_RUNTIME=proot` override?

If all checklist items pass and tools still fail, check WRDS system status or contact support.
