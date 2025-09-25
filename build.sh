#!/usr/bin/env bash
set -e

echo "🚀 Building WRDS portable environments..."

# Build Nix DevShell Bundle
echo ""
echo "1️⃣ Building CLI tools bundle..."

# Note: This requires building from a Linux system or using remote builders
# On macOS, you may need to use a remote Linux builder or Docker

# Check if we're on Linux and detect architecture
if [[ $(uname) == "Linux" ]]; then
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            SYSTEM="x86_64-linux"
            ;;
        aarch64)
            SYSTEM="aarch64-linux"
            ;;
        *)
            echo "Warning: Unsupported architecture $ARCH, defaulting to x86_64-linux"
            SYSTEM="x86_64-linux"
            ;;
    esac
    TARGET_SHELL=".#devShells.$SYSTEM.default"
else
    echo "Warning: Building from non-Linux system. This may require remote builders."
    SYSTEM="x86_64-linux"
    TARGET_SHELL="github:edwinhu/wrds-devshell#devShells.x86_64-linux.default"
fi

echo "Target system: $SYSTEM"
echo "Target shell: $TARGET_SHELL"

# Build the bundle using nix-portable bundler
if [[ $(uname) == "Linux" ]]; then
    # Build directly on Linux
    nix bundle --bundler github:DavHau/nix-portable \
        -o wrds-devshell \
        "$TARGET_SHELL"
else
    # Build using x86_64 Lima VM on macOS
    echo "Building in x86_64 Lima VM..."

    # Ensure x86_64 Lima VM exists and is running
    if ! limactl list nix-x86_64-builder 2>/dev/null | grep -q "nix-x86_64-builder"; then
        echo "Creating x86_64 Lima VM..."
        limactl create --name nix-x86_64-builder nix-x86_64-builder.yaml
    fi

    if ! limactl list nix-x86_64-builder 2>/dev/null | grep -q "Running"; then
        echo "Starting x86_64 Lima VM..."
        limactl start nix-x86_64-builder
    fi

    # Build in the mounted directory (already has files)
    limactl shell nix-x86_64-builder -- bash -c "
        cd /Users/vwh7mb/projects/wrds-devshell &&
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh &&
        nix bundle --bundler github:DavHau/nix-portable .#devShells.x86_64-linux.default -o wrds-devshell-x86_64 &&
        ACTUAL_PATH=\$(readlink -f wrds-devshell-x86_64) &&
        cp \$ACTUAL_PATH/bin/wrds-tools ./wrds-devshell.portable &&
        chmod +x ./wrds-devshell.portable
    "

    # Copy result back to host (file already exists in mounted directory)
    if [[ -f wrds-devshell.portable ]]; then
        echo "✅ Found wrds-devshell.portable, no need to copy"
    else
        echo "❌ wrds-devshell.portable not created by Lima VM"
        exit 1
    fi
    echo "✅ x86_64 Lima build complete"
fi

# The executable is already created by the Lima VM build process
if [[ ! -f wrds-devshell.portable ]]; then
    echo "Error: wrds-devshell.portable not found after build"
    echo "Checking build artifacts..."
    ls -la wrds-devshell* 2>/dev/null || echo "No build artifacts found"
    exit 1
fi

chmod +x ./wrds-devshell.portable

echo "✅ CLI tools bundle created: wrds-devshell.portable"
echo "📦 Size: $(du -sh wrds-devshell.portable | cut -f1)"

# Build Pixi Data Science Environment
echo ""
echo "2️⃣ Building data science environment..."

# Check if pixi.toml exists
if [[ ! -f "pixi.toml" ]]; then
    echo "❌ pixi.toml not found in current directory"
    exit 1
fi

# Pack the data science environment
pixi-pack --platform linux-64 --create-executable

# Check if the packed environment was created
if [[ -f "environment.sh" ]]; then
    echo "✅ Data science environment created: environment.sh"
    echo "📦 Size: $(du -sh environment.sh | cut -f1)"
else
    echo "❌ Failed to create data science environment"
    exit 1
fi

echo ""
echo "🎉 Build complete!"
echo "📂 Created files:"
echo "   • wrds-devshell.portable (CLI tools)"
echo "   • environment.sh (data science)"
echo ""
echo "Deploy with: ./deploy.sh"