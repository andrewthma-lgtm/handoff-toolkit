#!/bin/bash
# Tailscale: uninstall App Store / GUI app, then install Intel CLI via Homebrew formula.
# Run on your MacBook Pro in Terminal: bash mac-tailscale-uninstall-and-intel-cli.sh

set -euo pipefail

ARCH="$(uname -m)"
echo "==> Detected CPU architecture: ${ARCH}"

if [[ "${ARCH}" != "x86_64" ]]; then
  echo "WARNING: This script installs the Intel (x86_64) Homebrew bottle."
  echo "         Your Mac reports '${ARCH}'. On Apple Silicon, prefer: brew install tailscale"
  read -r -p "Continue anyway? [y/N] " ans
  [[ "${ans}" =~ ^[Yy]$ ]] || exit 1
fi

echo "==> Step 1: Quit Tailscale"
osascript -e 'quit app "Tailscale"' 2>/dev/null || true
pkill -x Tailscale 2>/dev/null || true
sleep 2

echo "==> Step 2: Remove Tailscale.app"
if [[ -d "/Applications/Tailscale.app" ]]; then
  sudo rm -rf "/Applications/Tailscale.app"
  echo "    Removed /Applications/Tailscale.app"
fi

echo "==> Step 3: Remove App Store / GUI leftovers"
PATHS=(
  "$HOME/Library/Application Scripts/io.tailscale.ipn.macos"
  "$HOME/Library/Application Scripts/io.tailscale.ipn.macos.login-item-helper"
  "$HOME/Library/Application Scripts/io.tailscale.ipn.macos.share-extension"
  "$HOME/Library/Application Scripts/io.tailscale.ipn.macsys"
  "$HOME/Library/Caches/io.tailscale.ipn.macos"
  "$HOME/Library/Containers/io.tailscale.ipn.macos"
  "$HOME/Library/Containers/io.tailscale.ipn.macos.login-item-helper"
  "$HOME/Library/Containers/io.tailscale.ipn.macos.network-extension"
  "$HOME/Library/Containers/io.tailscale.ipn.macos.share-extension"
  "$HOME/Library/Containers/Tailscale"
  "$HOME/Library/Group Containers/io.tailscale.ipn.macos"
  "$HOME/Library/HTTPStorages/io.tailscale.ipn.macos"
  "$HOME/Library/Preferences/io.tailscale.ipn.macos.plist"
  "$HOME/Library/Tailscale"
  "/Library/Tailscale"
  "/var/lib/tailscale"
  "/var/run/tailscale"
)
for p in "${PATHS[@]}"; do
  [[ -e "$p" ]] && rm -rf "$p" && echo "    Removed $p"
done

# Broken CLI symlinks from App Store build
for bin in /usr/local/bin/tailscale /opt/homebrew/bin/tailscale; do
  if [[ -L "$bin" ]] || [[ -x "$bin" ]]; then
    sudo rm -f "$bin" 2>/dev/null || rm -f "$bin" 2>/dev/null || true
    echo "    Removed old CLI: $bin"
  fi
done

echo "==> Step 4: Remove VPN configuration (manual if this fails)"
echo "    System Settings > Network > VPN > Tailscale > Remove Configuration"

echo "==> Step 5: Install Homebrew (if missing)"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi
eval "$(brew shellenv)"

echo "==> Step 6: Install Tailscale CLI (formula, not cask)"
brew uninstall --cask tailscale 2>/dev/null || true
brew install tailscale

echo "==> Step 7: Start tailscaled"
sudo brew services start tailscale
sleep 2

echo "==> Step 8: Verify CLI"
which tailscale
file "$(which tailscale)"
tailscale version

echo ""
echo "==> DONE. Reboot recommended, then run:"
echo "    sudo tailscale up"
echo "    tailscale status"
