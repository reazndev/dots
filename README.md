# Dotfiles

Personal Hyprland + Quickshell desktop setup for CachyOS/Arch Linux.

## Deploying

These configs are intended to live in `~/.config`. Use a symlink manager like `stow` or copy them manually:

```bash
git clone https://github.com/reazndev/dots.git ~/dots
cd ~/dots
stow -t ~/.config -d . .
# or: cp -r * ~/.config/
```

## Required packages

Install everything below on a fresh machine before starting Hyprland.

For an interactive installer that detects already-installed packages, run:

```bash
./install.sh
```

### Quick install

```bash
# Core desktop
sudo pacman -S hyprland hyprsunset quickshell-git

# Terminal / shell
sudo pacman -S fish cachyos-fish-config starship zoxide ghostty kitty micro

# Audio / media / brightness
sudo pacman -S pipewire wireplumber playerctl brightnessctl

# Screenshots / color picker / region selection
sudo pacman -S hyprshot hyprpicker slurp

# Theming
yay -S wallust ttf-lucide-font mactahoe-icon-theme-git

# Fonts
sudo pacman -S ttf-lilex-nerd ttf-dejavu ttf-liberation
yay -S ttf-outfit ttf-apple-emoji

# Apps
yay -S helium-browser-bin vesktop element-desktop-nightly spotify-launcher vicinae-bin t3code-nightly-bin zed-preview

# Optional but referenced
sudo pacman -S dolphin gnome-keyring xdg-desktop-portal xdg-desktop-portal-hyprland
yay -S spicetify-cli qgnomeplatform-qt5 qgnomeplatform-qt6
```

---

## Package breakdown

### WM / compositor

| Package | Why it's needed |
|---------|-----------------|
| `hyprland` | Window manager / Wayland compositor |
| `hyprsunset` | Blue-light filter / night light daemon |
| `quickshell` / `quickshell-git` | Desktop shell / bar / widgets |
| `gnome-keyring` | Secret storage daemon started in `hypr/startup.lua` |
| `xdg-desktop-portal-hyprland` | Screensharing and portal support |

### Terminal / shell

| Package | Why it's needed |
|---------|-----------------|
| `fish` | Default shell |
| `cachyos-fish-config` | CachyOS fish defaults sourced by `fish/config.fish` |
| `starship` | Prompt renderer |
| `zoxide` | Smart `cd` replacement invoked in `fish/config.fish` |
| `ghostty` | Primary terminal emulator |
| `kitty` | Secondary terminal config + fastfetch logo image protocol |
| `micro` | Terminal editor (uses bundled `catppuccin-macchiato` colorscheme) |

### Bar / widgets helpers

Quickshell shells out to these tools:

| Package | Why it's needed |
|---------|-----------------|
| `python` | `HyprlandSnapshotService` parses `hyprctl` output |
| `bash` | Shell wrapper for many Quickshell `Process` commands |
| `wpctl` (`wireplumber`) | Volume control |
| `pactl` (`pulseaudio-utils`) | Audio event subscription |
| `free`, `awk` (`gawk`) | RAM usage in system monitor |
| `sensors` (`lm_sensors`) | CPU temperature |
| `nvidia-smi` | GPU usage (NVIDIA only; optional) |
| `hyprctl` | Hyprland IPC |
| `pidof`, `killall` (`psmisc`) | Managing `hyprsunset` |
| `notify-send` (`libnotify`) | Layout toggle notifications |

### Audio / brightness / media

| Package | Why it's needed |
|---------|-----------------|
| `pipewire` + `wireplumber` | Audio stack |
| `playerctl` | Media keys (play/pause/next/prev) |
| `brightnessctl` | Laptop brightness keys |

### Screenshots / color picker / recording

| Package | Why it's needed |
|---------|-----------------|
| `hyprshot` | Screenshots (`Super+Shift+S`, etc.) |
| `hyprpicker` | Color picker (`Super+Shift+C`) |
| `slurp` | Region selection (used by the example recording script) |
| `wf-recorder` or `wl-screenrec` | For the missing `hypr/scripts/record-region.sh` script |

### Theming engine

| Package | Why it's needed |
|---------|-----------------|
| `wallust` | Generates color themes from wallpaper for Ghostty, Kitty, Starship, Hyprland, Zed, GTK, KDE globals, Vicinae, Spicetify, Vesktop |

### Fonts

| Package | Why it's needed |
|---------|-----------------|
| `ttf-lucide-font` | Icon font used by the Quickshell bar (`Theme.iconFontFamily: "lucide"`) |
| `ttf-lilex-nerd` | Terminal font in Ghostty and Kitty |
| `ttf-outfit` | GTK UI font (`gtk-3.0/settings.ini`, `gtk-4.0/settings.ini`) |
| `ttf-apple-emoji` | Apple-style color emoji font, preferred globally by `fontconfig/fonts.conf` |
| `ttf-dejavu` / `ttf-liberation` | Used by `fastfetch/generate_logo_png.py` to render the logo PNG |

### Icon / cursor / GTK themes

| Package | Why it's needed |
|---------|-----------------|
| `mactahoe-icon-theme-git` | System icon theme (`MacTahoe-dark`) used by GTK, Dolphin, and KDE globals |
| `adwaita-icon-theme` | Cursor / fallback icon theme (`Adwaita`) |
| `gnome-themes-extra` | GTK theme (`Adwaita-dark`) |
| `qgnomeplatform-qt5` / `qgnomeplatform-qt6` | Qt GTK3 platform theme (`QT_QPA_PLATFORMTHEME=gtk3`) |

### Applications

| Package | Why it's needed |
|---------|-----------------|
| `dolphin` | File manager |
| `helium-browser-bin` | Default web browser (HTTP/HTTPS/HTML) |
| `zeditor` / `zed` / `zed-preview` | Code editor bound to `Super+C` |
| `t3code-nightly-bin` | Editor/IDE bound to `Super+M` |
| `vesktop` | Discord client (also `discord://` handler) |
| `element-desktop-nightly` | Matrix client |
| `spotify-launcher` / `spotify` | Spotify client |
| `spicetify-cli` | Spotify theming, refreshed on wallpaper change |
| `vicinae-bin` | Application launcher / clipboard manager / command palette |
| `localsend` | LocalSend integration in Quickshell island |

### Utilities

| Package | Why it's needed |
|---------|-----------------|
| `yay` | AUR helper (used throughout this README and by `pacseek`) |
| `pacseek` | Package searcher (`pacseek/config.json`) |
| `curl`, `less` | Viewing PKGBUILDs from `pacseek` |
| `python-pillow` | Used by `fastfetch/generate_logo_png.py` to render the logo PNG |

### Development / build tools

| Package | Why it's needed |
|---------|-----------------|
| `rust` / `cargo` | Build the `quickshell/helpers/localsend-bridge` helper |
| `nodejs` + `npm` | Run Prettier in Zed |
| `prettier` | External formatter for JS/TS/HTML/CSS/JSON/Markdown in Zed |
| `kimi-code` | Optional: AI assistant referenced in `fish/config.fish` and Zed ACP settings |

---

## Post-install steps

### 1. Refresh font cache

```bash
fc-cache -fv
```

### 2. Build the LocalSend bridge

```bash
cd ~/.config/quickshell/helpers/localsend-bridge
cargo build --release
```

The binary is expected at `quickshell/helpers/localsend-bridge/target/release/localsend-bridge`.

### 3. Generate themes from wallpaper

```bash
wallust run /path/to/wallpaper.png
```

This creates `Wallust` color schemes for Hyprland, GTK, KDE globals, Zed, etc.

### 4. Fix missing screen-recording script

`hypr/keybinds.lua` references `~/.config/hypr/scripts/record-region.sh`, but the `hypr/scripts/` directory does not exist. Create it yourself, for example:

```bash
mkdir -p ~/.config/hypr/scripts
cat > ~/.config/hypr/scripts/record-region.sh <<'EOF'
#!/bin/bash
# Screen region recorder using wf-recorder
set -e

OUTPUT="$HOME/Videos/record-$(date +%Y%m%d-%H%M%S).mp4"
mkdir -p "$(dirname "$OUTPUT")"

if pgrep -x wf-recorder >/dev/null; then
    pkill -x wf-recorder
    notify-send "Recording saved"
else
    notify-send "Select a region to record"
    wf-recorder -g "$(slurp)" -f "$OUTPUT"
    notify-send "Recording saved" "$OUTPUT"
fi
EOF
chmod +x ~/.config/hypr/scripts/record-region.sh
```

You will also need `wf-recorder` and `slurp` for this script.

---

## Known non-repo / custom items

| Item | Status |
|------|--------|
| `awww-daemon` | Referenced in `hypr/startup.lua` but not available in repos/AUR. This is likely a custom wallpaper daemon from a separate `awww` project. |
| `~/.config/icons/png/*.png` | Tracked in this repo; no package needed. Used for custom Quickshell notification app icons. |

---

## Starting the session

Log in from a TTY or display manager and launch Hyprland:

```bash
Hyprland
```

Quickshell, `hyprsunset`, `vicinae`, and `awww-daemon` are started automatically via `hypr/startup.lua`.
