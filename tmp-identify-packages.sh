#!/bin/bash
# Debug: identify packages that pull conflicting Node LTS providers
echo -e "${BLUE}>>> Checking AUR package deps for Node LTS conflicts...${NC}"
AUR_PKGS=(
  vicinae-git
  mailspring
  1password
  1password-cli
  android-studio
  balena-etcher
  bambustudio-bin
  beekeeper-studio-bin
  calibre
  filezilla
  freecad
  google-chrome
  local-by-flywheel-bin
  phpstorm
  postman-bin
  proton-mail-bin
  proton-vpn-applet
  slack-desktop
  tailscale
  visual-studio-code-bin
  whatsapp-for-linux
  vial-appimage
  qmk
)

# `yay -Si` is metadata-only; it won't install anything.
# If any package has an explicit dep on nodejs-lts-iron/jod, it should show up here.
yay -Si "${AUR_PKGS[@]}" 2>/dev/null | grep -nE '^(Name|Depends On|Make Deps|Check Deps|Optional Deps)\s*:' | grep -nE 'nodejs-lts-(iron|jod)|\bnodejs\b' || true
