#!/bin/bash

# Install Homebrew
echo "Installing Homebrew..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"

# Add Homebrew to PATH
echo "Adding Homebrew to PATH..."
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install base development tools
echo "Installing base development tools..."
sudo pacman -S --noconfirm base-devel

# Install GCC
echo "Installing GCC..."
brew install gcc

# Verify installation
echo "Verifying Homebrew installation..."
brew help

echo "Homebrew installation and setup complete!"
