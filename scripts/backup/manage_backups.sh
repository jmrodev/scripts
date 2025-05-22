#!/bin/bash

# Main backup directory
MAIN_BACKUP_DIR="~/system_backups"
PACKAGES_BACKUP_DIR="$MAIN_BACKUP_DIR/packages"
CONFIGS_BACKUP_DIR="$MAIN_BACKUP_DIR/configs"

# Ensure backup directories exist
mkdir -p "$PACKAGES_BACKUP_DIR"
mkdir -p "$CONFIGS_BACKUP_DIR"

# Function to backup official packages
backup_official_packages() {
    echo "Backing up official packages..."
    pacman -Qqen > "$PACKAGES_BACKUP_DIR/official_packages.txt"
    echo "Official packages backup complete."
}

# Function to restore official packages
restore_official_packages() {
    echo "Restoring official packages..."
    if [ -f "$PACKAGES_BACKUP_DIR/official_packages.txt" ]; then
        sudo pacman -S --needed --noconfirm - < "$PACKAGES_BACKUP_DIR/official_packages.txt"
        echo "Official packages restoration complete."
    else
        echo "Error: Official packages backup file not found."
    fi
}

# Function to backup AUR packages
backup_aur_packages() {
    echo "Backing up AUR packages..."
    pacman -Qqem > "$PACKAGES_BACKUP_DIR/aur_packages.txt"
    echo "AUR packages backup complete."
}

# Function to restore AUR packages
restore_aur_packages() {
    echo "Restoring AUR packages..."
    if [ -f "$PACKAGES_BACKUP_DIR/aur_packages.txt" ]; then
        yay -S --needed --noconfirm - < "$PACKAGES_BACKUP_DIR/aur_packages.txt"
        echo "AUR packages restoration complete."
    else
        echo "Error: AUR packages backup file not found."
    fi
}

# Function to backup configuration files
backup_configs() {
    echo "Backing up configuration files..."
    # Define files and directories to backup
    local backup_items=(
        "$HOME/.config"
        "$HOME/.local/share"
        "$HOME/.bashrc"
        "$HOME/.zshrc"
        "$HOME/.profile"
        "$HOME/.bash_profile"
        "$HOME/.gitconfig"
    )
    
    for item in "${backup_items[@]}"; do
        if [ -e "$item" ]; then
            echo "Backing up $item to $CONFIGS_BACKUP_DIR/"
            cp -R "$item" "$CONFIGS_BACKUP_DIR/"
        else
            echo "Warning: $item does not exist, skipping."
        fi
    done
    echo "Configuration files backup complete."
}

# Function to restore configuration files
restore_configs() {
    echo "Restoring configuration files..."
    if [ -d "$CONFIGS_BACKUP_DIR" ]; then
        echo "Copying files from $CONFIGS_BACKUP_DIR to $HOME/"
        # This is a simple restore, might need more sophisticated handling for conflicts
        cp -R "$CONFIGS_BACKUP_DIR/." "$HOME/"
        echo "Configuration files restoration complete."
        echo "Note: You may need to restart your session or source profile files for changes to take effect."
    else
        echo "Error: Configs backup directory not found."
    fi
}

# Main menu
show_menu() {
    echo "Backup and Restore Management Script"
    echo "------------------------------------"
    echo "1. Backup Official Packages"
    echo "2. Restore Official Packages"
    echo "3. Backup AUR Packages"
    echo "4. Restore AUR Packages"
    echo "5. Backup Configuration Files"
    echo "6. Restore Configuration Files"
    echo "7. Exit"
    echo "------------------------------------"
    read -p "Enter your choice: " choice
}

# Main script logic
while true; do
    show_menu
    case $choice in
        1) backup_official_packages ;;
        2) restore_official_packages ;;
        3) backup_aur_packages ;;
        4) restore_aur_packages ;;
        5) backup_configs ;;
        6) restore_configs ;;
        7) echo "Exiting."; exit 0 ;;
        *) echo "Invalid choice. Please try again." ;;
    esac
    echo "" # Add a newline for better readability
done
