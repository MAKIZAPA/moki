#!/usr/bin/env bash
# ==============================================================================
# ✨ MOKI - Script de Instalación Universal
# Compatible con Arch / CachyOS, Debian / Ubuntu, Fedora
# Soporte de GPU: NVIDIA, AMD Radeon e Intel (Vulkan + VA-API / NVDEC)
# Autor: makizapa
# ==============================================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_BIN="$HOME/.local/bin"
TARGET_MPV="$HOME/.config/mpv"
TARGET_DATA="$HOME/.config/streaming-cli"

clear 2>/dev/null || true
echo -e "${CYAN}${BOLD}"
echo "  __  __  ___  _  _____ "
echo " |  \/  |/ _ \| |/ /_ _|"
echo " | |\/| | | | | ' / | | "
echo " | |  | | |_| | . \ | | "
echo " |_|  |_|\___/|_|\_\___|"
echo -e "${NC}"
echo -e "${PURPLE}${BOLD} ✨ Instalador Universal de MOKI (Streaming Suite de Terminal)${NC}"
echo -e "${BLUE} Creado por: ${YELLOW}makizapa${NC}\n"

# ------------------------------------------------------------------------------
# 1. Detección de Distribución y Gestor de Paquetes
# ------------------------------------------------------------------------------
echo -e "${YELLOW}🔍 [1/6] Detectando sistema operativo y gestor de paquetes...${NC}"

PKG_MANAGER=""
if command -v pacman &>/dev/null; then
    PKG_MANAGER="pacman"
    echo -e "   ${GREEN}➔ Sistema basado en Arch / CachyOS detectado (pacman)${NC}"
elif command -v apt-get &>/dev/null; then
    PKG_MANAGER="apt"
    echo -e "   ${GREEN}➔ Sistema basado en Debian / Ubuntu detectado (apt)${NC}"
elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
    echo -e "   ${GREEN}➔ Sistema basado en Fedora / RHEL detectado (dnf)${NC}"
else
    echo -e "   ${YELLOW}⚠️  No se reconoció un gestor de paquetes estándar (pacman/apt/dnf). Se asumirá que las dependencias ya están instaladas.${NC}"
fi

# ------------------------------------------------------------------------------
# 2. Detección de Tarjeta Gráfica (GPU) y Aceleración por Hardware
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}🎮 [2/6] Detectando GPU y aceleración por hardware...${NC}"

GPU_VENDOR="generic"
GPU_INFO=$(lspci 2>/dev/null | grep -Ei "vga|3d|display" || true)

if echo "$GPU_INFO" | grep -qi "nvidia"; then
    GPU_VENDOR="nvidia"
    GPU_NAME=$(echo "$GPU_INFO" | grep -i "nvidia" | sed -E 's/.*controller: //; s/.*\[//; s/\].*//' | head -n1)
    echo -e "   ${GREEN}➔ GPU NVIDIA detectada:${NC} ${BOLD}${GPU_NAME:-NVIDIA Graphics}${NC}"
    echo -e "   ${CYAN}  • Motor óptimo: Vulkan (gpu-next) + Decodificación NVDEC${NC}"
elif echo "$GPU_INFO" | grep -qi "amd\|radeon\|advanced micro devices"; then
    GPU_VENDOR="amd"
    GPU_NAME=$(echo "$GPU_INFO" | grep -Ei "amd|radeon" | head -n1)
    echo -e "   ${GREEN}➔ GPU AMD Radeon detectada:${NC} ${BOLD}${GPU_NAME:-AMD Radeon}${NC}"
    echo -e "   ${CYAN}  • Motor óptimo: Vulkan (RADV) + Decodificación VA-API (Mesa)${NC}"
elif echo "$GPU_INFO" | grep -qi "intel"; then
    GPU_VENDOR="intel"
    GPU_NAME=$(echo "$GPU_INFO" | grep -i "intel" | head -n1)
    echo -e "   ${GREEN}➔ GPU Intel detectada:${NC} ${BOLD}${GPU_NAME:-Intel Graphics}${NC}"
    echo -e "   ${CYAN}  • Motor óptimo: Vulkan (ANV) + Decodificación VA-API / QSV${NC}"
else
    echo -e "   ${YELLOW}➔ GPU genérica o máquina virtual detectada${NC}"
    echo -e "   ${CYAN}  • Motor óptimo: Auto (gpu-next con fallback universal)${NC}"
fi

# ------------------------------------------------------------------------------
# 3. Instalación de Dependencias del Sistema
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}📦 [3/6] Verificando e instalando dependencias del sistema...${NC}"

install_deps() {
    case "$PKG_MANAGER" in
        pacman)
            local packages=(mpv fzf jq python nodejs npm)
            if [ "$GPU_VENDOR" == "nvidia" ]; then
                packages+=(vulkan-icd-loader)
            elif [ "$GPU_VENDOR" == "amd" ]; then
                packages+=(vulkan-radeon libva-mesa-driver)
            elif [ "$GPU_VENDOR" == "intel" ]; then
                packages+=(vulkan-intel intel-media-driver)
            fi

            echo -e "   ${CYAN}Instalando paquetes requeridos con pacman...${NC}"
            if command -v sudo &>/dev/null; then
                sudo pacman -S --needed --noconfirm "${packages[@]}"
            else
                pacman -S --needed --noconfirm "${packages[@]}"
            fi
            ;;
        apt)
            local packages=(mpv fzf jq python3 nodejs npm curl)
            if [ "$GPU_VENDOR" == "amd" ] || [ "$GPU_VENDOR" == "intel" ]; then
                packages+=(mesa-vulkan-drivers va-driver-all)
            elif [ "$GPU_VENDOR" == "nvidia" ]; then
                packages+=(libvulkan1)
            fi

            echo -e "   ${CYAN}Instalando paquetes requeridos con apt...${NC}"
            if command -v sudo &>/dev/null; then
                sudo apt-get update -y
                sudo apt-get install -y "${packages[@]}"
            else
                apt-get update -y
                apt-get install -y "${packages[@]}"
            fi
            ;;
        dnf)
            local packages=(mpv fzf jq python3 nodejs npm)
            echo -e "   ${CYAN}Instalando paquetes requeridos con dnf...${NC}"
            if command -v sudo &>/dev/null; then
                sudo dnf install -y "${packages[@]}"
            else
                dnf install -y "${packages[@]}"
            fi
            ;;
    esac
}

# Solo intentar instalar paquetes si se detectó un gestor y faltan herramientas
MISSING_TOOLS=()
for tool in mpv fzf jq node npm; do
    if ! command -v "$tool" &>/dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo -e "   ${YELLOW}Faltan herramientas esenciales: ${MISSING_TOOLS[*]}${NC}"
    if [ -n "$PKG_MANAGER" ]; then
        install_deps
    else
        echo -e "   ${RED}Por favor instala manualmente: mpv, fzf, jq, nodejs, npm${NC}"
    fi
else
    echo -e "   ${GREEN}✓ Todas las dependencias principales ya están instaladas.${NC}"
fi

# Instalar webtorrent-cli si no existe
if ! command -v webtorrent &>/dev/null; then
    echo -e "   ${CYAN}Instalando webtorrent-cli vía npm...${NC}"
    # Configurar prefijo local si no tenemos permisos root para npm global
    if [ ! -w "$(npm root -g 2>/dev/null)" ] 2>/dev/null && command -v sudo &>/dev/null; then
        sudo npm install -g webtorrent-cli
    else
        npm install -g webtorrent-cli || {
            mkdir -p "$HOME/.npm-global"
            npm config set prefix "$HOME/.npm-global"
            export PATH="$HOME/.npm-global/bin:$PATH"
            npm install -g webtorrent-cli
        }
    fi
    echo -e "   ${GREEN}✓ webtorrent-cli instalado correctamente.${NC}"
else
    echo -e "   ${GREEN}✓ webtorrent-cli ya se encuentra instalado.${NC}"
fi

# ------------------------------------------------------------------------------
# 4. Instalación de Comandos y Scripts (~/.local/bin)
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}🚀 [4/6] Instalando ejecutables de MOKI en ~/.local/bin...${NC}"

mkdir -p "$TARGET_BIN"
mkdir -p "$TARGET_DATA"

cp "$SCRIPT_DIR/bin/"* "$TARGET_BIN/"
chmod +x "$TARGET_BIN/moki"
chmod +x "$TARGET_BIN/anime"*
chmod +x "$TARGET_BIN/serie"*
chmod +x "$TARGET_BIN/latino"*
chmod +x "$TARGET_BIN/audio-aligner"*
chmod +x "$TARGET_BIN/continuar"
chmod +x "$TARGET_BIN/limpiar"*

# Crear enlace pelis -> serie
ln -sf "$TARGET_BIN/serie" "$TARGET_BIN/pelis"

echo -e "   ${GREEN}✓ Comandos instalados: moki, anime, serie, pelis, latino, continuar, limpiar${NC}"

# ------------------------------------------------------------------------------
# 5. Configuración Universal de MPV y Shaders Anime4K
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}🎬 [5/6] Configurando mpv, scripts Lua y shaders para tu GPU (${GPU_VENDOR^^})...${NC}"

mkdir -p "$TARGET_MPV/scripts"
mkdir -p "$TARGET_MPV/shaders"

# Backup de configuración anterior si existe
if [ -f "$TARGET_MPV/mpv.conf" ] && [ ! -f "$TARGET_MPV/mpv.conf.moki_backup" ]; then
    cp "$TARGET_MPV/mpv.conf" "$TARGET_MPV/mpv.conf.moki_backup"
    echo -e "   ${BLUE}ℹ️  Se respaldó tu mpv.conf anterior en mpv.conf.moki_backup${NC}"
fi

# Copiar scripts Lua y atajos de teclado
cp -r "$SCRIPT_DIR/mpv/scripts/"* "$TARGET_MPV/scripts/"
cp "$SCRIPT_DIR/mpv/input.conf" "$TARGET_MPV/input.conf"

# Copiar shaders Anime4K si existen en el repo
if [ -d "$SCRIPT_DIR/mpv/shaders" ] && [ "$(ls -A "$SCRIPT_DIR/mpv/shaders" 2>/dev/null)" ]; then
    cp -r "$SCRIPT_DIR/mpv/shaders/"* "$TARGET_MPV/shaders/"
    echo -e "   ${GREEN}✓ Shaders Anime4K instalados correctamente.${NC}"
else
    echo -e "   ${CYAN}Descargando shaders Anime4K oficiales...${NC}"
    curl -sL "https://github.com/bloc97/Anime4K/releases/download/v4.0.1/Anime4K_v4.0.zip" -o "/tmp/Anime4K.zip" 2>/dev/null && \
    unzip -qo "/tmp/Anime4K.zip" -d "$TARGET_MPV/shaders/" 2>/dev/null && rm -f "/tmp/Anime4K.zip" || true
fi

# Generar mpv.conf optimizado para la GPU detectada
cat <<EOF > "$TARGET_MPV/mpv.conf"
# ==========================================
# ✨ MOKI - Configuración Óptima de MPV
# Generado automáticamente para GPU: ${GPU_VENDOR^^}
# ==========================================

# Aceleración de Video por Hardware
vo=gpu-next
gpu-api=auto
hwdec=auto-safe

# Calidad de Escalado y Renderizado
scale=ewa_lanczos
cscale=ewa_lanczos
dscale=mitchell
correct-downscaling=yes
linear-downscaling=yes

# Idiomas Preferidos (Español Latino prioritario, Español España, Japonés, Inglés)
alang=es-419,es-la,lat,latino,es,spa,ja,jpn,en
slang=es-419,es-la,lat,latino,es,spa,en
audio-pitch-correction=yes

# Subtítulos Estilizados
sub-auto=fuzzy
sub-font='sans-serif'
sub-font-size=48
sub-border-size=2.5

# Búfer y Streaming Fluido (Memoria RAM)
cache=yes
demuxer-max-bytes=250M
demuxer-max-back-bytes=100M

# Compatibilidad con streams de audio web
user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0"
referrer="https://flaswish.com/"
EOF

echo -e "   ${GREEN}✓ mpv.conf, input.conf y 5 scripts Lua instalados.${NC}"

# ------------------------------------------------------------------------------
# 6. Verificación de la variable PATH
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}🧭 [6/6] Verificando acceso en tu terminal ($PATH)...${NC}"

add_to_shell_rc() {
    local rc_file="$1"
    if [ -f "$rc_file" ] && ! grep -q '\.local/bin' "$rc_file"; then
        echo -e '\n# MOKI Streaming Suite' >> "$rc_file"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc_file"
        echo -e "   ${GREEN}✓ Agregado ~/.local/bin a ${rc_file}${NC}"
    fi
}

add_to_shell_rc "$HOME/.bashrc"
add_to_shell_rc "$HOME/.zshrc"

if [ -f "$HOME/.config/fish/config.fish" ] && ! grep -q '\.local/bin' "$HOME/.config/fish/config.fish"; then
    echo -e '\n# MOKI Streaming Suite' >> "$HOME/.config/fish/config.fish"
    echo 'fish_add_path -g $HOME/.local/bin' >> "$HOME/.config/fish/config.fish"
    echo -e "   ${GREEN}✓ Agregado ~/.local/bin a Fish shell${NC}"
fi

# ------------------------------------------------------------------------------
# Resumen Final
# ------------------------------------------------------------------------------
echo -e "\n${GREEN}${BOLD}══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  🎉 ¡INSTALACIÓN DE MOKI COMPLETADA CON ÉXITO!               ${NC}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Comandos listos para usar en tu terminal:${NC}"
echo -e "  • ${YELLOW}moki${NC}                 ➔ Menú interactivo con todo integrado"
echo -e "  • ${YELLOW}anime <nombre>${NC}       ➔ Búsqueda y streaming de anime en Nyaa"
echo -e "  • ${YELLOW}serie <nombre>${NC}       ➔ Streaming de series (Netflix, HBO, Disney, etc.)"
echo -e "  • ${YELLOW}pelis <nombre>${NC}       ➔ Streaming directo de películas en 4K/1080p"
echo -e "  • ${YELLOW}continuar${NC}            ➔ Tu historial inteligente de reanudación"
echo -e "  • ${YELLOW}limpiar${NC}              ➔ Mantenimiento y liberación de memoria RAM"
echo -e ""
echo -e "${PURPLE}Atajos útiles dentro de MPV:${NC}"
echo -e "  • ${YELLOW}[Shift + N]${NC}        ➔ Salta al siguiente episodio al instante (Modo Maratón)"
echo -e "  • ${YELLOW}[TAB]${NC}              ➔ Salta el Opening automáticamente (AniSkip)"
echo -e "  • ${YELLOW}[a]${NC}                ➔ Alterna pista de audio activa"
echo -e "  • ${YELLOW}[L]${NC}                ➔ Inyecta Audio Latino Web al instante (si el torrent viene en versión original)"
echo -e "  • ${YELLOW}[Alt + z / x]${NC}      ➔ Ajusta y memoriza la sincronía de audio por serie (±50ms)"
echo -e "  • ${YELLOW}[j]${NC}                ➔ Cambia subtítulos"
echo -e "  • ${YELLOW}[Ctrl + 1 / 2]${NC}     ➔ Activa reescalado por Inteligencia Artificial (Anime4K)"
echo -e ""
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════════════${NC}\n"
