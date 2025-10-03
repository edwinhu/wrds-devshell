#!/usr/bin/env bash
set -e

CLI_BUNDLE="wrds-devshell.portable"
DS_BUNDLE="environment.sh"
REMOTE_HOST="wrds"

echo "🚀 Deploying WRDS development environments to $REMOTE_HOST..."

# --- 1. Check for Artifacts ---
if [[ ! -f "$CLI_BUNDLE" || ! -f "$DS_BUNDLE" ]]; then
    echo "❌ Build artifacts not found. Run ./build.sh first."
    exit 1
fi

echo "📦 Using build artifacts:"
ls -lh "$CLI_BUNDLE" "$DS_BUNDLE"

# --- 2. Upload Artifacts ---
echo ""
echo "📤 Uploading to $REMOTE_HOST..."
# Use rclone for efficient file transfer.
rclone copy "$CLI_BUNDLE" "$REMOTE_HOST":
rclone copy "$DS_BUNDLE" "$REMOTE_HOST":

# --- 3. Install on Remote ---
echo ""
echo "⚙️  Installing on $REMOTE_HOST..."

# Combine all remote commands into a single SSH session for efficiency.
ssh "$REMOTE_HOST" '
    set -e # Ensure remote script also exits on error

    echo "Installing CLI tools..."
    mkdir -p ~/.local/bin
    mv -f wrds-devshell.portable ~/.local/bin/wrds-tools
    chmod +x ~/.local/bin/wrds-tools
    echo "✅ CLI tools installed to ~/.local/bin/wrds-tools"

    echo "Installing data science environment..."
    # Only install if not already present
    if [ ! -d ~/.local/wrds-data-science ]; then
        bash environment.sh --output-directory ~/.local --env-name wrds-data-science
        echo "✅ Data science environment installed."
    else
        echo "✅ Data science environment already exists, skipping installation."
    fi

    # Add data science tools to PATH if not already there
    if ! grep -q "wrds-data-science/bin" ~/.shell_env 2>/dev/null; then
        echo "" >> ~/.shell_env
        echo "# Added by wrds-devshell deployment" >> ~/.shell_env
        echo "export PATH=\"\$HOME/.local/wrds-data-science/bin:\$PATH\"" >> ~/.shell_env
        echo "✅ PATH configured in ~/.shell_env"
    fi

    # Clean up uploaded installer
    rm -f environment.sh
'

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🖥️  On WRDS, reload your shell and you can now use the tools."
