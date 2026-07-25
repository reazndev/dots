#!/bin/bash
#
# Interactive package installer for reazndev/dots
#
# Usage: ./install.sh
#
# Uses fzf for a TUI if available; falls back to a simple numbered menu.
# Detects already-installed packages, lets you toggle selections with
# <Space>, select all with Ctrl-A, deselect all with Ctrl-D, then installs
# the selected packages with pacman / yay.

set -uo pipefail

# -----------------------------------------------------------------------------
# Package list
# Format: "category|manager|package|description"
# manager is either "pacman" or "yay"
# -----------------------------------------------------------------------------

declare -a PACKAGES=(
    # Core desktop
    "Core Desktop|pacman|hyprland|Window manager / Wayland compositor"
    "Core Desktop|pacman|hyprsunset|Blue-light filter / night light daemon"
    "Core Desktop|pacman|quickshell-git|Desktop shell / bar / widgets"
    "Core Desktop|pacman|gnome-keyring|Secret storage daemon"
    "Core Desktop|pacman|xdg-desktop-portal-hyprland|Screensharing / portal support"
    "Core Desktop|pacman|xdg-desktop-portal|Generic xdg-desktop-portal"

    # Terminal / shell
    "Terminal / Shell|pacman|fish|Default shell"
    "Terminal / Shell|pacman|cachyos-fish-config|CachyOS fish defaults"
    "Terminal / Shell|pacman|starship|Prompt renderer"
    "Terminal / Shell|pacman|zoxide|Smart cd command"
    "Terminal / Shell|pacman|ghostty|Primary terminal emulator"
    "Terminal / Shell|pacman|kitty|Secondary terminal + fastfetch image protocol"
    "Terminal / Shell|pacman|micro|Terminal editor"

    # Audio / media / brightness
    "Audio / Media|pacman|pipewire|Audio server"
    "Audio / Media|pacman|wireplumber|PipeWire session manager (provides wpctl)"
    "Audio / Media|pacman|playerctl|Media keys controller"
    "Audio / Media|pacman|brightnessctl|Laptop brightness control"

    # Screenshots / color picker / recording
    "Screenshots|pacman|hyprshot|Screenshot utility"
    "Screenshots|pacman|hyprpicker|Wayland color picker"
    "Screenshots|pacman|slurp|Region selection"
    "Screenshots|yay|wf-recorder|Screen recorder for the record-region script"

    # Theming
    "Theming|yay|wallust|Generate colors from wallpaper"
    "Theming|yay|ttf-lucide-font|Icon font for the Quickshell bar"
    "Theming|yay|mactahoe-icon-theme-git|MacTahoe-dark icon theme"

    # Fonts
    "Fonts|pacman|ttf-lilex-nerd|Terminal font"
    "Fonts|pacman|ttf-dejavu|Fallback font for fastfetch logo"
    "Fonts|pacman|ttf-liberation|Fallback font for fastfetch logo"
    "Fonts|yay|ttf-outfit|GTK UI font"
    "Fonts|yay|ttf-apple-emoji|Apple-style color emoji font"

    # Icon / cursor / GTK themes
    "Themes|pacman|adwaita-icon-theme|Adwaita cursor / fallback icons"
    "Themes|pacman|gnome-themes-extra|Adwaita-dark GTK theme"
    "Themes|yay|qgnomeplatform-qt5|Qt5 GTK3 platform theme"
    "Themes|yay|qgnomeplatform-qt6|Qt6 GTK3 platform theme"

    # Applications
    "Applications|pacman|dolphin|File manager"
    "Applications|yay|helium-browser-bin|Default web browser"
    "Applications|yay|vesktop-bin|Discord client"
    "Applications|yay|element-desktop-nightly|Matrix client"
    "Applications|yay|spotify-launcher|Spotify client"
    "Applications|yay|vicinae-bin|Launcher / clipboard manager"
    "Applications|yay|t3code-nightly-bin|Editor bound to Super+M"
    "Applications|yay|zed-preview|Zed editor preview"
    "Applications|yay|spicetify-cli|Spotify theming tool"
    "Applications|pacman|localsend|LocalSend integration"

    # Utilities
    "Utilities|pacman|pacseek|Package searcher"
    "Utilities|pacman|python-pillow|Fastfetch logo generator dependency"

    # Development
    "Development|pacman|rust|Build localsend-bridge"
    "Development|pacman|cargo|Build localsend-bridge"
    "Development|pacman|nodejs|Zed formatter runner"
    "Development|pacman|npm|Zed formatter runner"
    "Development|pacman|prettier|External formatter for Zed"
    "Development|yay|kimi-code|AI assistant (optional)"
)

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

is_installed() {
    pacman -Q "$1" &>/dev/null
}

# ANSI colors
C_RESET='\033[0m'
C_GREEN='\033[1;32m'
C_RED='\033[1;31m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'
C_DIM='\033[2m'

# -----------------------------------------------------------------------------
# fzf-based TUI
# -----------------------------------------------------------------------------

run_fzf_tui() {
    local tmpdir
    tmpdir=$(mktemp -d)
    local lines_file="$tmpdir/lines"

    > "$lines_file"

    local idx=0
    local entry category manager pkg desc
    for entry in "${PACKAGES[@]}"; do
        IFS='|' read -r category manager pkg desc <<< "$entry"
        if is_installed "$pkg"; then
            printf '%d\t%s[installed]%s  %-22s %-14s %s\n' \
                "$idx" "$C_GREEN" "$C_RESET" "[$category]" "$pkg" "$desc" >> "$lines_file"
        else
            printf '%d\t%s[missing]  %s  %-22s %-14s %s\n' \
                "$idx" "$C_RED" "$C_RESET" "[$category]" "$pkg" "$desc" >> "$lines_file"
        fi
        ((idx++))
    done

    local fzf_height=$(( ${#PACKAGES[@]} + 6 ))
    (( fzf_height > 40 )) && fzf_height=40

    local header
    header="Toggle: <Space> | Select all: Ctrl-A | Deselect all: Ctrl-D | Confirm: <Enter> | Quit: Ctrl-C"

    mapfile -t selected < <(
        fzf \
            --multi \
            --ansi \
            --no-sort \
            --reverse \
            --height "$fzf_height" \
            --header "$header" \
            --prompt "Packages to install > " \
            --bind 'space:toggle+down' \
            --bind 'ctrl-a:select-all' \
            --bind 'ctrl-d:deselect-all' \
            --bind 'ctrl-t:toggle-all' \
            --delimiter '\t' \
            --with-nth 2.. \
            < "$lines_file"
    )

    rm -rf "$tmpdir"

    if (( ${#selected[@]} == 0 )); then
        echo "No packages selected. Exiting."
        exit 0
    fi

    declare -a pacman_pkgs=()
    declare -a yay_pkgs=()

    local line idx
    for line in "${selected[@]}"; do
        idx=$(printf '%s' "$line" | cut -f1)
        entry="${PACKAGES[$idx]}"
        IFS='|' read -r category manager pkg desc <<< "$entry"
        if [[ "$manager" == "pacman" ]]; then
            pacman_pkgs+=("$pkg")
        else
            yay_pkgs+=("$pkg")
        fi
    done

    install_selected pacman_pkgs yay_pkgs
}

# -----------------------------------------------------------------------------
# Fallback numbered menu (no fzf)
# -----------------------------------------------------------------------------

run_fallback_menu() {
    echo "${C_YELLOW}fzf not found. Using numbered menu instead.${C_RESET}"
    echo

    local idx=0
    local entry category manager pkg desc
    for entry in "${PACKAGES[@]}"; do
        IFS='|' read -r category manager pkg desc <<< "$entry"
        if is_installed "$pkg"; then
            printf '%s%3d)%s [INSTALLED] %-20s %s\n' "$C_GREEN" "$idx" "$C_RESET" "$pkg" "$desc"
        else
            printf '%s%3d)%s [MISSING]   %-20s %s\n' "$C_RED" "$idx" "$C_RESET" "$pkg" "$desc"
        fi
        ((idx++))
    done

    echo
    echo "Enter the numbers of packages to install, separated by spaces."
    echo "Example: 0 1 5 12"
    echo "Or type 'all-missing' to install every missing package."
    read -rp "> " selection

    declare -a indices=()
    if [[ "$selection" == "all-missing" ]]; then
        local i=0
        for entry in "${PACKAGES[@]}"; do
            IFS='|' read -r _ _ pkg _ <<< "$entry"
            if ! is_installed "$pkg"; then
                indices+=("$i")
            fi
            ((i++))
        done
    else
        for n in $selection; do
            if [[ "$n" =~ ^[0-9]+$ ]] && (( n >= 0 && n < ${#PACKAGES[@]} )); then
                indices+=("$n")
            else
                echo "Invalid selection: $n" >&2
            fi
        done
    fi

    if (( ${#indices[@]} == 0 )); then
        echo "No packages selected. Exiting."
        exit 0
    fi

    declare -a pacman_pkgs=()
    declare -a yay_pkgs=()

    for idx in "${indices[@]}"; do
        entry="${PACKAGES[$idx]}"
        IFS='|' read -r category manager pkg desc <<< "$entry"
        if [[ "$manager" == "pacman" ]]; then
            pacman_pkgs+=("$pkg")
        else
            yay_pkgs+=("$pkg")
        fi
    done

    install_selected pacman_pkgs yay_pkgs
}

# -----------------------------------------------------------------------------
# Installation
# -----------------------------------------------------------------------------

install_selected() {
    local -n _pacman=$1
    local -n _yay=$2

    if (( ${#_pacman[@]} == 0 && ${#_yay[@]} == 0 )); then
        echo "No packages to install."
        exit 0
    fi

    echo
    echo "${C_BLUE}Selected packages:${C_RESET}"
    for pkg in "${_pacman[@]}"; do
        echo "  [pacman] $pkg"
    done
    for pkg in "${_yay[@]}"; do
        echo "  [yay]    $pkg"
    done
    echo

    read -rp "Proceed with installation? [Y/n] " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo "Cancelled."
        exit 0
    fi

    if (( ${#_pacman[@]} > 0 )); then
        echo
        echo "${C_BLUE}Installing via pacman...${C_RESET}"
        sudo pacman -S --needed "${_pacman[@]}"
    fi

    if (( ${#_yay[@]} > 0 )); then
        echo
        echo "${C_BLUE}Installing via yay...${C_RESET}"
        yay -S --needed "${_yay[@]}"
    fi

    echo
    echo "${C_GREEN}Done.${C_RESET}"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    if ! command -v yay &>/dev/null; then
        echo "Error: yay is required but not installed." >&2
        exit 1
    fi

    if command -v fzf &>/dev/null; then
        run_fzf_tui
    else
        run_fallback_menu
    fi
}

main "$@"
