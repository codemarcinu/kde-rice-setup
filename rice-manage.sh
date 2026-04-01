#!/bin/bash
# rice-manage.sh — zarzadzanie KDE rice bez grzebania w systemie
# Uzycie: ./rice-manage.sh <komenda> [opcje]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Kolory ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()  { echo -e "${BLUE}::${NC} $1"; }
ok()    { echo -e "${GREEN}OK${NC} $1"; }
warn()  { echo -e "${YELLOW}!!${NC} $1"; }
fail()  { echo -e "${RED}BLAD${NC} $1"; }

# ============================================================
# TAPETA
# ============================================================
cmd_wallpaper() {
    case "$1" in
        set)
            if [[ -z "$2" ]]; then
                echo "Uzycie: rice-manage.sh wallpaper set <sciezka_do_pliku>"
                return 1
            fi
            local src="$2"
            if [[ ! -f "$src" ]]; then
                fail "Plik nie istnieje: $src"
                return 1
            fi
            mkdir -p ~/.local/share/wallpapers
            cp "$src" ~/.local/share/wallpapers/rice-wallpaper.png
            qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
            var allDesktops = desktops();
            for (var i = 0; i < allDesktops.length; i++) {
                var d = allDesktops[i];
                d.wallpaperPlugin = 'org.kde.image';
                d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
                d.writeConfig('Image', 'file://$HOME/.local/share/wallpapers/rice-wallpaper.png');
            }
            " 2>/dev/null
            ok "Tapeta ustawiona: $src"
            ;;
        darken)
            local src="${2:-$HOME/.local/share/wallpapers/rice-wallpaper.png}"
            local amount="${3:-10}"
            if [[ ! -f "$src" ]]; then
                fail "Brak tapety: $src"
                return 1
            fi
            local brightness=$((100 - amount))
            magick "$src" -modulate ${brightness},100,100 "$src"
            ok "Tapeta przyciemniona o ${amount}%"
            cmd_wallpaper set "$src"
            ;;
        lighten)
            local src="${2:-$HOME/.local/share/wallpapers/rice-wallpaper.png}"
            local amount="${3:-10}"
            if [[ ! -f "$src" ]]; then
                fail "Brak tapety: $src"
                return 1
            fi
            local brightness=$((100 + amount))
            magick "$src" -modulate ${brightness},100,100 "$src"
            ok "Tapeta rozjasniona o ${amount}%"
            cmd_wallpaper set "$src"
            ;;
        blur)
            local src="${2:-$HOME/.local/share/wallpapers/rice-wallpaper.png}"
            local radius="${3:-5}"
            if [[ ! -f "$src" ]]; then
                fail "Brak tapety: $src"
                return 1
            fi
            magick "$src" -blur 0x${radius} "$src"
            ok "Tapeta rozmyta (radius=${radius})"
            cmd_wallpaper set "$src"
            ;;
        reset)
            if [[ -f "$SCRIPT_DIR/wallpaper/wallpaper.png" ]]; then
                cmd_wallpaper set "$SCRIPT_DIR/wallpaper/wallpaper.png"
                ok "Tapeta przywrocona do domyslnej"
            else
                fail "Brak domyslnej tapety w $SCRIPT_DIR/wallpaper/"
            fi
            ;;
        *)
            echo "Uzycie: rice-manage.sh wallpaper <set|darken|lighten|blur|reset> [opcje]"
            echo ""
            echo "  set <plik>          — ustaw tapete"
            echo "  darken [plik] [%]   — przyciemnij (domyslnie 10%)"
            echo "  lighten [plik] [%]  — rozjasnij (domyslnie 10%)"
            echo "  blur [plik] [r]     — rozmyj (domyslnie radius=5)"
            echo "  reset               — przywroc domyslna tapete"
            ;;
    esac
}

# ============================================================
# PANEL
# ============================================================
cmd_panel() {
    case "$1" in
        opacity)
            local val="${2:-adaptive}"
            case "$val" in
                adaptive|auto) val=0 ;;
                opaque|solid)  val=1 ;;
                translucent)   val=2 ;;
                *)
                    if [[ ! "$val" =~ ^[0-2]$ ]]; then
                        echo "Uzycie: rice-manage.sh panel opacity <adaptive|opaque|translucent>"
                        return 1
                    fi
                    ;;
            esac
            kwriteconfig6 --file plasmashellrc --group "PlasmaViews" --group "Panel 23" --key panelOpacity "$val"
            ok "Gorny panel opacity: $val (0=adaptive, 1=opaque, 2=translucent)"
            info "Restart plasmashell wymagany (rice-manage.sh restart)"
            ;;
        thickness)
            local panel="${2:-top}"
            local size="$3"
            if [[ -z "$size" ]]; then
                echo "Uzycie: rice-manage.sh panel thickness <top|dock> <piksele>"
                return 1
            fi
            local panel_id
            case "$panel" in
                top)  panel_id=23 ;;
                dock|bottom) panel_id=54 ;;
                *) fail "Nieznany panel: $panel (uzyj top/dock)"; return 1 ;;
            esac
            kwriteconfig6 --file plasmashellrc --group "PlasmaViews" --group "Panel $panel_id" --group "Defaults" --key thickness "$size"
            ok "Panel $panel thickness: ${size}px"
            info "Restart plasmashell wymagany (rice-manage.sh restart)"
            ;;
        floating)
            local panel="${2:-dock}"
            local state="${3:-true}"
            local panel_id
            case "$panel" in
                top) panel_id=23 ;;
                dock|bottom) panel_id=54 ;;
                *) fail "Nieznany panel: $panel"; return 1 ;;
            esac
            local val=1
            [[ "$state" == "false" || "$state" == "off" || "$state" == "0" ]] && val=0
            kwriteconfig6 --file plasmashellrc --group "PlasmaViews" --group "Panel $panel_id" --key floating "$val"
            ok "Panel $panel floating: $val"
            info "Restart plasmashell wymagany (rice-manage.sh restart)"
            ;;
        *)
            echo "Uzycie: rice-manage.sh panel <opacity|thickness|floating>"
            echo ""
            echo "  opacity <adaptive|opaque|translucent>"
            echo "  thickness <top|dock> <piksele>"
            echo "  floating <top|dock> <true|false>"
            ;;
    esac
}

# ============================================================
# DOCK (dolny panel)
# ============================================================
cmd_dock() {
    case "$1" in
        add)
            local app="$2"
            if [[ -z "$app" ]]; then
                echo "Uzycie: rice-manage.sh dock add <nazwa.desktop>"
                echo "  Przyklady: kitty.desktop, brave-browser.desktop, org.kde.dolphin.desktop"
                echo ""
                echo "  Dostepne:"
                ls /usr/share/applications/*.desktop 2>/dev/null | xargs -I{} basename {} | sort | column
                return 1
            fi
            # Verify .desktop file exists
            if [[ ! -f "/usr/share/applications/$app" ]]; then
                fail "Nie znaleziono: /usr/share/applications/$app"
                return 1
            fi
            local cfg=~/.config/plasma-org.kde.plasma.desktop-appletsrc
            local current
            current=$(grep -A1 '\[Containments\]\[54\]\[Applets\]\[55\]\[Configuration\]\[General\]' "$cfg" | grep launchers= | sed 's/launchers=//')
            if echo "$current" | grep -q "$app"; then
                warn "$app juz jest w docku"
                return 0
            fi
            local new_launchers="${current},applications:${app}"
            sed -i "s|launchers=.*|launchers=${new_launchers}|" "$cfg"
            ok "Dodano $app do docka"
            info "Restart plasmashell wymagany (rice-manage.sh restart)"
            ;;
        remove)
            local app="$2"
            if [[ -z "$app" ]]; then
                echo "Uzycie: rice-manage.sh dock remove <nazwa.desktop>"
                return 1
            fi
            local cfg=~/.config/plasma-org.kde.plasma.desktop-appletsrc
            sed -i "s|,applications:${app}||g; s|applications:${app},||g; s|applications:${app}||g" "$cfg"
            ok "Usunieto $app z docka"
            info "Restart plasmashell wymagany (rice-manage.sh restart)"
            ;;
        list)
            local cfg=~/.config/plasma-org.kde.plasma.desktop-appletsrc
            local launchers
            launchers=$(grep -A1 '\[Containments\]\[54\]\[Applets\]\[55\]\[Configuration\]\[General\]' "$cfg" | grep launchers= | sed 's/launchers=//')
            echo -e "${BOLD}Aplikacje w docku:${NC}"
            echo "$launchers" | tr ',' '\n' | while read -r l; do
                echo "  - $l"
            done
            ;;
        *)
            echo "Uzycie: rice-manage.sh dock <add|remove|list>"
            echo ""
            echo "  add <app.desktop>    — dodaj aplikacje do docka"
            echo "  remove <app.desktop> — usun aplikacje z docka"
            echo "  list                 — pokaz aktualne aplikacje"
            ;;
    esac
}

# ============================================================
# EFEKTY KWin
# ============================================================
cmd_effects() {
    case "$1" in
        blur)
            local strength="${2:-8}"
            kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled true
            kwriteconfig6 --file kwinrc --group Effect-blur --key BlurStrength "$strength"
            kwriteconfig6 --file kwinrc --group Effect-blur --key NoiseStrength 0
            qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null
            ok "Blur wlaczony (sila: $strength/15)"
            ;;
        blur-off)
            kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled false
            qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null
            ok "Blur wylaczony"
            ;;
        corners)
            local size="${2:-10}"
            kwriteconfig6 --file kwinrc --group Plugins --key kwin_effect_rounded_cornersEnabled true
            kwriteconfig6 --file kwinrc --group Effect-kwin_effect_rounded_corners --key Size "$size"
            qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null
            ok "Zaokraglone rogi: ${size}px"
            ;;
        corners-off)
            kwriteconfig6 --file kwinrc --group Plugins --key kwin_effect_rounded_cornersEnabled false
            qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null
            ok "Zaokraglone rogi wylaczone"
            ;;
        dim)
            local strength="${2:-15}"
            kwriteconfig6 --file kwinrc --group Plugins --key diminactiveEnabled true
            kwriteconfig6 --file kwinrc --group Effect-diminactive --key Strength "$strength"
            qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null
            ok "Przyciemnianie nieaktywnych okien: ${strength}%"
            ;;
        dim-off)
            kwriteconfig6 --file kwinrc --group Plugins --key diminactiveEnabled false
            qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null
            ok "Przyciemnianie wylaczone"
            ;;
        gaps)
            local size="${2:-4}"
            kwriteconfig6 --file kwinrc --group Windows --key BorderlessMaximizedWindows true
            # Update tiling padding for all layouts
            local desktops
            desktops=$(kreadconfig6 --file kwinrc --group Desktops --key Number)
            info "Window gaps: ${size}px (dla tiling)"
            ok "Ustawiono BorderlessMaximizedWindows"
            ;;
        status)
            echo -e "${BOLD}Status efektow KWin:${NC}"
            for effect in blur kwin_effect_rounded_corners diminactive; do
                local enabled
                enabled=$(kreadconfig6 --file kwinrc --group Plugins --key "${effect}Enabled")
                local name
                case "$effect" in
                    blur) name="Blur" ;;
                    kwin_effect_rounded_corners) name="Rounded Corners" ;;
                    diminactive) name="Dim Inactive" ;;
                esac
                if [[ "$enabled" == "true" ]]; then
                    echo -e "  ${GREEN}ON${NC}  $name"
                else
                    echo -e "  ${RED}OFF${NC} $name"
                fi
            done
            ;;
        *)
            echo "Uzycie: rice-manage.sh effects <komenda> [opcje]"
            echo ""
            echo "  blur [sila 1-15]     — wlacz blur (domyslnie 8)"
            echo "  blur-off             — wylacz blur"
            echo "  corners [px]         — zaokraglone rogi (domyslnie 10px)"
            echo "  corners-off          — wylacz zaokraglenia"
            echo "  dim [sila 1-100]     — przyciemniaj nieaktywne okna"
            echo "  dim-off              — wylacz przyciemnianie"
            echo "  gaps [px]            — window gaps dla tiling"
            echo "  status               — pokaz status efektow"
            ;;
    esac
}

# ============================================================
# MOTYW / KOLORY
# ============================================================
cmd_theme() {
    case "$1" in
        dark)
            plasma-apply-desktoptheme Qogir-dark
            plasma-apply-colorscheme QogirManjaroDark
            /usr/lib/plasma-changeicons Papirus-Dark 2>/dev/null
            kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme "__aurorae__svg__Qogir-dark"
            kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle "kvantum"
            mkdir -p ~/.config/Kvantum
            echo -e "[General]\ntheme=Qogir-dark" > ~/.config/Kvantum/kvantum.kvconfig
            # Fix hardcoded light colors in upstream SVGs
            find ~/.local/share/plasma/desktoptheme/Qogir-dark -name '*.svg' -exec sed -i \
                -e 's/color:#eff0f1/color:#282a33/g' \
                -e 's/stop-color:#eff0f1/stop-color:#282a33/g' \
                -e 's/color:#fcfcfc/color:#30333d/g' \
                -e 's/stop-color:#fcfcfc/stop-color:#30333d/g' \
                -e 's/color:#31363b/color:#d3dae3/g' \
                -e 's/stop-color:#31363b/stop-color:#d3dae3/g' \
                {} +
            qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null
            ok "Motyw ciemny (Qogir-dark) zastosowany"
            ;;
        light)
            plasma-apply-desktoptheme Qogir-light
            plasma-apply-colorscheme QogirLight
            /usr/lib/plasma-changeicons Papirus-Light 2>/dev/null
            kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme "__aurorae__svg__Qogir"
            mkdir -p ~/.config/Kvantum
            echo -e "[General]\ntheme=Qogir-light" > ~/.config/Kvantum/kvantum.kvconfig
            qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null
            ok "Motyw jasny (Qogir-light) zastosowany"
            ;;
        info)
            echo -e "${BOLD}Aktualny motyw:${NC}"
            echo "  Plasma:     $(kreadconfig6 --file plasmarc --group Theme --key name)"
            echo "  Kolory:     $(kreadconfig6 --file kdeglobals --group General --key ColorScheme)"
            echo "  Ikony:      $(kreadconfig6 --file kdeglobals --group Icons --key Theme)"
            echo "  Dekoracja:  $(kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme)"
            echo "  Kursor:     $(kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme)"
            echo "  Widget:     $(kreadconfig6 --file kdeglobals --group KDE --key widgetStyle)"
            echo "  Kvantum:    $(grep theme= ~/.config/Kvantum/kvantum.kvconfig 2>/dev/null | cut -d= -f2)"
            ;;
        *)
            echo "Uzycie: rice-manage.sh theme <dark|light|info>"
            ;;
    esac
}

# ============================================================
# CZCIONKI
# ============================================================
cmd_fonts() {
    case "$1" in
        set)
            local font="${2:-IBM Plex Mono}"
            local size="${3:-10}"
            kwriteconfig6 --file kdeglobals --group General --key font "$font,$size,-1,5,50,0,0,0,0,0"
            kwriteconfig6 --file kdeglobals --group General --key menuFont "$font,$size,-1,5,50,0,0,0,0,0"
            kwriteconfig6 --file kdeglobals --group General --key toolBarFont "$font,$((size-1)),-1,5,50,0,0,0,0,0"
            kwriteconfig6 --file kdeglobals --group General --key smallestReadableFont "$font,$((size-2)),-1,5,50,0,0,0,0,0"
            ok "Czcionka systemowa: $font ${size}pt"
            info "Wyloguj/zaloguj aby zastosowac"
            ;;
        terminal)
            local font="${2:-JetBrains Mono}"
            local size="${3:-11}"
            if [[ -f ~/.config/kitty/kitty.conf ]]; then
                sed -i "s/^font_family .*/font_family      $font/" ~/.config/kitty/kitty.conf
                sed -i "s/^font_size .*/font_size        $size/" ~/.config/kitty/kitty.conf
                ok "Czcionka kitty: $font ${size}pt"
                info "Zrestartuj kitty aby zastosowac"
            fi
            ;;
        info)
            echo -e "${BOLD}Czcionki:${NC}"
            echo "  System:   $(kreadconfig6 --file kdeglobals --group General --key font)"
            echo "  Fixed:    $(kreadconfig6 --file kdeglobals --group General --key fixed)"
            if [[ -f ~/.config/kitty/kitty.conf ]]; then
                echo "  Kitty:    $(grep '^font_family' ~/.config/kitty/kitty.conf | sed 's/font_family *//')"
                echo "  Size:     $(grep '^font_size' ~/.config/kitty/kitty.conf | sed 's/font_size *//')"
            fi
            ;;
        *)
            echo "Uzycie: rice-manage.sh fonts <set|terminal|info>"
            echo ""
            echo "  set [czcionka] [rozmiar]       — zmien czcionke systemowa"
            echo "  terminal [czcionka] [rozmiar]  — zmien czcionke kitty"
            echo "  info                           — pokaz aktualne czcionki"
            ;;
    esac
}

# ============================================================
# TERMINAL (kitty)
# ============================================================
cmd_terminal() {
    case "$1" in
        opacity)
            local val="${2:-0.92}"
            if [[ -f ~/.config/kitty/kitty.conf ]]; then
                sed -i "s/^background_opacity .*/background_opacity $val/" ~/.config/kitty/kitty.conf
                ok "Kitty opacity: $val"
                info "Zrestartuj kitty aby zastosowac"
            fi
            ;;
        padding)
            local val="${2:-8 12}"
            if [[ -f ~/.config/kitty/kitty.conf ]]; then
                sed -i "s/^window_padding_width .*/window_padding_width $val/" ~/.config/kitty/kitty.conf
                ok "Kitty padding: $val"
            fi
            ;;
        info)
            echo -e "${BOLD}Konfiguracja kitty:${NC}"
            grep -E "^(font_|background_opacity|window_padding|tab_bar|shell )" ~/.config/kitty/kitty.conf 2>/dev/null | while read -r line; do
                echo "  $line"
            done
            ;;
        *)
            echo "Uzycie: rice-manage.sh terminal <opacity|padding|info>"
            echo ""
            echo "  opacity [0.0-1.0]   — przezroczystosc (domyslnie 0.92)"
            echo "  padding [px]        — padding okna (domyslnie '8 12')"
            echo "  info                — pokaz konfiguracje"
            ;;
    esac
}

# ============================================================
# PULPITY WIRTUALNE
# ============================================================
cmd_desktops() {
    case "$1" in
        set)
            local num="${2:-3}"
            kwriteconfig6 --file kwinrc --group Desktops --key Number "$num"
            kwriteconfig6 --file kwinrc --group Desktops --key Rows 1
            qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null
            ok "Liczba pulpitow: $num"
            ;;
        info)
            local num
            num=$(kreadconfig6 --file kwinrc --group Desktops --key Number)
            echo "Pulpity wirtualne: ${num:-1}"
            ;;
        *)
            echo "Uzycie: rice-manage.sh desktops <set|info> [liczba]"
            ;;
    esac
}

# ============================================================
# KURSOR
# ============================================================
cmd_cursor() {
    case "$1" in
        set)
            local theme="${2:-Bibata-Modern-Classic}"
            local size="${3:-24}"
            kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "$theme"
            kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize "$size"
            kwriteconfig6 --file kdeglobals --group KDE --key cursorTheme "$theme"
            ok "Kursor: $theme (${size}px)"
            info "Wyloguj/zaloguj aby zastosowac"
            ;;
        list)
            echo -e "${BOLD}Dostepne motywy kursora:${NC}"
            find /usr/share/icons ~/.local/share/icons -name "cursors" -type d 2>/dev/null | \
                sed 's|.*/icons/||; s|/cursors||' | sort -u | while read -r t; do
                echo "  - $t"
            done
            ;;
        info)
            echo "Kursor: $(kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme) ($(kreadconfig6 --file kcminputrc --group Mouse --key cursorSize)px)"
            ;;
        *)
            echo "Uzycie: rice-manage.sh cursor <set|list|info>"
            echo ""
            echo "  set [motyw] [rozmiar]  — zmien kursor (domyslnie Bibata-Modern-Classic 24px)"
            echo "  list                   — pokaz dostepne motywy"
            echo "  info                   — aktualny kursor"
            ;;
    esac
}

# ============================================================
# IKONY
# ============================================================
cmd_icons() {
    case "$1" in
        desktop)
            local size="${2:-48}"
            kwriteconfig6 --file kdeglobals --group DesktopIcons --key Size "$size"
            ok "Ikony pulpitu: ${size}px"
            info "Wyloguj/zaloguj aby zastosowac"
            ;;
        panel)
            local size="${2:-22}"
            kwriteconfig6 --file kdeglobals --group PanelIcons --key Size "$size"
            ok "Ikony panelu: ${size}px"
            info "Wyloguj/zaloguj aby zastosowac"
            ;;
        toolbar)
            local size="${2:-22}"
            kwriteconfig6 --file kdeglobals --group ToolbarIcons --key Size "$size"
            kwriteconfig6 --file kdeglobals --group MainToolbarIcons --key Size "$size"
            ok "Ikony paska narzedzi: ${size}px"
            ;;
        small)
            local size="${2:-16}"
            kwriteconfig6 --file kdeglobals --group SmallIcons --key Size "$size"
            ok "Male ikony: ${size}px"
            ;;
        dialog)
            local size="${2:-32}"
            kwriteconfig6 --file kdeglobals --group DialogIcons --key Size "$size"
            ok "Ikony dialogow: ${size}px"
            ;;
        all)
            local size="${2:-22}"
            cmd_icons desktop "$((size * 2))"
            cmd_icons panel "$size"
            cmd_icons toolbar "$size"
            cmd_icons small "$((size - 6 > 12 ? size - 6 : 12))"
            cmd_icons dialog "$((size + 10))"
            ;;
        info)
            echo -e "${BOLD}Rozmiary ikon:${NC}"
            echo "  Pulpit:         $(kreadconfig6 --file kdeglobals --group DesktopIcons --key Size)px"
            echo "  Panel:          $(kreadconfig6 --file kdeglobals --group PanelIcons --key Size)px"
            echo "  Pasek narzedzi: $(kreadconfig6 --file kdeglobals --group ToolbarIcons --key Size)px"
            echo "  Male:           $(kreadconfig6 --file kdeglobals --group SmallIcons --key Size)px"
            echo "  Dialogi:        $(kreadconfig6 --file kdeglobals --group DialogIcons --key Size)px"
            ;;
        *)
            echo "Uzycie: rice-manage.sh icons <desktop|panel|toolbar|small|dialog|all|info> [px]"
            echo ""
            echo "  desktop [px]   — ikony na pulpicie (domyslnie 48)"
            echo "  panel [px]     — ikony w panelu (domyslnie 22)"
            echo "  toolbar [px]   — ikony paska narzedzi (domyslnie 22)"
            echo "  small [px]     — male ikony w menu (domyslnie 16)"
            echo "  dialog [px]    — ikony w dialogach (domyslnie 32)"
            echo "  all [px]       — ustaw wszystkie proporcjonalnie"
            echo "  info           — pokaz aktualne rozmiary"
            ;;
    esac
}

# ============================================================
# PRZEZROCZYSTOSC
# ============================================================
cmd_transparency() {
    case "$1" in
        panel)
            local val="${2:-0.8}"
            # Panel opacity via D-Bus (0.0 = fully transparent, 1.0 = opaque)
            qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
            var panels = panels();
            for (var i = 0; i < panels.length; i++) {
                panels[i].opacity = $val;
            }
            " 2>/dev/null
            # Also set in plasmashellrc for persistence
            kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel 23" --key panelOpacity 2
            ok "Przezroczystosc panelu: $val"
            ;;
        dock)
            local val="${2:-0.8}"
            kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel 54" --key panelOpacity 2
            ok "Przezroczystosc docka: translucent"
            info "Restart plasmashell wymagany (rice-manage.sh restart)"
            ;;
        windows)
            local val="${2:-85}"
            # KWin active/inactive window opacity via window rules
            kwriteconfig6 --file kwinrc --group Plugins --key forceblurEnabled true
            kwriteconfig6 --file kwinrc --group Effect-blur --key BlurStrength 8
            info "Przezroczystosc okien wymaga regul KWin lub ustawien per-aplikacja"
            info "Uzyj: Ustawienia systemowe > Reguly okien > Dodaj regule z 'Opacity'"
            info "Lub ustaw per-terminal: rice-manage.sh terminal opacity $val"
            ;;
        kitty)
            local val="${2:-0.85}"
            cmd_terminal opacity "$val"
            ;;
        info)
            echo -e "${BOLD}Przezroczystosc:${NC}"
            local panel_op
            panel_op=$(kreadconfig6 --file plasmashellrc --group PlasmaViews --group "Panel 23" --key panelOpacity)
            case "$panel_op" in
                0) echo "  Panel:   adaptive" ;;
                1) echo "  Panel:   opaque" ;;
                2) echo "  Panel:   translucent" ;;
                *) echo "  Panel:   $panel_op" ;;
            esac
            if [[ -f ~/.config/kitty/kitty.conf ]]; then
                echo "  Kitty:   $(grep '^background_opacity' ~/.config/kitty/kitty.conf 2>/dev/null | awk '{print $2}')"
            fi
            ;;
        *)
            echo "Uzycie: rice-manage.sh transparency <panel|dock|kitty|windows|info>"
            echo ""
            echo "  panel [0.0-1.0]    — przezroczystosc gornego panelu"
            echo "  dock [0.0-1.0]     — przezroczystosc docka"
            echo "  kitty [0.0-1.0]    — przezroczystosc terminala (domyslnie 0.85)"
            echo "  windows            — informacje o przezroczystosci okien"
            echo "  info               — pokaz aktualne ustawienia"
            ;;
    esac
}

# ============================================================
# ANIMACJE
# ============================================================
cmd_animations() {
    case "$1" in
        speed)
            local val="${2:-0.5}"
            kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor "$val"
            ok "Szybkosc animacji: $val (0=natychmiast, 1=normalna)"
            ;;
        off)
            kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 0
            ok "Animacje wylaczone"
            ;;
        info)
            local val
            val=$(kreadconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor)
            echo "Szybkosc animacji: ${val:-1} (0=natychmiast, 1=normalna)"
            ;;
        *)
            echo "Uzycie: rice-manage.sh animations <speed|off|info>"
            echo ""
            echo "  speed [0.0-1.0]  — ustaw szybkosc (domyslnie 0.5)"
            echo "  off              — wylacz animacje"
            echo "  info             — pokaz aktualne"
            ;;
    esac
}

# ============================================================
# PRZYCISKI OKIEN
# ============================================================
cmd_buttons() {
    case "$1" in
        mac|left)
            kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft "XAI"
            kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight ""
            qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null
            ok "Przyciski okien: styl macOS (zamknij, maks, mini — po lewej)"
            ;;
        windows|right)
            kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft "M"
            kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"
            qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null
            ok "Przyciski okien: styl Windows (mini, maks, zamknij — po prawej)"
            ;;
        info)
            echo -e "${BOLD}Przyciski okien:${NC}"
            echo "  Lewa:  $(kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft)"
            echo "  Prawa: $(kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight)"
            echo "  (M=menu, X=zamknij, A=maksymalizuj, I=minimalizuj)"
            ;;
        *)
            echo "Uzycie: rice-manage.sh buttons <mac|windows|info>"
            echo ""
            echo "  mac / left      — przyciski po lewej (styl macOS)"
            echo "  windows / right — przyciski po prawej (styl Windows)"
            echo "  info            — pokaz aktualny uklad"
            ;;
    esac
}

# ============================================================
# RESTART / BACKUP / EXPORT
# ============================================================
cmd_restart() {
    info "Restartowanie plasmashell..."
    kquitapp6 plasmashell 2>/dev/null || true
    sleep 2
    kstart plasmashell 2>/dev/null &
    sleep 4
    # Re-apply dock settings
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    var panels = panels();
    for (var i = 0; i < panels.length; i++) {
        if (panels[i].location == 'bottom') {
            panels[i].alignment = 'center';
            panels[i].lengthMode = 'fit';
        }
    }
    " 2>/dev/null
    ok "Plasmashell zrestartowany"
}

cmd_backup() {
    local dir="${1:-$SCRIPT_DIR/backup-$(date +%Y%m%d-%H%M%S)}"
    mkdir -p "$dir"
    cp ~/.config/plasma-org.kde.plasma.desktop-appletsrc "$dir/plasma-appletsrc" 2>/dev/null
    cp ~/.config/plasmashellrc "$dir/plasmashellrc" 2>/dev/null
    cp ~/.config/kwinrc "$dir/kwinrc" 2>/dev/null
    cp ~/.config/kdeglobals "$dir/kdeglobals" 2>/dev/null
    cp ~/.config/kcminputrc "$dir/kcminputrc" 2>/dev/null
    cp ~/.config/kitty/kitty.conf "$dir/kitty.conf" 2>/dev/null
    cp ~/.config/starship.toml "$dir/starship.toml" 2>/dev/null
    cp ~/.config/Kvantum/kvantum.kvconfig "$dir/kvantum.kvconfig" 2>/dev/null
    ok "Backup zapisany: $dir"
}

cmd_export() {
    info "Eksportowanie aktualnej konfiguracji do $SCRIPT_DIR/configs/..."
    cp ~/.config/plasma-org.kde.plasma.desktop-appletsrc "$SCRIPT_DIR/configs/plasma-appletsrc"
    cp ~/.config/plasmashellrc "$SCRIPT_DIR/configs/plasmashellrc"
    cp ~/.config/kitty/kitty.conf "$SCRIPT_DIR/configs/kitty.conf"
    cp ~/.config/starship.toml "$SCRIPT_DIR/configs/starship.toml"
    cp ~/.local/share/wallpapers/rice-wallpaper.png "$SCRIPT_DIR/wallpaper/wallpaper.png" 2>/dev/null
    ok "Konfiguracja wyeksportowana"
}

cmd_status() {
    echo ""
    echo -e "${BOLD}  KDE Rice — Status${NC}"
    echo -e "  ──────────────────"
    echo ""
    cmd_theme info
    echo ""
    cmd_cursor info
    echo ""
    cmd_fonts info
    echo ""
    cmd_desktops info
    echo ""
    cmd_effects status
    echo ""
    cmd_icons info
    echo ""
    cmd_transparency info
    echo ""
    cmd_animations info
    echo ""
    cmd_buttons info
    echo ""
    cmd_terminal info
    echo ""
    cmd_dock list
    echo ""
}

# ============================================================
# HELP
# ============================================================
cmd_help() {
    echo ""
    echo -e "${BOLD}  rice-manage.sh${NC} — zarzadzanie KDE rice"
    echo -e "  ────────────────────────────────────────"
    echo ""
    echo -e "  ${CYAN}Wygląd:${NC}"
    echo "    wallpaper <set|darken|lighten|blur|reset>  — tapeta"
    echo "    theme <dark|light|info>                    — motyw Qogir"
    echo "    cursor <set|list|info>                     — motyw kursora"
    echo "    fonts <set|terminal|info>                  — czcionki"
    echo ""
    echo -e "  ${CYAN}Panele:${NC}"
    echo "    panel <opacity|thickness|floating>         — ustawienia paneli"
    echo "    dock <add|remove|list>                     — aplikacje w docku"
    echo ""
    echo -e "  ${CYAN}Efekty:${NC}"
    echo "    effects <blur|corners|dim|gaps|status>     — efekty KWin"
    echo "    transparency <panel|dock|kitty|info>       — przezroczystosc"
    echo "    animations <speed|off|info>                — szybkosc animacji"
    echo "    desktops <set|info>                        — pulpity wirtualne"
    echo ""
    echo -e "  ${CYAN}Ikony i okna:${NC}"
    echo "    icons <desktop|panel|toolbar|all|info>     — rozmiary ikon"
    echo "    buttons <mac|windows|info>                 — przyciski okien"
    echo ""
    echo -e "  ${CYAN}Terminal:${NC}"
    echo "    terminal <opacity|padding|info>            — ustawienia kitty"
    echo ""
    echo -e "  ${CYAN}System:${NC}"
    echo "    restart                                    — restart plasmashell"
    echo "    backup [dir]                               — backup konfiguracji"
    echo "    export                                     — eksport do ~/kde-rice-setup/"
    echo "    status                                     — pokaz wszystko"
    echo ""
    echo -e "  ${DIM}Przyklady:${NC}"
    echo "    ./rice-manage.sh wallpaper set ~/foto.jpg"
    echo "    ./rice-manage.sh effects blur 12"
    echo "    ./rice-manage.sh dock add brave-browser.desktop"
    echo "    ./rice-manage.sh panel thickness dock 56"
    echo "    ./rice-manage.sh terminal opacity 0.85"
    echo "    ./rice-manage.sh icons all 24"
    echo "    ./rice-manage.sh transparency panel 0.7"
    echo "    ./rice-manage.sh buttons mac"
    echo "    ./rice-manage.sh animations speed 0.3"
    echo ""
}

# ============================================================
# ROUTER
# ============================================================
case "${1:-help}" in
    wallpaper)  shift; cmd_wallpaper "$@" ;;
    panel)      shift; cmd_panel "$@" ;;
    dock)       shift; cmd_dock "$@" ;;
    effects)    shift; cmd_effects "$@" ;;
    theme)      shift; cmd_theme "$@" ;;
    fonts)      shift; cmd_fonts "$@" ;;
    terminal)   shift; cmd_terminal "$@" ;;
    desktops)   shift; cmd_desktops "$@" ;;
    cursor)       shift; cmd_cursor "$@" ;;
    icons)        shift; cmd_icons "$@" ;;
    transparency) shift; cmd_transparency "$@" ;;
    animations)   shift; cmd_animations "$@" ;;
    buttons)      shift; cmd_buttons "$@" ;;
    restart)      shift; cmd_restart "$@" ;;
    backup)     shift; cmd_backup "$@" ;;
    export)     shift; cmd_export "$@" ;;
    status)     shift; cmd_status "$@" ;;
    help|--help|-h) cmd_help ;;
    *)
        fail "Nieznana komenda: $1"
        cmd_help
        exit 1
        ;;
esac
