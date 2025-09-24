#!/usr/bin/env bash
set -e

echo "🚀 Deploying WRDS environments..."

# Build both environments
./build.sh

echo ""
echo "📤 Uploading to WRDS..."

# Upload CLI tools bundle
echo "Uploading CLI tools bundle..."
rclone copy wrds-devshell.portable wrds:.local/bin/

# Upload data science environment
echo "Uploading data science environment..."
rclone copy environment.sh wrds:

echo ""
echo "⚙️  Setting up on WRDS..."

# Make CLI tools executable and create symlink
ssh wrds 'mkdir -p ~/.local/bin && chmod +x ~/.local/bin/wrds-devshell.portable && ln -sf ~/.local/bin/wrds-devshell.portable ~/.local/bin/wrds-tools'

# Install data science environment
ssh wrds 'bash environment.sh'

echo ""
echo "✅ Deployment complete!"
echo ""
echo "On WRDS, you can now use:"
echo ""
echo "🛠️  CLI Tools:"
echo "   wrds-tools                        # Enter devshell with all tools"
echo "   wrds-tools --run tw file.csv      # Run individual tools"
echo ""
echo "📊 Data Science:"
echo "   euporie console     # Jupyter console with SAS kernel"
echo "   euporie notebook    # Jupyter notebook interface"
echo "   python              # Python with all dependencies"
echo ""
echo "Available CLI tools: tw, bat, rg, fd, fzf, xan, eza, zoxide, jq, dust, btop, yazi, pixi, and more!"