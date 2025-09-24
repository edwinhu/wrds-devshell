#!/usr/bin/env bash
set -e

# Build the bundle
./build.sh

# Upload to WRDS
echo "Uploading bundle to WRDS..."
rclone copy wrds-devshell.portable wrds:bin/

# Make executable on WRDS
ssh wrds 'chmod +x ~/bin/wrds-devshell.portable'

# Create symlink for easier access
ssh wrds 'ln -sf ~/bin/wrds-devshell.portable ~/bin/wrds-tools'

# Update shell config to add to PATH
ssh wrds 'mkdir -p ~/bin && grep -q "~/bin" ~/.bashrc || echo "export PATH=\$HOME/bin:\$PATH" >> ~/.bashrc'

echo "✅ Deployment complete!"
echo ""
echo "On WRDS, you can now:"
echo "  - Enter devshell: ~/bin/wrds-tools"
echo "  - Or use alias: ~/bin/wrds-devshell.portable"
echo "  - Run individual tools: ~/bin/wrds-tools --run tw file.csv"
echo ""
echo "Tools available: tw, bat, rg, fd, fzf, xan, eza, zoxide, jq, dust, btop, yazi"