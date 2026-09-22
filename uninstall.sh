#!/usr/bin/env bash
# ==============================================================================
# ✨ MOKI - Desinstalador Limpio
# Autor: makizapa
# ==============================================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

clear 2>/dev/null || true
echo -e "${RED}${BOLD}🗑️  Desinstalador de MOKI${NC}\n"
read -p "¿Estás seguro de que deseas desinstalar MOKI de tu sistema? [s/N]: " CONFIRM

if [[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]]; then
    echo -e "${GREEN}Desinstalación cancelada.${NC}"
    exit 0
fi

echo -e "\n${YELLOW}Eliminando ejecutables de ~/.local/bin...${NC}"
rm -f "$HOME/.local/bin/moki"
rm -f "$HOME/.local/bin/anime"
rm -f "$HOME/.local/bin/anime-search"
rm -f "$HOME/.local/bin/anime-voice"
rm -f "$HOME/.local/bin/serie"
rm -f "$HOME/.local/bin/serie-search"
rm -f "$HOME/.local/bin/pelis"
rm -f "$HOME/.local/bin/latino"
rm -f "$HOME/.local/bin/latino-search"
rm -f "$HOME/.local/bin/continuar"
rm -f "$HOME/.local/bin/limpiar"
rm -f "$HOME/.local/bin/limpiar-ram"

read -p "¿Deseas eliminar también el historial de reproducción (~/.config/streaming-cli)? [s/N]: " DEL_HIST
if [[ "$DEL_HIST" == "s" || "$DEL_HIST" == "S" ]]; then
    rm -rf "$HOME/.config/streaming-cli"
    echo -e "   ${GREEN}✓ Historial eliminado.${NC}"
fi

# Restaurar backup de mpv si existía
if [ -f "$HOME/.config/mpv/mpv.conf.moki_backup" ]; then
    mv "$HOME/.config/mpv/mpv.conf.moki_backup" "$HOME/.config/mpv/mpv.conf"
    echo -e "   ${GREEN}✓ Restaurado tu mpv.conf previo.${NC}"
fi

echo -e "\n${GREEN}✓ MOKI ha sido desinstalado limpiamente de tu sistema.${NC}\n"
