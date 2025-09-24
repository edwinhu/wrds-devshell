#!/usr/bin/env bash
set -e

echo "🚀 Deploying WRDS development environments..."

# Build both environments
echo "📦 Building environments..."
./build.sh

echo ""
echo "📤 Uploading to WRDS..."

# Upload CLI tools bundle
echo "Uploading CLI tools bundle..."
cat wrds-devshell.portable | ssh wrds "cat > wrds-devshell.portable"

# Upload data science environment
echo "Uploading data science environment..."
cat environment.sh | ssh wrds "cat > environment.sh"

echo ""
echo "⚙️  Installing on WRDS..."

# Install CLI tools to ~/.local/bin
echo "Installing CLI tools..."
ssh wrds '
mkdir -p ~/.local/bin
mv wrds-devshell.portable ~/.local/bin/wrds-tools
chmod +x ~/.local/bin/wrds-tools

# Ensure ~/.local/bin is in PATH
grep -q "~/.local/bin" ~/.bash_profile 2>/dev/null || echo "export PATH=~/.local/bin:\$PATH" >> ~/.bash_profile
'

# Install data science environment to ~/.local
echo "Installing data science environment..."
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
ln -sf ~/.local/wrds-data-science/bin/zsh ~/.local/bin/zsh

# Ensure ~/.local/bin is in PATH for all sessions
grep -q "~/.local/bin" ~/.bash_profile || echo "export PATH=~/.local/bin:\$PATH" >> ~/.bash_profile
'

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🖥️  On WRDS, you can now use:"
echo ""
echo "🛠️  CLI Tools (directly in PATH):"
echo "   wrds-tools                   # Enter devshell with all tools"
echo "   wrds-tools tw file.csv       # Run tabiew on a file"
echo "   tw file.csv                  # Direct access (after PATH reload)"
echo "   rg \"pattern\" .              # Search text files"
echo "   fd filename                  # Find files"
echo ""
echo "📊 Data Science (directly in PATH):"
echo "   euporie console              # Jupyter console with SAS kernel"
echo "   euporie notebook             # Jupyter notebook interface"
echo "   python-wrds                  # Python with all dependencies"
echo ""
echo "Or activate full conda environment:"
echo "   source ~/.local/bin/activate-wrds-data-science"
echo ""
echo "📏 Deployed sizes:"
echo "   CLI tools: $(du -sh wrds-devshell.portable | cut -f1)"
echo "   Data science: $(du -sh environment.sh | cut -f1)"