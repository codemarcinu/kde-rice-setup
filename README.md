# KDE Rice Setup — Qogir Dark + Catppuccin Mocha

A reproducible KDE Plasma 6 rice with a calm, minimal aesthetic. Dual-panel layout with a top info bar and a floating macOS-style dock.

Inspired by [this r/unixporn post](https://www.reddit.com/r/unixporn/comments/1qtr5br/) by u/markreuz.

![KDE Plasma 6](https://img.shields.io/badge/KDE_Plasma-6-1d99f3?logo=kde)
![Arch Linux](https://img.shields.io/badge/Arch_Linux-CachyOS-1793d1?logo=archlinux)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Overview

| Component | Choice |
|---|---|
| **Plasma Theme** | Qogir |
| **Color Scheme** | QogirManjaroDark |
| **Icons** | Papirus-Dark |
| **Window Decoration** | Qogir-dark (Aurorae) |
| **Cursor** | Bibata Modern Classic |
| **GTK Theme** | Qogir-Round-Dark |
| **Kvantum** | Qogir-dark |
| **System Font** | IBM Plex Mono 10pt |
| **Terminal Font** | JetBrains Mono 11pt |
| **Terminal** | kitty + fish + starship |
| **Color Palette** | Catppuccin Mocha |
| **Wallpaper** | Edited [Unsplash photo](https://unsplash.com/photos/KZaf74glebg) by Yohanes Dicky Yuniar |

### Panel Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  Menu │ Pager │ PlasMusic Toolbar    ···    Tray │ 12:56 │
└──────────────────────────────────────────────────────────────────┘

                    ┌──────────────────────┐
                    │  App icons (dock)    │
                    └──────────────────────┘
```

- **Top panel** — App menu, Latte Separator, Compact Pager, Latte Separator, PlasMusic Toolbar, spacer, System Tray, Digital Clock, Show Desktop
- **Bottom dock** — Floating, centered, fit-content icon task manager

### KWin Effects

- Blur (strength 8)
- Rounded corners (10px)
- Dim inactive windows (15%)
- Borderless maximized windows
- 3 virtual desktops

---

## Installation

### Requirements

- Arch Linux (or Arch-based distro like CachyOS, EndeavourOS, Manjaro)
- KDE Plasma 6 on Wayland
- [yay](https://github.com/Jguer/yay) AUR helper

### Quick Start

```bash
git clone https://github.com/codemarcinu/kde-rice-setup.git
cd kde-rice-setup
./install.sh
```

Log out and back in to fully apply cursor and fonts.

### Dry Run

Preview what will be installed without making changes:

```bash
./install.sh --dry-run
```

### SDDM Login Theme

The Qogir SDDM theme requires root access — run manually:

```bash
sudo mkdir -p /etc/sddm.conf.d
echo -e '[Theme]\nCurrent=Qogir' | sudo tee /etc/sddm.conf.d/theme.conf
```

---

## Management CLI

After installation, use `rice-manage.sh` to tweak settings without editing config files:

```bash
./rice-manage.sh help
```

### Wallpaper

```bash
./rice-manage.sh wallpaper set ~/photos/new-wallpaper.jpg
./rice-manage.sh wallpaper darken          # darken by 10%
./rice-manage.sh wallpaper lighten 20      # lighten by 20%
./rice-manage.sh wallpaper blur 8          # gaussian blur
./rice-manage.sh wallpaper reset           # restore default
```

### Panel & Dock

```bash
./rice-manage.sh panel opacity translucent
./rice-manage.sh panel thickness top 28
./rice-manage.sh panel thickness dock 56
./rice-manage.sh panel floating dock false

./rice-manage.sh dock add brave-browser.desktop
./rice-manage.sh dock remove org.kde.kate.desktop
./rice-manage.sh dock list
```

### KWin Effects

```bash
./rice-manage.sh effects blur 12           # blur strength (1-15)
./rice-manage.sh effects corners 8         # rounded corners (px)
./rice-manage.sh effects dim 20            # dim inactive (%)
./rice-manage.sh effects status            # show all effects
```

### Theme

```bash
./rice-manage.sh theme dark                # switch to dark
./rice-manage.sh theme light               # switch to light
./rice-manage.sh theme info                # show current
```

### Terminal (kitty)

```bash
./rice-manage.sh terminal opacity 0.85
./rice-manage.sh terminal padding "10 16"
./rice-manage.sh fonts terminal "Fira Code" 12
```

### Other

```bash
./rice-manage.sh cursor set Bibata-Modern-Ice
./rice-manage.sh cursor list
./rice-manage.sh desktops set 4
./rice-manage.sh status                    # full overview
./rice-manage.sh backup                    # backup all configs
./rice-manage.sh export                    # sync to this repo
./rice-manage.sh restart                   # restart plasmashell
```

---

## File Structure

```
kde-rice-setup/
├── install.sh                 # Full installation script
├── rice-manage.sh             # Management CLI
├── configs/
│   ├── kitty.conf             # Kitty terminal (Catppuccin Mocha)
│   ├── starship.toml          # Starship prompt config
│   ├── plasma-appletsrc       # Plasma panel layout
│   └── plasmashellrc          # Panel appearance settings
└── wallpaper/
    ├── original.jpg           # Original Unsplash photo
    └── wallpaper.png          # Edited (darkened, color-graded)
```

---

## Installed Packages

From official repos and AUR:

```
plasma6-themes-qogir-git    qogir-gtk-theme       papirus-icon-theme
bibata-cursor-theme-bin      kvantum               qt5ct / qt6ct
kwin-effect-rounded-corners  ttf-ibm-plex          ttf-jetbrains-mono
kitty                        fish                  starship
btop                         imagemagick
```

### Plasma Widgets (from KDE Store)

- [Latte Separator](https://store.kde.org/p/1295376)
- [Compact Pager](https://store.kde.org/p/2112443)
- [PlasMusic Toolbar](https://store.kde.org/p/2128143)

---

## Credits

- Original setup by [u/markreuz](https://www.reddit.com/r/unixporn/comments/1qtr5br/)
- Wallpaper photo by [Yohanes Dicky Yuniar](https://unsplash.com/@yhnsdcky) on Unsplash
- [Qogir theme](https://github.com/vinceliuice/Qogir-kde) by vinceliuice
- [Catppuccin](https://github.com/catppuccin/catppuccin) color palette
- [Papirus icons](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme)
- [Bibata cursors](https://github.com/ful1e5/Bibata_Cursor)

---

## License

MIT
