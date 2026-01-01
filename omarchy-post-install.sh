#!/bin/bash
# Omarchy 3.2 Optimized Post-Install Script
# Focus: Dev Tools, Vicinae (Raycast), Starship+FZF, Zsh (Safe Mode)

set -e

# Visual feedback colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Node.js LTS selection (avoid nodejs-lts-* conflicts) ---
# Arch allows only one nodejs provider at a time. We normalize to Node 22 LTS.
NODE_LTS_PKG="${NODE_LTS_PKG:-nodejs-lts-jod}"


# We write to /etc/udev/rules.d with a high priority (99)
echo 'KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"' | sudo tee /etc/udev/rules.d/99-vial.rules > /dev/null
sudo udevadm control --reload
sudo udevadm trigger

# 1. Update System & Install Base Devel
echo "Updating system..."
sudo pacman -Syyu --noconfirm
sudo pacman -S --needed --noconfirm base-devel git

# 2. Install YAY (AUR Helper) if not present
if ! command -v yay &> /dev/null; then
    echo "Installing yay..."
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
fi

# 3. CLI tools and runtimes

sudo pacman -S --needed --noconfirm \
    curl unzip tree \
    python python-pip go php composer rubygems jdk-openjdk \
    lua luajit npm \
    ffmpeg imagemagick jq ripgrep fd bat eza procs \
    zip unzip p7zip unrar tar gzip \
    sdl2 sdl2_ttf sdl2_image sdl2_mixer \
    postgresql-libs sqlite \
    bun


# AUR Packages (Proprietary/Specific versions)
yay -S --needed --noconfirm \
    vicinae-git \
    mailspring-bin \
    android-studio \
    bambustudio-bin \
    beekeeper-studio-bin \
    calibre-bin \
    filezilla \
    freecad \
    google-chrome \
    local-by-flywheel-bin \
    phpstorm \
    postman-bin \
    proton-mail-bin \
    slack-desktop \
    tailscale \
    visual-studio-code-bin \
    whatsapp-for-linux \
    vial-appimage \
    qmk

# PHP Configuration (Common fix for Composer/Laravel)
# Uncommenting iconv, gd, zip, sockets in php.ini
echo "Enabling common PHP extensions..."
# Check if file exists to avoid errors
if [ -f /etc/php/php.ini ]; then
    sudo sed -i 's/;extension=iconv/extension=iconv/g' /etc/php/php.ini
    sudo sed -i 's/;extension=gd/extension=gd/g' /etc/php/php.ini
    sudo sed -i 's/;extension=zip/extension=zip/g' /etc/php/php.ini
    sudo sed -i 's/;extension=sockets/extension=sockets/g' /etc/php/php.ini
else
    echo "PHP ini file not found. Skipping PHP extension configuration."
fi

#Keyboard Setup (Vial)
echo "Setting up Vial udev rules..."
# Note: Vial AppImage usually handles this, but manual rules ensure access
echo 'KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0666"' | sudo tee /etc/udev/rules.d/99-vial.rules > /dev/null
sudo udevadm control --reload
sudo udevadm trigger

# 4. GUI Applications (Mapped from applications.txt)
echo "Installing GUI Applications..."

# --------------------------------------------------------------------------
# 4. Shell Architecture: Zsh + Oh My Zsh + Starship + FZF (The Safe Way)
# --------------------------------------------------------------------------
echo -e "${GREEN}>>> Configuring Zsh / Oh My Zsh / Starship...${NC}"

# Ensure Zsh and plugins are installed via Pacman where possible
sudo pacman -S --needed --noconfirm zsh zsh-autosuggestions zsh-syntax-highlighting git curl fzf starship

# Install Oh My Zsh (unattended / idempotent)
# Ref: https://ohmyz.sh/
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
if [ ! -d "$ZSH" ]; then
    echo -e "${GREEN}>>> Installing Oh My Zsh...${NC}"
    # The official installer is interactive by default; we run it in unattended mode,
    # and prevent it from auto-launching Zsh so the rest of this script can continue.
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo -e "${GREEN}>>> Oh My Zsh already installed at $ZSH${NC}"
fi

# Install fzf-tab (The "FZF Support" for Zsh completion) - Not in standard repos
if [ ! -d "$HOME/.local/share/fzf-tab" ]; then
    echo ">>> Cloning fzf-tab..."
    git clone https://github.com/Aloxaf/fzf-tab "$HOME/.local/share/fzf-tab"
fi

# Configure Starship (Nerd Font Preset)
mkdir -p "$HOME/.config"
starship preset nerd-font-symbols -o "$HOME/.config/starship.toml"

# Manage Omarchy Zsh config in a separate file and source it from ~/.zshrc (idempotent)
ZSH_MANAGED_DIR="$HOME/.config/omarchy"
ZSH_MANAGED_FILE="$ZSH_MANAGED_DIR/zshrc.omarchy.zsh"

mkdir -p "$ZSH_MANAGED_DIR"

cat > "$ZSH_MANAGED_FILE" <<'EOF'
# --- Omarchy Managed Zsh Config (Oh My Zsh + Starship) ---

# 0. Oh My Zsh
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME="robbyrussell"

# Keep OMZ light; we source extra plugins manually below.
plugins=(git pacman arch)

# Load Oh My Zsh if present
if [ -f "$ZSH/oh-my-zsh.sh" ]; then
    source "$ZSH/oh-my-zsh.sh"
fi

# 1. Source Omarchy Base Envs (If available)
# This pulls in paths and defaults set by the distro
if [ -f "$HOME/.local/share/omarchy/default/bash/rc" ]; then
    # We scan the bash rc for exports. This is a best-effort integration.
    export PATH="$HOME/.local/share/omarchy/bin:$PATH"
fi

# 2. Plugins (Sourcing directly)
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $HOME/.local/share/fzf-tab/fzf-tab.plugin.zsh

# 3. FZF Initialization (Bindings)
source <(fzf --zsh)

# 4. Starship Init
eval "$(starship init zsh)"

# 5. Configs & Aliases
alias ls='eza --icons'
alias ll='eza -l --icons'
alias cat='bat'
alias vici='vicinae'

# FZF-Tab Configuration (Theming to match Starship/Omarchy)
# Use Omarchy colors (Catppuccin-esque)
zstyle ':fzf-tab:*' fzf-flags --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
EOF

# Ensure ~/.zshrc sources the managed config exactly once (do not overwrite user customizations)
if [ ! -f "$HOME/.zshrc" ]; then
    touch "$HOME/.zshrc"
fi

if ! grep -q 'source "$HOME/.config/omarchy/zshrc.omarchy.zsh"' "$HOME/.zshrc"; then
    cat >> "$HOME/.zshrc" <<'EOF'

# --- Omarchy Managed Config (do not edit generated file; edit your ~/.zshrc instead) ---
if [ -f "$HOME/.config/omarchy/zshrc.omarchy.zsh" ]; then
    source "$HOME/.config/omarchy/zshrc.omarchy.zsh"
fi
EOF
fi

# --------------------------------------------------------------------------
# 5. Terminal Integration (Ghostty)
# --------------------------------------------------------------------------
echo -e "${GREEN}>>> Configuring Ghostty to use Zsh...${NC}"
# CRITICAL: We do NOT run chsh. We tell Ghostty to run Zsh.

mkdir -p "$HOME/.config/ghostty"
GHOSTTY_CONFIG="$HOME/.config/ghostty/config"

if [ ! -f "$GHOSTTY_CONFIG" ]; then
    touch "$GHOSTTY_CONFIG"
fi

# Idempotency check: only add if missing
if ! grep -q "command = /usr/bin/zsh" "$GHOSTTY_CONFIG"; then
    echo "" >> "$GHOSTTY_CONFIG"
    echo "# Launch Zsh instead of default Bash (Omarchy Safe Mode)" >> "$GHOSTTY_CONFIG"
    echo "command = /usr/bin/zsh" >> "$GHOSTTY_CONFIG"
fi

# --------------------------------------------------------------------------
# 6. Vicinae (Raycast) Configuration
# --------------------------------------------------------------------------
echo -e "${GREEN}>>> Configuring Vicinae (Settings & Extensions)...${NC}"
mkdir -p "$HOME/.config/vicinae"

# Vicinae 0.17+ Settings Structure [10, 15]
# Explicitly enabling Raycast extensions and setting the node path
cat > "$HOME/.config/vicinae/settings.json" <<EOF
{
    "general": {
        "start_at_login": true,
        "theme": "system",
        "hotkey": "Super+Space"
    },
    "extensions": {
        "core": {
            "enabled": true
        },
        "vicinae-clipboard": {
            "enabled": true,
            "hotkey": "Super+Shift+V"
        },
        "vicinae-emoji": {
            "enabled": true,
            "hotkey": "Super+."
        },
        "raycast": {
            "enabled": true,
            "compatibility": {
                "node_path": "/usr/bin/node",
                "enable_store": true
            }
        }
    },
    "ui": {
        "corner_radius": 12,
        "width": 750
    }
}
EOF

# Enable User Service for Vicinae (required for background tasks like clipboard)
systemctl --user enable --now vicinae.service

echo -e "${BLUE}>>> Setup Complete.${NC}"
echo -e "    1. Restart your session (Super+Esc -> Logout) to apply group/env changes."
echo -e "    2. IMPORTANT: You must manually edit ~/.config/hypr/hyprland.conf to unbind Walker"
echo -e "       from Super+Space so Vicinae can take over."
