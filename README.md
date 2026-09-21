# ✨ MOKI (モキ)
> **La Streaming Suite de Terminal definitiva para Linux.**  
> Streaming P2P en memoria RAM, Anime en Nyaa, Series & Películas en 4K/1080p con `mpv`, AniSkip, Anime4K y Modo Maratón automático.

---

## 🌟 Características Principales

- ⚡ **Zero-Wear SSD (Buffer 100% en RAM):** Todo el contenido menor a 6 GB se almacena temporalmente en `/tmp` (memoria RAM), evitando cualquier desgaste o escritura en tu disco SSD.
- 🎌 **Anime con Fansub Memory:** Búsqueda en Nyaa y AniList. Si estás viendo un grupo específico (ej. `VARYG`, `Puya`), el sistema lo recuerda y salta al siguiente capítulo de ese mismo grupo automáticamente.
- 🍿 **Series y Películas:** Catálogo verificado de Cinemeta y streams de Torrentio con soporte para Netflix, HBO Max, Disney+, Amazon Prime y estrenos de cine.
- 🔊 **Filtro Estricto de Audio:** Prioridad absoluta a versiones en **Español Latino** y **Español España**. Bloqueo automático de seeds francesas mudas (`MULTi AD`).
- ⏭️ **Modo Maratón & AniSkip:**
  - `[Shift + N]`: Salta de inmediato al siguiente capítulo sin abrir nuevas terminales.
  - `[TAB]`: Salta el Opening automáticamente gracias a la API v2 de AniSkip.
  - Cuenta regresiva de 5 segundos al terminar el episodio para reproducción continua desatendida.
- 🎮 **Aceleración por Hardware Multi-GPU:**
  - **NVIDIA:** Vulkan (`gpu-next`) + NVDEC + Anime4K AI Upscaling.
  - **AMD Radeon:** Vulkan (RADV) + VA-API (Mesa) + Anime4K.
  - **Intel:** Vulkan (ANV) + VA-API (Media Driver) + Anime4K.
- ⏩ **Historial Inteligente (`continuar`):**
  - **< 90% visto:** Reanuda exactamente en el minuto y segundo donde te quedaste con la misma seed.
  - **≥ 90% visto:** Avanza el contador al siguiente capítulo y busca la misma release.
  - **Filtro de 2 minutos:** Descarta pruebas rápidas para no ensuciar tu lista.
- 🎙️ **Búsqueda por Voz:** Busca anime, series o películas hablando por el micrófono.
- 💬 **Discord Rich Presence:** Muestra el título, capítulo y póster oficial en tu estado de Discord en tiempo real.

---

## 🚀 Instalación Rápida

### 1. Clonar el repositorio
```bash
git clone https://github.com/makizapa/moki.git
cd moki
```

### 2. Ejecutar el instalador
```bash
chmod +x install.sh
./install.sh
```

El instalador detectará automáticamente:
1. Tu distribución (Arch/CachyOS, Debian/Ubuntu, Fedora).
2. Tu tarjeta gráfica (NVIDIA, AMD o Intel) y configurará los drivers de Vulkan/VA-API adecuados.
3. Instalará las herramientas requeridas (`mpv`, `fzf`, `jq`, `webtorrent-cli`, etc.).
4. Copiará los comandos a `~/.local/bin/` y configurará tu `PATH`.

---

## 💻 Comandos Disponibles

| Comando | Descripción |
| :--- | :--- |
| `moki` | Abre el menú interactivo principal de la suite |
| `moki anime <nombre> [cap]` | Busca y reproduce anime (ej. `moki anime "Dandadan" 1`) |
| `moki serie <nombre> [temp] [cap]` | Busca y reproduce series (ej. `moki serie "The Last of Us" 1 1`) |
| `moki pelis <nombre>` | Busca películas con prioridad de cine (ej. `moki pelis "Dune"`) |
| `moki continuar` | Abre tu historial de reanudación interactivo |
| `moki voz` | Inicia la búsqueda por voz a través del micrófono |
| `moki limpiar` | Limpia los buffers temporales de streaming y libera RAM |

*Nota: También puedes usar los comandos directos en la terminal: `anime`, `serie`, `pelis`, `continuar` y `limpiar`.*

---

## ⌨️ Atajos dentro del Reproductor (`mpv`)

| Tecla | Acción |
| :---: | :--- |
| `Shift + N` | **Siguiente capítulo automático** (Modo Maratón con la misma seed) |
| `TAB` | **Saltar Opening** (AniSkip con base de datos oficial) |
| `a` o `#` | **Alternar pista de audio** (Español Latino / Japonés / Inglés) |
| `j` | **Alternar subtítulos** |
| `Ctrl + 1` | **Anime4K Modo A (HQ)** - Máxima fidelidad con IA en GPU |
| `Ctrl + 2` | **Anime4K Modo A (Rápido)** - Modo ligero para GPUs integradas o laptops |
| `Ctrl + 0` | Desactivar Anime4K (Imagen original) |
| `f` | Pantalla completa |
| `q` | Guardar posición y salir |

---

## 🗑️ Desinstalación

Si alguna vez deseas desinstalar MOKI de tu equipo, solo ejecuta:
```bash
cd moki
./uninstall.sh
```

---

## 👤 Autor & Agradecimientos

- **Desarrollado y optimizado por:** [@makizapa](https://github.com/makizapa)
- **Agradecimiento especial:** 💖 *Gracias a mi novia por el nombre (Moki).*

Hecho para entusiastas de Linux, amantes del anime y cinéfilos de terminal.

---

## ⚖️ Aviso Legal / Disclaimer

Este software (**MOKI**) ha sido desarrollado exclusivamente con fines educativos, de investigación técnica y uso personal.

- **Sin alojamiento de contenidos:** MOKI **no almacena, no aloja, no transmite, no sube ni distribuye** ningún archivo de video, audio, multimedia o contenido protegido por leyes de propiedad intelectual en ningún servidor.
- **Cliente P2P e Indexación pública:** El software funciona estrictamente como un cliente de terminal y reproductor local que consulta metadatos y APIs públicas de libre acceso en internet (BitTorrent / P2P, AniList, Kitsu, Cinemeta).
- **Responsabilidad del usuario:** Los creadores y colaboradores de este proyecto no se hacen responsables del uso indebido que los usuarios puedan darle a esta herramienta, ni de la naturaleza de los contenidos que decidan reproducir. Es responsabilidad exclusiva de cada usuario final verificar y cumplir con las leyes de derechos de autor y regulaciones vigentes en su respectivo país o jurisdicción.
- **Marcas comerciales:** Todas las marcas registradas, títulos, logotipos y nombres de servicios mencionados (Crunchyroll, Netflix, HBO Max, Disney+, Amazon Prime, AniList, etc.) pertenecen a sus respectivos propietarios y se utilizan únicamente con propósitos informativos y de referencia descriptiva.

---

## 📜 Licencia

Este proyecto está bajo la Licencia **MIT**. Consulta el archivo [`LICENSE`](LICENSE) para más detalles.

