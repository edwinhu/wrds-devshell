#!/usr/bin/env bash
set -e

echo "🚀 Building WRDS portable environments..."

# Build Nix DevShell Bundle
echo ""
echo "1️⃣ Building CLI tools bundle..."

# Note: This requires building from a Linux system or using remote builders
# On macOS, you may need to use a remote Linux builder or Docker

# Check if we're on Linux
if [[ $(uname) == "Linux" ]]; then
    SYSTEM="x86_64-linux"
    TARGET_SHELL=".#devShells.x86_64-linux.default"
else
    echo "Warning: Building from non-Linux system. This may require remote builders."
    SYSTEM="x86_64-linux"
    TARGET_SHELL="github:edwinhu/wrds-devshell#devShells.x86_64-linux.default"
fi

echo "Target system: $SYSTEM"
echo "Target shell: $TARGET_SHELL"

# Build the bundle using nix-portable bundler
nix bundle --bundler github:DavHau/nix-portable \
    -o wrds-devshell \
    "$TARGET_SHELL"

# Make it properly executable
if [[ -f wrds-devshell/bin/wrds-devshell ]]; then
    cp ./wrds-devshell/bin/wrds-devshell ./wrds-devshell.portable
elif [[ -f wrds-devshell ]]; then
    cp ./wrds-devshell ./wrds-devshell.portable
else
    echo "Error: Could not find built executable"
    find wrds-devshell -type f -executable 2>/dev/null || echo "No executable files found"
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