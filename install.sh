#!/bin/bash
# KDE Rice Setup - Qogir Dark + Calm & Simple
# Inspiracja: reddit.com/r/unixporn/comments/1qtr5br
# Data: 2026-03-31
#
# Uruchom: chmod +x install.sh && ./install.sh
# Opcje:  --dry-run   pokaz co zostanie zrobione bez instalacji

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=false
[[ "$1" == "--dry-run" ]] && DRY_RUN=true

# --- Kolory ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${BLUE}${BOLD}::${NC} $1"; }
ok()    { echo -e "${GREEN}${BOLD}OK${NC} $1"; }
warn()  { echo -e "${YELLOW}${BOLD}!!${NC} $1"; }
fail()  { echo -e "${RED}${BOLD}BLAD${NC} $1"; return 1; }

# --- Sprawdzenie wymaganych narzedzi ---
check_deps() {
    local missing=()
    for cmd in yay qdbus6 kpackagetool6 kwriteconfig6 python3 curl plasma-apply-desktoptheme plasma-apply-colorscheme; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        fail "Brakujace narzedzia: ${missing[*]}"
        exit 1
    fi
    ok "Wszystkie zaleznosci dostepne"
}

# --- Pobieranie widgetu z KDE Store ---
download_widget() {
    local name="$1" store_id="$2" filename="$3"
    info "Pobieranie: $name"

    local url
    url=$(curl -sL "https://store.kde.org/p/${store_id}/loadFiles" | \
        python3 -c "
import json, sys, urllib.parse
try:
    d = json.load(sys.stdin)
    urls = [urllib.parse.unquote(f['url']) for f in d['files'] if f['active'] == '1']
    if urls: print(urls[0])
except: pass
" 2>/dev/null)

    if [[ -z "$url" ]]; then
        warn "Nie udalo sie pobrac URL dla $name — zainstaluj recznie ze store.kde.org/p/$store_id"
        return 1
    fi

    curl -sL -o "$filename" "$url"

    # Walidacja — plik powinien miec >1KB
    local size
    size=$(stat -c%s "$filename" 2>/dev/null || echo 0)
    if [[ "$size" -lt 1024 ]]; then
        warn "Pobrany plik $name jest za maly (${size}B) — moze byc uszkodzony"
        rm -f "$filename"
        return 1
    fi

    ok "$name (${size}B)"
}

# --- Instalacja widgetu (install lub upgrade) ---
install_widget() {
    local file="$1" name="$2"
    if [[ ! -f "$file" ]]; then
        return 1
    fi

    if kpackagetool6 -t Plasma/Applet -i "$file" 2>/dev/null; then
        ok "Zainstalowano $name"
    elif kpackagetool6 -t Plasma/Applet -u "$file" 2>/dev/null; then
        ok "Zaktualizowano $name"
    else
        warn "Nie udalo sie zainstalowac $name"
        return 1
    fi
}

# ============================================================
# MAIN
# ============================================================

echo ""
echo -e "${BOLD}  KDE Rice Setup — Qogir Dark + Calm & Simple${NC}"
echo -e "  ─────────────────────────────────────────────"
echo ""

check_deps

if $DRY_RUN; then
    warn "Tryb --dry-run: pokazuje plan bez wykonywania zmian"
    echo ""
    echo "  Pakiety:  plasma6-themes-qogir-git qogir-gtk-theme papirus-icon-theme"
    echo "            ttf-ibm-plex ttf-jetbrains-mono kitty fish starship btop"
    echo "            bibata-cursor-theme-bin kvantum kwin-effect-rounded-corners"
    echo "  Widgety:  Latte Separator, Compact Pager, PlasMusic Toolbar"
    echo "  Motyw:    Qogir (plasma) + QogirManjaroDark (kolory) + Papirus-Dark (ikony)"
    echo "  Okna:     Qogir-dark (Aurorae) + rounded corners + blur + dim inactive"
    echo "  Kursor:   Bibata Modern Classic"
    echo "  Kvantum:  Qogir-dark"
    echo "  Czcionki: IBM Plex Mono (system) + JetBrains Mono (terminal)"
    echo "  GTK:      Qogir-Round-Dark"
    echo "  Terminal: kitty + fish + starship (Catppuccin Mocha)"
    echo "  Panele:   gorny (info) + dolny dock (ikony, plywajacy)"
    echo "  Tapeta:   edytowane zdjecie z Unsplash (Yohanes Dicky Yuniar)"
    echo "  Pulpity:  3 wirtualne pulpity"
    echo ""
    echo "  Uruchom bez --dry-run aby zainstalowac."
    exit 0
fi

# --- Pakiety ---
info "Instalacja pakietow..."
yay -S --needed --noconfirm \
    plasma6-themes-qogir-git \
    qogir-gtk-theme \
    papirus-icon-theme \
    ttf-ibm-plex \
    ttf-jetbrains-mono \
    kitty \
    fish \
    starship \
    btop \
    bibata-cursor-theme-bin \
    kvantum \
    qt5ct \
    qt6ct \
    kwin-effect-rounded-corners \
    imagemagick || fail "Instalacja pakietow nie powiodla sie"
ok "Pakiety zainstalowane"

# --- Widgety panelu ---
echo ""
info "Pobieranie widgetow panelu..."
WIDGET_DIR=$(mktemp -d)
trap "rm -rf '$WIDGET_DIR'" EXIT

download_widget "Latte Separator"  1295376 "$WIDGET_DIR/latte-separator.plasmoid"
download_widget "Compact Pager"    2112443 "$WIDGET_DIR/compact-pager.plasmoid"
download_widget "PlasMusic Toolbar" 2128143 "$WIDGET_DIR/plasmusic.plasmoid"

install_widget "$WIDGET_DIR/latte-separator.plasmoid" "Latte Separator"
install_widget "$WIDGET_DIR/compact-pager.plasmoid"   "Compact Pager"
install_widget "$WIDGET_DIR/plasmusic.plasmoid"        "PlasMusic Toolbar"

# --- Motywy KDE ---
echo ""
info "Zastosowanie motywow KDE..."
# Utwórz Qogir-dark jako samodzielny motyw (upstream nie ma metadata)
mkdir -p ~/.local/share/plasma/desktoptheme/Qogir-dark
cp -r /usr/share/plasma/desktoptheme/Qogir/* ~/.local/share/plasma/desktoptheme/Qogir-dark/
cp -r /usr/share/plasma/desktoptheme/Qogir-dark/* ~/.local/share/plasma/desktoptheme/Qogir-dark/ 2>/dev/null || true
cat > ~/.local/share/plasma/desktoptheme/Qogir-dark/metadata.json <<'METAEOF'
{
    "KPlugin": {
        "Authors": [{"Email": "vinceliuice@hotmail.com", "Name": "Vinceliuice"}],
        "Description": "Qogir dark theme for plasma",
        "EnabledByDefault": true,
        "Id": "Qogir-dark",
        "License": "GPL 3.0",
        "Name": "Qogir-dark",
        "Version": "0.1"
    }
}
METAEOF
plasma-apply-desktoptheme Qogir-dark
plasma-apply-colorscheme QogirManjaroDark
/usr/lib/plasma-changeicons Papirus-Dark 2>/dev/null || warn "Nie udalo sie zmienic ikon"

# Dekoracja okien
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.kwin.aurorae"
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme "__aurorae__svg__Qogir-dark"
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || warn "Nie udalo sie przeladowac KWin"

# Czcionki
kwriteconfig6 --file kdeglobals --group General --key font "IBM Plex Mono,10,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file kdeglobals --group General --key menuFont "IBM Plex Mono,10,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file kdeglobals --group General --key toolBarFont "IBM Plex Mono,9,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file kdeglobals --group General --key smallestReadableFont "IBM Plex Mono,8,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file kdeglobals --group General --key fixed "JetBrains Mono,10,-1,5,50,0,0,0,0,0"

# GTK — uzyj gsettings jesli dostepne, fallback na kwriteconfig6
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme "Qogir-Round-Dark" 2>/dev/null || true
fi
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
cat > ~/.config/gtk-3.0/settings.ini <<'EOF'
[Settings]
gtk-theme-name=Qogir-Round-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=IBM Plex Mono 10
EOF
cat > ~/.config/gtk-4.0/settings.ini <<'EOF'
[Settings]
gtk-theme-name=Qogir-Round-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=IBM Plex Mono 10
EOF

# Domyslny terminal
kwriteconfig6 --file kdeglobals --group General --key TerminalApplication kitty
kwriteconfig6 --file kdeglobals --group General --key TerminalService org.kde.kitty.desktop

# Kursor — Bibata Modern Classic
kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "Bibata-Modern-Classic"
kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize 24
kwriteconfig6 --file kdeglobals --group KDE --key cursorTheme "Bibata-Modern-Classic"

# Kvantum — Qogir-dark
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle "kvantum"
mkdir -p ~/.config/Kvantum
cat > ~/.config/Kvantum/kvantum.kvconfig <<'EOF'
[General]
theme=Qogir-dark
EOF

# KWin efekty — blur, rounded corners, dim inactive
kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled true
kwriteconfig6 --file kwinrc --group Effect-blur --key BlurStrength 8
kwriteconfig6 --file kwinrc --group Effect-blur --key NoiseStrength 0
kwriteconfig6 --file kwinrc --group Plugins --key kwin_effect_rounded_cornersEnabled true
kwriteconfig6 --file kwinrc --group Effect-kwin_effect_rounded_corners --key Size 10
kwriteconfig6 --file kwinrc --group Plugins --key diminactiveEnabled true
kwriteconfig6 --file kwinrc --group Effect-diminactive --key Strength 15
kwriteconfig6 --file kwinrc --group Windows --key BorderlessMaximizedWindows true

# 3 pulpity wirtualne
kwriteconfig6 --file kwinrc --group Desktops --key Number 3
kwriteconfig6 --file kwinrc --group Desktops --key Rows 1

qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || warn "Nie udalo sie przeladowac KWin"
ok "Motywy, efekty i kursor zastosowane"

# --- Konfiguracje terminalowe ---
echo ""
info "Kopiowanie konfiguracji terminalowych..."

# Kitty
mkdir -p ~/.config/kitty
cp "$SCRIPT_DIR/configs/kitty.conf" ~/.config/kitty/kitty.conf
ok "kitty.conf"

# Starship
cp "$SCRIPT_DIR/configs/starship.toml" ~/.config/starship.toml
ok "starship.toml"

# Fish — stworz config jesli nie istnieje, dodaj starship init
mkdir -p ~/.config/fish
touch ~/.config/fish/config.fish
if ! grep -q "starship init fish" ~/.config/fish/config.fish; then
    cat >> ~/.config/fish/config.fish <<'EOF'

# Starship prompt
starship init fish | source
EOF
    ok "fish — dodano starship init"
else
    ok "fish — starship init juz obecny"
fi

# --- Tapeta ---
echo ""
info "Ustawianie tapety..."
if [[ -f "$SCRIPT_DIR/wallpaper/wallpaper.png" ]]; then
    mkdir -p ~/.local/share/wallpapers
    cp "$SCRIPT_DIR/wallpaper/wallpaper.png" ~/.local/share/wallpapers/rice-wallpaper.png
    ok "Tapeta skopiowana"
else
    warn "Brak tapety w $SCRIPT_DIR/wallpaper/ — pomijam"
fi

# --- Konfiguracja paneli ---
echo ""
info "Konfiguracja paneli (gorny + dolny dock)..."

# Kopia zapasowa
for f in plasma-org.kde.plasma.desktop-appletsrc plasmashellrc; do
    if [[ -f ~/.config/$f ]]; then
        cp ~/.config/$f ~/.config/${f}.bak
    fi
done
ok "Backup istniejacych konfiguracji (.bak)"

# Zatrzymaj plasmashell
kquitapp6 plasmashell 2>/dev/null || true
sleep 2

# Kopiuj appletsrc
cp "$SCRIPT_DIR/configs/plasma-appletsrc" ~/.config/plasma-org.kde.plasma.desktop-appletsrc

# Kopiuj plasmashellrc BEZ sekcji [Updates] (zachowaj lokalne migracje)
python3 -c "
import configparser, sys, os

# Wczytaj nowy plik (z rice setup)
new = configparser.ConfigParser()
new.optionxform = str
new.read('$SCRIPT_DIR/configs/plasmashellrc')

# Wczytaj istniejacy (lokalny) jesli jest
old = configparser.ConfigParser()
old.optionxform = str
old_path = os.path.expanduser('~/.config/plasmashellrc')
if os.path.exists(old_path):
    old.read(old_path)

# Zachowaj lokalna sekcje [Updates]
if old.has_section('Updates'):
    if not new.has_section('Updates'):
        new.add_section('Updates')
    for key, val in old.items('Updates'):
        new.set('Updates', key, val)

with open(old_path, 'w') as f:
    new.write(f, space_around_delimiters=False)
"
ok "Konfiguracje paneli skopiowane"

# Uruchom plasmashell
kstart plasmashell 2>/dev/null &
info "Czekam na plasmashell..."
sleep 4

# Ustaw dolny dock przez D-Bus API (unika problemow z hardkodowanymi ID)
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var panels = panels();
for (var i = 0; i < panels.length; i++) {
    if (panels[i].location == 'bottom') {
        panels[i].alignment = 'center';
        panels[i].lengthMode = 'fit';
    }
}
" 2>/dev/null || warn "Nie udalo sie ustawic docka — ustaw recznie (PPM > Edytuj panel)"

# Ustaw tapete
if [[ -f ~/.local/share/wallpapers/rice-wallpaper.png ]]; then
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    var allDesktops = desktops();
    for (var i = 0; i < allDesktops.length; i++) {
        var d = allDesktops[i];
        d.wallpaperPlugin = 'org.kde.image';
        d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
        d.writeConfig('Image', 'file://$HOME/.local/share/wallpapers/rice-wallpaper.png');
    }
    " 2>/dev/null
    ok "Tapeta ustawiona"
fi

# --- Podsumowanie ---
echo ""
echo -e "${GREEN}${BOLD}  Gotowe!${NC}"
echo ""
echo "  Layout:"
echo "    Gorny panel: Menu | Sep | Pager | Sep | PlasMusic | [spacer] | Tray | Zegar"
echo "    Dolny dock:  Ikony aplikacji (wycentrowany, plywajacy)"
echo ""
echo "  Zarzadzanie: ./rice-manage.sh help"
echo ""
echo -e "  ${YELLOW}Uwaga:${NC} Wyloguj/zaloguj aby zastosowac kursor i czcionki w pelni."
echo ""
