#!/usr/bin/env bash
set -e

echo "🚀 Deploying WRDS data science environment only..."

# Check if environment.sh exists
if [[ ! -f "environment.sh" ]]; then
    echo "📦 Building data science environment..."
    pixi-pack --platform linux-64 --create-executable
fi

echo ""
echo "📤 Uploading to WRDS..."

# Upload data science environment
echo "Uploading data science environment..."
rclone copy environment.sh wrds:

echo ""
echo "⚙️  Installing on WRDS..."

# Install data science environment to ~/.local/bin
ssh wrds 'mkdir -p ~/.local && bash environment.sh --output-directory ~/.local --env-name wrds-data-science'

# Create activation script and symlinks in ~/.local/bin
ssh wrds '
mkdir -p ~/.local/bin
echo "export PATH=\"~/.local/wrds-data-science/bin:\${PATH}\"" > ~/.local/bin/activate-wrds-data-science
echo "export CONDA_SHLVL=1" >> ~/.local/bin/activate-wrds-data-science
echo "export CONDA_PREFIX=~/.local/wrds-data-science" >> ~/.local/bin/activate-wrds-data-science
chmod +x ~/.local/bin/activate-wrds-data-science

# Create direct symlinks for key tools
ln -sf ~/.local/wrds-data-science/bin/euporie ~/.local/bin/euporie
ln -sf ~/.local/wrds-data-science/bin/python ~/.local/bin/python-wrds

# Ensure ~/.local/bin is in PATH for all sessions
grep -q "~/.local/bin" ~/.bash_profile || echo "export PATH=~/.local/bin:\$PATH" >> ~/.bash_profile
'

echo ""
echo "✅ Data science deployment complete!"
echo ""
echo "📊 On WRDS, you can now use:"
echo "   euporie console              # Jupyter console with SAS kernel (directly in PATH)"
echo "   euporie notebook             # Jupyter notebook interface"
echo "   python-wrds                  # Python with all dependencies"
echo ""
echo "Or activate full environment:"
echo "   source ~/.local/bin/activate-wrds-data-science  # Full conda environment"
echo ""
echo "Size deployed: $(du -sh environment.sh | cut -f1)"