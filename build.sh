#!/usr/bin/env bash
set -e

# --- Configuration ---
# Define a single target system for consistent, portable builds.
TARGET_SYSTEM="x86_64-linux"
TARGET_SHELL_ATTR=".#devShells.$TARGET_SYSTEM.default"
CLI_OUTPUT_FILE="wrds-devshell.portable"
DATA_SCIENCE_OUTPUT_FILE="environment.sh"

echo "🚀 Building WRDS portable environments for $TARGET_SYSTEM..."

# --- 1. Build Nix DevShell Bundle ---
echo ""
echo "1️⃣ Building CLI tools bundle..."

# The build command produces a result symlink that we need to extract
NIX_BUNDLE_CMD="nix bundle --bundler github:DavHau/nix-portable '$TARGET_SHELL_ATTR'"

# On macOS, we need a Linux builder (Lima). On Linux, we can build directly.
if [[ "$(uname)" == "Darwin" ]]; then
    echo "macOS detected. Building in x86_64 Lima VM..."

    # Ensure Lima VM is running
    if ! limactl list nix-x86_64-builder --json | grep '"status":"Running"'; then
        echo "Starting x86_64 Lima VM..."
        limactl start nix-x86_64-builder || {
            echo "Lima VM not found. Creating it..."
            limactl create --name nix-x86_64-builder nix-x86_64-builder.yaml && \
            limactl start nix-x86_64-builder
        }
    fi

    # Execute the simplified build command in the VM.
    # It works directly on the mounted project directory.
    limactl shell nix-x86_64-builder bash -c "
        cd $(pwd) &&
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh &&
        $NIX_BUNDLE_CMD
    "
else
    echo "Linux detected. Building directly..."
    eval "$NIX_BUNDLE_CMD"
fi

# --- Verification and Extraction ---
# nix bundle creates a 'result' symlink to the store path
if [[ -L "result" ]]; then
    # Find the executable in the result
    ACTUAL_PATH=$(readlink -f result)
    if [[ -f "$ACTUAL_PATH/bin/wrds-tools" ]]; then
        cp "$ACTUAL_PATH/bin/wrds-tools" "$CLI_OUTPUT_FILE"
        chmod +x "$CLI_OUTPUT_FILE"
        rm -f result
        echo "✅ CLI tools bundle created: $CLI_OUTPUT_FILE"
        echo "📦 Size: $(du -sh $CLI_OUTPUT_FILE | cut -f1)"
    else
        echo "❌ Build failed: wrds-tools executable not found in result"
        ls -la "$ACTUAL_PATH"
        exit 1
    fi
else
    echo "❌ Build failed: result symlink not created"
    exit 1
fi


# --- 2. Build Pixi Data Science Environment ---
echo ""
echo "2️⃣ Building data science environment..."

if [[ ! -f "pixi.toml" ]]; then
    echo "❌ pixi.toml not found."
    exit 1
fi

pixi-pack --platform linux-64 --create-executable

if [[ ! -f "$DATA_SCIENCE_OUTPUT_FILE" ]]; then
    echo "❌ Failed to create data science environment."
    exit 1
fi

echo "✅ Data science environment created: $DATA_SCIENCE_OUTPUT_FILE"
echo "📦 Size: $(du -sh $DATA_SCIENCE_OUTPUT_FILE | cut -f1)"


# --- Summary ---
echo ""
echo "🎉 Build complete!"
echo "📂 Created files:"
echo "   • $CLI_OUTPUT_FILE (CLI tools)"
echo "   • $DATA_SCIENCE_OUTPUT_FILE (data science)"
echo ""
echo "Deploy with: ./deploy.sh"
