#!/usr/bin/env bash
set -e

echo "🔬 Setting up WRDS Data Science Environment..."

# Check if pixi.toml exists
if [[ ! -f "pixi.toml" ]]; then
    echo "❌ pixi.toml not found in current directory"
    echo "Make sure you're running this from the wrds-devshell directory"
    exit 1
fi

# Install the pixi environment
echo "📦 Installing data science packages..."
pixi install

# Pack the environment
echo "🎁 Packing data science environment..."
pixi run pack

# Check if the packed environment was created
if [[ -f "environment.sh" ]]; then
    echo "✅ Data science environment packed successfully!"
    echo "📂 Created: environment.sh"
    echo ""
    echo "To deploy to WRDS:"
    echo "  rclone copy environment.sh wrds:"
    echo "  ssh wrds 'bash environment.sh'"
    echo ""
    echo "On WRDS, you can then:"
    echo "  euporie console  # Start Jupyter console with SAS kernel"
    echo "  euporie notebook # Start Jupyter notebook interface"
else
    echo "❌ Failed to create packed environment"
    exit 1
fi