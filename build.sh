#!/usr/bin/env bash
set -e

echo "Building portable WRDS devshell bundle..."

# Build the bundle using nix-portable bundler for Linux target
nix bundle --bundler github:DavHau/nix-portable \
    --system x86_64-linux \
    -o wrds-devshell \
    .#devShells.x86_64-linux.default

# Make it properly executable
cp ./wrds-devshell/bin/wrds-devshell ./wrds-devshell.portable
chmod +x ./wrds-devshell.portable

echo "Bundle created: wrds-devshell.portable"
echo "Size: $(du -sh wrds-devshell.portable | cut -f1)"