# parrot-clean

A clean, minimalist i3 desktop environment installer for **Parrot OS** (Home and Security editions) featuring **Omarchy's themes**.

Flat near-black or curated palettes, Geist Mono typography, 1px borders, tear-free compositing, and full ecosystem styling (i3, i3bar, Alacritty, Rofi, GTK-3, Firefox, and Wallpapers).

---

# My not-AI-generated README:

inspired by xct's kali-clean i implemented the install script with parrot and added the theme switcher I took from omarchy .

--- 
## Features

- **Parrot OS native**: Designed for Debian/Parrot repos (`apt`), LightDM display manager compatibility, and MATE coexistence.
- **23 Omarchy Themes built-in**: `tokyo-night`, `catppuccin`, `gruvbox`, `nord`, `hackerman`, `kanagawa`, `rose-pine`, `matte-black`, `flexoki-light`, and more.
- **Dynamic Theme Switcher**: Interactive Rofi/FZF menu (`Super + Shift + t`) that live-reloads i3bar, window borders, Alacritty, Rofi, GTK mode (light/dark), and sets matching wallpapers.
- **Wallpaper Cycling**: Cycle through curated wallpapers for the active theme (`Super + Shift + b`).
- **Terminal CWD Tracking**: Spawns new terminals in the working directory of the currently focused terminal (`Super + Return`).
- **Geist Mono font**: Clean, high-legibility developer font across the entire desktop.
- **Firefox Chrome styling**: Custom `userChrome.css` and `userContent.css` mirroring the active styling.

---

## Quick Install (on Parrot OS)

Clone and run as your **normal user** (not root):

```bash
git clone https://github.com/Weave7/parrot-clean.git
cd parrot-clean
./install.sh
```

To review what the installer will do without making changes:
```bash
./install.sh --dry-run
```

After installation finishes, log out or reboot and select **i3** from the LightDM session menu on your login screen.

---

## Keybindings (Mod = Super)

| Shortcut | Action |
| --- | --- |
| `mod + Return` | Open terminal in focused directory |
| `mod + d` | Open Rofi application launcher |
| `mod + Shift + t` | **Open Omarchy Theme Switcher** (Rofi / FZF) |
| `mod + Shift + b` | **Next Wallpaper** for current theme |
| `mod + Shift + f` | Launch Firefox |
| `mod + P` | Screenshot with Flameshot |
| `mod + Shift + q` | Close focused window |
| `mod + Shift + w` | Close all windows on current workspace |
| `mod + j/k/l/;` | Focus window left / down / up / right |
| `mod + Shift + j/k/l/;` | Move window left / down / up / right |
| `mod + h` / `mod + v` | Split horizontal / vertical |
| `mod + f` | Fullscreen toggle |
| `mod + s` / `mod + w` / `mod + e` | Stacking / Tabbed / Split layout |
| `mod + Shift + space` | Toggle floating |
| `mod + 1..0` | Switch to workspace 1..10 |
| `mod + Shift + 1..0` | Move container to workspace 1..10 |
| `mod + r` | Resize mode |
| `mod + Shift + c` | Reload i3 configuration |
| `mod + Shift + e` | Exit i3 (log out) |

---

## Theme Engine CLI

You can also control themes from the terminal or scripts:

```bash
# List all 23 available themes
parrot-theme-list

# Show active theme
parrot-theme-current

# Apply any theme by name (e.g., catppuccin, gruvbox, hackerman, flexoki-light)
parrot-theme-set tokyo-night

# Open interactive switcher
parrot-theme-switcher

# Switch to next background for current theme
parrot-theme-bg-next
```

---

## Directory Structure

```text
parrot-clean/
├── install.sh                  # Distro-aware installer (idempotent, supports --dry-run)
├── README.md                   # Documentation and keybindings
├── LICENSE                     # MIT license & attribution
├── bin/                        # Theme engine scripts (installed to ~/.local/bin/)
│   ├── render_template.py      # Python 3 template renderer (substitutions & mixes)
│   ├── parrot-theme-list       # Lists available themes
│   ├── parrot-theme-current    # Prints currently applied theme
│   ├── parrot-theme-set        # Renders templates, reloads i3/alacritty/rofi/feh/gtk
│   ├── parrot-theme-switcher   # Interactive Rofi picker
│   └── parrot-theme-bg-next    # Wallpaper cycler
├── templates/                  # Templates rendered on theme switch
│   ├── alacritty.toml.tpl      # Terminal palette template
│   ├── i3-colors.conf.tpl      # i3bar and border colors template
│   └── rofi-theme.rasi.tpl     # Rofi styling template
├── themes/                     # 23 Omarchy themes (colors.toml + backgrounds/)
├── .config/                    # Base configs (i3, alacritty, rofi, compton, picom, gtk, firefox)
├── .fehbg                      # Initial wallpaper launcher
└── .zshrc                      # Oh-My-Zsh & CWD tracking configuration
```

---

## How It Works

1. Each theme folder in `themes/<name>/` contains:
   - `colors.toml`: semantic colors (`background`, `foreground`, `accent`, `muted`, `red`, `green`, etc.) and `mode` (`dark` or `light`).
   - `backgrounds/`: curated wallpapers.
2. `render_template.py` processes templates in `templates/*.tpl`, evaluating variables `{{ var_name }}` and color mixes `{{ mix c1 c2 pct }}`.
3. `parrot-theme-set` outputs dynamic configuration files directly to `~/.config/` and signals running tools (reloads i3 via `i3-msg reload`, live-updates Alacritty colors, applies GTK dark/light mode via `gsettings`, and calls `feh` for wallpaper updates).

---

## Adding Custom Themes

To add your own theme:
1. Create a directory: `~/.config/parrot/themes/my-theme/`
2. Add a `colors.toml` file with your color palette (see any existing theme for reference).
3. Optionally add a `backgrounds/` folder containing images.
4. Run `parrot-theme-set my-theme` or select it from `parrot-theme-switcher`.

---

## Differences from kali-clean

- **Target Distro**: Uses Debian/Parrot package naming and repository tools; handles Parrot's LightDM without disruption.
- **Dynamic Theming**: Replaces hardcoded static near-black colors with the full suite of 23 Omarchy themes and dynamic rendering.
- **Live Switcher**: Adds `Super + Shift + t` and `Super + Shift + b` shortcuts.
- **Safety**: Safe backup mechanism (`.bak`), `set -euo pipefail`, and `--dry-run` inspection support.

---

## Credits & License

- Forked and adapted from [xct/kali-clean](https://github.com/xct/kali-clean).
- Themes and palette engine inspired by [Omarchy](https://github.com/basecamp/omarchy) by David Heinemeier Hansson / 37signals (MIT License).
