#!/bin/bash
# Omarchy Gaming & Productivity Extension Script
# -----------------------------------------------------------------------------
# This script extends the base Omarchy install to support a full gaming suite
# (Heroic, NonSteamLaunchers) and replaces the launcher with Vicinae.

set -e  # Exit on error

# --- Helper Functions ---
log() {
    echo -e "\033[0;32m[OMARCHY]\033[0m $1"
}

# --- 1. Gaming Setup ---
setup_gaming() {
    log "Initializing Gaming Subsystem..."

    # 1.1 Enable Multilib (Required for Steam/Wine)
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        log "Enabling multilib repository..."
        sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
        sudo pacman -Syu --noconfirm
    fi

    # 1.2 Install Heroic Games Launcher (For Epic, GOG, Amazon)
    # Using 'bin' package from AUR to avoid long compilation times
    if ! pacman -Qs heroic-games-launcher-bin > /dev/null; then
        log "Installing Heroic Games Launcher..."
        yay -S --noconfirm heroic-games-launcher-bin
    else
        log "Heroic Games Launcher already installed."
    fi

    # 1.3 Install NonSteamLaunchers (For EA, Ubisoft, Battle.net)
    # Using headless mode to install specific launchers directly to Steam
    log "Deploying Proprietary Launchers via NonSteamLaunchers..."

    # List of launchers to install + Proton-GE update
    # Arguments derived from documentation: "EA App", "Ubisoft Connect", "Battle.net"
    LAUNCHERS=("EA App" "Ubisoft Connect" "Battle.net" "Update Proton-GE")

    # Construct argument string for the bash command with quotes to handle spaces
    LAUNCHER_ARGS=""
    for launcher in "${LAUNCHERS[@]}"; do
        LAUNCHER_ARGS="$LAUNCHER_ARGS \"$launcher\""
    done

    log "Installing Launchers and Updating Proton-GE..."
    # Pipe curl to bash with arguments for automated install
    # We use /bin/bash -c to execute the pipeline and pass all arguments at once
    /bin/bash -c "curl -Ls https://raw.githubusercontent.com/moraroy/NonSteamLaunchers-On-Steam-Deck/main/NonSteamLaunchers.sh | nohup /bin/bash -s -- $LAUNCHER_ARGS"

    # 1.5 Install Gaming Optimization Tools
    # Gamescope: Micro-compositor for resolution scaling/isolation
    # Gamemode: CPU governor optimization daemon
    log "Installing Gamescope and Gamemode..."
    sudo pacman -S --noconfirm gamescope gamemode lib32-gamemode
}

# --- 2. Productivity & Vicinae Setup ---
setup_productivity() {
    log "Initializing Productivity Subsystem..."

    # 2.1 Install Vicinae (Raycast Alternative)
    if ! pacman -Qs vicinae-git > /dev/null; then
        log "Installing Vicinae..."
        yay -S --noconfirm vicinae-git
    fi

    # 2.2 Configure Vicinae Directory Structure
    mkdir -p "$HOME/.config/vicinae"

    # Generate default config if it doesn't exist (Critical for v0.17+ schema)
    if [ ! -f "$HOME/.config/vicinae/settings.json" ]; then
        log "Generating default Vicinae configuration..."
        # Note: Vicinae server must be running to generate config via CLI,
        # or we manually write a basic valid JSON structure.
        cat <<EOF > "$HOME/.config/vicinae/settings.json"
{
    "general": {
        "autostart": true,
        "theme": "default-dark"
    },
    "extensions": {
        "enabled": true,
        "sources": [
            { "type": "raycast_store", "enabled": true }
        ]
    },
    "keybindings": {
        "toggle": "Super+Space"
    }
}
EOF
    fi

    # 2.3 Configure Ghostty to use Zsh
    # We do NOT change the system shell to avoid breaking Omarchy scripts.
    log "Configuring Ghostty to use Zsh..."
    mkdir -p "$HOME/.config/ghostty"
    GHOSTTY_CONFIG="$HOME/.config/ghostty/config"
    touch "$GHOSTTY_CONFIG"

    # Check if config exists, append if not present (checking individually to prevent duplicates)
    if ! grep -q "^command = /usr/bin/zsh" "$GHOSTTY_CONFIG"; then
        echo "command = /usr/bin/zsh" >> "$GHOSTTY_CONFIG"
    fi

    if ! grep -q '^font-family = "JetBrainsMono Nerd Font"' "$GHOSTTY_CONFIG"; then
        echo 'font-family = "JetBrainsMono Nerd Font"' >> "$GHOSTTY_CONFIG"
    fi

    # 2.4 Zsh Configuration (Starship + FZF)
    log "Configuring Zsh environment..."

    # Ensure .zshrc exists
    touch "$HOME/.zshrc"

    # Ensure Starship init is present
    if ! grep -q "starship init zsh" "$HOME/.zshrc"; then
        echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
    fi
    # Ensure FZF init is present
    if ! grep -q "fzf --zsh" "$HOME/.zshrc"; then
        echo 'source <(fzf --zsh)' >> "$HOME/.zshrc"
    fi
}

# --- Execution ---
setup_gaming
# setup_productivity
log "Setup Complete. Please restart Hyprland (Super+M usually) or reboot."
