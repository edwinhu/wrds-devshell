#!/usr/bin/env bash
set -e

echo "🚀 Deploying WRDS development environments..."

# Check if build artifacts exist and are recent
if [[ -f "wrds-devshell.portable" && -f "environment.sh" ]]; then
    echo "📦 Using existing build artifacts..."
    echo "   • CLI tools: $(ls -lh wrds-devshell.portable | awk '{print $5}') ($(date -r wrds-devshell.portable +'%Y-%m-%d %H:%M'))"
    echo "   • Data science: $(ls -lh environment.sh | awk '{print $5}') ($(date -r environment.sh +'%Y-%m-%d %H:%M'))"
else
    echo "📦 Building environments..."
    ./build.sh
fi

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
cp wrds-devshell.portable ~/.local/bin/wrds-tools
chmod +x ~/.local/bin/wrds-tools
rm -f wrds-devshell.portable

echo "✅ CLI tools bundle installed to ~/.local/bin/wrds-tools"
'

# Install data science environment to ~/.local
echo "Installing data science environment..."
ssh wrds '
# Only install if not already present
if [ ! -d ~/.local/wrds-data-science ]; then
    mkdir -p ~/.local && bash environment.sh --output-directory ~/.local --env-name wrds-data-science
    echo "✅ Data science environment installed"
else
    echo "✅ Data science environment already exists"
fi

# Create/update symlinks for key tools
mkdir -p ~/.local/bin
ln -sf ~/.local/wrds-data-science/bin/euporie ~/.local/bin/euporie 2>/dev/null || true
ln -sf ~/.local/wrds-data-science/bin/python ~/.local/bin/python-wrds 2>/dev/null || true

# Clean up uploaded file
rm -f environment.sh

echo "✅ Data science tools configured"
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