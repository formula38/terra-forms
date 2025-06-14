#!/bin/bash

set -e

echo "📦 Installing coldchainctl CLI (symlink method)..."

chmod +x ./coldchainctl

# Remove old symlink if exists
sudo rm -f /usr/local/bin/coldchainctl

# Symlink the CLI to /usr/local/bin
sudo ln -s "$(pwd)/coldchainctl" /usr/local/bin/coldchainctl

echo "✅ Installed! You can now run:"
echo
echo "    coldchainctl help"
echo

