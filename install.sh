#!/bin/bash
set -euo pipefail

# ==============================================================================
# parrot-clean: i3 desktop installer for Parrot OS with Omarchy themes
# Supports: Parrot OS (Home & Security), Debian-based systems, and Kali Linux
# ==============================================================================

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    echo "[-] Error: Run as your normal user, not root." >&2
    exit 1
fi

DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=true
            ;;
        -h|--help)
            echo "Usage: ./install.sh [--dry-run]"
            echo "Installs parrot-clean i3 desktop environment and Omarchy themes."
            exit 0
            ;;
    esac
done

REPO="$(cd "$(dirname "$0")" && pwd)"

log() {
    echo -e "\033[1;34m[*] $1\033[0m"
}

run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] $*"
    else
        "$@"
    fi
}

# 1. Distro Detection
log "Checking distribution..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    DISTRO_LIKE="${ID_LIKE:-unknown}"
else
    echo "[-] Error: Cannot detect operating system (/etc/os-release missing)." >&2
    exit 1
fi

log "Detected OS: $NAME ($DISTRO_ID, like $DISTRO_LIKE)"
case "$DISTRO_ID" in
    parrot|kali|debian|ubuntu)
        log "Compatible distribution confirmed."
        ;;
    *)
        if [[ "$DISTRO_LIKE" == *"debian"* ]]; then
            log "Debian-derivative detected ($DISTRO_ID). Proceeding..."
        else
            echo "[-] Error: $DISTRO_ID is not a Debian/Parrot-compatible distribution." >&2
            exit 1
        fi
        ;;
esac

# 2. Package installation
log "Updating package lists..."
run_cmd sudo apt-get update

PKGS=(
    wget curl git zsh thunar jq x11-utils unzip fontconfig
    arandr flameshot arc-theme feh i3blocks i3status lxappearance rofi unclutter
    compton papirus-icon-theme imagemagick alacritty
    zsh-autosuggestions zsh-syntax-highlighting fzf
)

# Detect browser package (parrot ships firefox-esr or firefox)
if apt-cache show firefox-esr >/dev/null 2>&1; then
    BROWSER_PKG="firefox-esr"
elif apt-cache show firefox >/dev/null 2>&1; then
    BROWSER_PKG="firefox"
else
    BROWSER_PKG=""
fi
[ -n "$BROWSER_PKG" ] && PKGS+=("$BROWSER_PKG")

# Picom vs Compton: Prefer picom if available in repos
if apt-cache show picom >/dev/null 2>&1; then
    PKGS+=("picom")
fi

log "Installing required packages: ${PKGS[*]}"
run_cmd sudo apt-get install -y "${PKGS[@]}"

# Build dependencies for i3-gaps (if i3 is not already available)
BUILD_DEPS=(
    meson ninja-build autoconf pkg-config
    libxcb1-dev libxcb-shape0-dev libxcb-keysyms1-dev libxcb-util0-dev
    libxcb-icccm4-dev libxcb-xkb-dev libxcb-cursor-dev libxcb-xinerama0-dev
    libxcb-randr0-dev libxcb-xrm-dev libxcb-render-util0-dev libxcb-xfixes0-dev
    libpango1.0-dev libyajl-dev libev-dev libxkbcommon-dev libxkbcommon-x11-dev
    libstartup-notification0-dev
)

if ! command -v i3 >/dev/null 2>&1; then
    log "i3 not found. Installing build dependencies to compile i3-gaps..."
    run_cmd sudo apt-get install -y "${BUILD_DEPS[@]}"
    
    if [ "$DRY_RUN" = false ]; then
        src="$(mktemp -d)"
        git clone --depth 1 https://github.com/Airblader/i3 "$src/i3-gaps"
        mkdir -p "$src/i3-gaps/build"
        (cd "$src/i3-gaps/build" && meson .. && ninja && sudo ninja install)
        rm -rf "$src"
    else
        echo "[DRY-RUN] Would clone and compile i3-gaps from source"
    fi
fi

# 3. Install Geist Mono Font
log "Setting up Geist Mono font..."
if [ "$DRY_RUN" = false ]; then
    mkdir -p ~/.local/share/fonts/GeistMono
    if [ -z "$(ls -A ~/.local/share/fonts/GeistMono 2>/dev/null)" ]; then
        tmp="$(mktemp -d)"
        FONT_URL=""
        if command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
            FONT_URL="$(curl -fsSL https://api.github.com/repos/vercel/geist-font/releases/latest 2>/dev/null | jq -r '.assets[]? | select(.name | test("^geist-font.*\\.zip$")) | .browser_download_url' | head -n 1 || true)"
        fi
        if [ -z "$FONT_URL" ]; then
            FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/GeistMono.zip"
        fi

        if curl -fsSL -o "$tmp/geist.zip" "$FONT_URL" 2>/dev/null || wget -q -O "$tmp/geist.zip" "$FONT_URL"; then
            if [ -f "$tmp/geist.zip" ] && unzip -tq "$tmp/geist.zip" >/dev/null 2>&1; then
                unzip -qo "$tmp/geist.zip" -d "$tmp" || true
                mono_dir="$(find "$tmp" -type d -iname "*GeistMono*" | head -n 1)"
                if [ -n "$mono_dir" ]; then
                    cp -r "$mono_dir/." ~/.local/share/fonts/GeistMono/
                else
                    find "$tmp" -type f \( -name "*.otf" -o -name "*.ttf" \) -exec cp {} ~/.local/share/fonts/GeistMono/ \;
                fi
                fc-cache -f ~/.local/share/fonts || true
                log "Geist Mono font installed."
            else
                log "Warning: Could not verify font archive. Skipping font installation."
            fi
        else
            log "Warning: Font download failed. Skipping font installation."
        fi
        rm -rf "$tmp"
    else
        log "Geist Mono font already installed."
    fi
else
    echo "[DRY-RUN] Would download and install Geist Mono font"
fi

# 4. Deploy User Configuration Files
log "Deploying dotfiles and configs to ~/.config/..."
if [ "$DRY_RUN" = false ]; then
    mkdir -p ~/.config/i3/scripts ~/.config/i3/blocks ~/.cache/i3
    mkdir -p ~/.config/compton ~/.config/picom ~/.config/rofi/themes
    mkdir -p ~/.config/alacritty ~/.config/gtk-3.0
    mkdir -p ~/.config/parrot/templates ~/.local/bin ~/.local/state/parrot

    # Helper to backup before overwriting
    backup_copy() {
        src="$1"
        dest="$2"
        if [ -f "$dest" ] && [ ! -f "${dest}.bak" ]; then
            cp "$dest" "${dest}.bak"
        fi
        cp "$src" "$dest"
    }

    # i3 configs
    backup_copy "$REPO/.config/i3/config" ~/.config/i3/config
    backup_copy "$REPO/.config/i3/i3blocks.conf" ~/.config/i3/i3blocks.conf
    backup_copy "$REPO/.config/i3/clipboard_fix.sh" ~/.config/i3/clipboard_fix.sh
    backup_copy "$REPO/.config/i3/scripts/open-terminal-cwd.sh" ~/.config/i3/scripts/open-terminal-cwd.sh
    mkdir -p ~/.config/i3/blocks
    for f in "$REPO/.config/i3/blocks"/*; do
        [ -f "$f" ] && cp "$f" ~/.config/i3/blocks/
    done
    chmod +x ~/.config/i3/clipboard_fix.sh ~/.config/i3/scripts/* ~/.config/i3/blocks/*

    # Compositor & App configs
    backup_copy "$REPO/.config/compton/compton.conf" ~/.config/compton/compton.conf
    backup_copy "$REPO/.config/picom/picom.conf" ~/.config/picom/picom.conf
    backup_copy "$REPO/.config/rofi/config" ~/.config/rofi/config
    backup_copy "$REPO/.config/alacritty/alacritty.toml" ~/.config/alacritty/alacritty.toml
    backup_copy "$REPO/.config/gtk-3.0/settings.ini" ~/.config/gtk-3.0/settings.ini

    # Wallpaper fallback
    mkdir -p ~/.wallpaper
    cp -r "$REPO/.wallpaper/." ~/.wallpaper/
    backup_copy "$REPO/.fehbg" ~/.fehbg
    chmod +x ~/.fehbg

    # 5. Install Parrot Theme System
    log "Installing Omarchy themes and theme switcher..."
    mkdir -p ~/.config/parrot/themes
    cp -r "$REPO/themes/." ~/.config/parrot/themes/
    mkdir -p ~/.config/parrot/templates
    cp -r "$REPO/templates/." ~/.config/parrot/templates/
    mkdir -p ~/.local/bin
    for f in "$REPO/bin"/*; do
        [ -f "$f" ] && cp "$f" ~/.local/bin/
    done
    chmod +x ~/.local/bin/parrot-theme-* ~/.local/bin/render_template.py

    # 6. Oh-My-Zsh setup
    log "Configuring zsh shell..."
    if [ ! -d ~/.oh-my-zsh ]; then
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
    fi
    backup_copy "$REPO/.zshrc" ~/.zshrc

    ZSH_BIN="$(command -v zsh || true)"
    if [ -n "$ZSH_BIN" ] && [ "${SHELL:-}" != "$ZSH_BIN" ]; then
        chsh -s "$ZSH_BIN" || true
    fi

    # 7. Firefox customization
    if [ -f ~/.mozilla/firefox/profiles.ini ]; then
        log "Applying Firefox chrome ricing..."
        awk -F= '/^Path=/ {print $2}' ~/.mozilla/firefox/profiles.ini | while read -r profile; do
            dir=~/.mozilla/firefox/"$profile"
            [ -d "$dir" ] || continue
            mkdir -p "$dir/chrome"
            cp "$REPO/.config/firefox/chrome/userChrome.css" "$dir/chrome/"
            cp "$REPO/.config/firefox/chrome/userContent.css" "$dir/chrome/"
            touch "$dir/user.js"
            while IFS= read -r line; do
                name=$(echo "$line" | sed -n 's/^user_pref("\([^"]*\)".*/\1/p')
                [ -n "$name" ] || continue
                grep -q "user_pref(\"$name\"" "$dir/user.js" || echo "$line" >> "$dir/user.js"
            done < "$REPO/.config/firefox/user.js"
        done
    fi

    if [ -n "$BROWSER_PKG" ]; then
        DESKTOP_ENTRY="${BROWSER_PKG}.desktop"
        xdg-settings set default-web-browser "$DESKTOP_ENTRY" 2>/dev/null || true
        xdg-mime default "$DESKTOP_ENTRY" x-scheme-handler/http x-scheme-handler/https text/html 2>/dev/null || true
    fi

    # 8. Apply Initial Theme (tokyo-night)
    log "Applying default theme (tokyo-night)..."
    export PARROT_THEMES_DIR="$HOME/.config/parrot/themes"
    ~/.local/bin/parrot-theme-set tokyo-night || true
fi

echo
log "Installation complete!"
echo "------------------------------------------------------------------"
echo "Key shortcuts:"
echo "  Super + Return      : Terminal (cwd matched)"
echo "  Super + d           : Rofi launcher"
echo "  Super + Shift + t   : Omarchy Theme Switcher (interactive)"
echo "  Super + Shift + b   : Next Wallpaper for active theme"
echo "  Super + Shift + q   : Close focused window"
echo "  Super + Shift + e   : Exit i3"
echo "------------------------------------------------------------------"
echo "Reboot or log out, then pick 'i3' from your display manager (LightDM)."
