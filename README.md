<div align="center">

  <h1>モキ MOKI</h1>

  <p><b>La Streaming Suite de Terminal para Linux</b></p>
  <p><i>Streaming P2P directo a memoria RAM, Web Scraping multi-proveedor, búsqueda en Nyaa, Series & Películas con mpv, AniSkip y Anime4K.</i></p>

  <p>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-10b981?style=for-the-badge" alt="License" /></a>
    <img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux" />
    <img src="https://img.shields.io/badge/mpv-8B0000?style=for-the-badge&logo=mpv&logoColor=white" alt="mpv" />
    <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python" />
    <img src="https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash" />
    <img src="https://img.shields.io/badge/Discord-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Discord" />
    <img src="https://img.shields.io/badge/NVIDIA-76B900?style=for-the-badge&logo=nvidia&logoColor=white" alt="NVIDIA" />
    <img src="https://img.shields.io/badge/AMD-ED1C24?style=for-the-badge&logo=amd&logoColor=white" alt="AMD" />
    <img src="https://img.shields.io/badge/Intel-0071C5?style=for-the-badge&logo=intel&logoColor=white" alt="Intel" />
  </p>

  <br/>

  <img src="assets/banner.jpg" alt="MOKI Banner" width="100%" />

  <br/><br/>

  <sub>
    <a href="#características">Características</a> •
    <a href="#instalación">Instalación</a> •
    <a href="#atajos-de-teclado">Atajos</a> •
    <a href="#comandos">Comandos</a> •
    <a href="#aviso-legal">Aviso Legal</a>
  </sub>

  <br/><br/>
</div>

---

## Características

<table>
  <tr>
    <td width="50%">
      <img src="https://img.shields.io/badge/RAM_BUFFER-100%25_MEMORY-ffd700?style=flat-square" alt="RAM" /><br/>
      <b>Zero-Wear SSD & Batch Packs</b><br/>
      El búfer de streaming corre directamente en <code>/tmp</code> (memoria RAM), evitando cualquier desgaste o escritura innecesaria en discos SSD. Soporta <b>Streaming Selectivo de Packs</b> (temporadas de 50GB a 250GB) extrayendo únicamente el capítulo solicitado.
    </td>
    <td width="50%">
      <img src="https://img.shields.io/badge/ANIME_SEARCH-MULTI--SEASON-8B5CF6?style=flat-square" alt="Anime" /><br/>
      <b>Búsqueda por Temporadas & AniSkip</b><br/>
      Búsqueda discriminada por temporada y capítulo (ej. <code>"Mushoku Tensei" 2 5</code> o números romanos <code>II</code>). Filtrado estricto contra temporadas no coincidentes, metadatos y portadas por temporada en AniList y salto automático de Opening mediante AniSkip v2.
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="https://img.shields.io/badge/WEB_STREAM-MULTI--PROVIDER-10b981?style=flat-square" alt="Web Latino" /><br/>
      <b>Audio Latino Web & Auto-Sync</b><br/>
      Streaming directo y <b>Pre-carga en segundo plano</b> con <b>Memoria de Sincronía</b>. Si eliges un seed en idioma original, precarga el doblaje web automáticamente en RAM mientras conecta el enjambre y recuerda el desfase exacto por serie (<kbd>L</kbd> / <kbd>Alt+z</kbd> / <kbd>Alt+x</kbd>).
    </td>
    <td width="50%">
      <img src="https://img.shields.io/badge/AUDIO_FILTER-LATINO_&_ESPAÑA-0071C5?style=flat-square" alt="Audio" /><br/>
      <b>Filtro de Encoders & Dual Audio</b><br/>
      Prioridad estricta a fuentes en Español Latino (<code>dem3nt3</code>, <code>Cinecalidad</code>, <code>LasCositas</code>, <code>Puya</code>) con ordenamiento por semillas activas en BitTorrent y discriminación precisa de subtítulos vs. audio doblado.
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="https://img.shields.io/badge/AUTONOMOUS-FANSUB_CHAIN-e11d48?style=flat-square" alt="Fansub" /><br/>
      <b>Modo Maratón & Fansub Memory</b><br/>
      Memoriza tu grupo de release preferido (ej. <code>VARYG</code>, <code>Erai-raws</code>, <code>AnoZu</code>) y encadena los capítulos automáticamente preservando temporada, fuente y calidad sin prompts manuales.
    </td>
    <td width="50%">
      <img src="https://img.shields.io/badge/HARDWARE-MULTI--GPU_ACCEL-00f0ff?style=flat-square" alt="GPU" /><br/>
      <b>Multi-GPU Acelerada & Anime4K</b><br/>
      Aceleración por hardware dedicada para <b>NVIDIA</b> (NVDEC), <b>AMD Radeon</b> (RADV/VA-API) e <b>Intel</b> (ANV/VA-API) con escalado y reconstrucción en tiempo real mediante algoritmos <b>Anime4K</b>.
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="https://img.shields.io/badge/CATALOG-CINEMETA_&_TORRENTIO-475569?style=flat-square" alt="Catálogo" /><br/>
      <b>Series & Películas P2P</b><br/>
      Catálogo unificado mediante Cinemeta y streams de Torrentio con soporte para producciones de Netflix, HBO Max, Disney+, Prime Video y estrenos de cine en resoluciones 4K y 1080p.
    </td>
    <td width="50%">
      <img src="https://img.shields.io/badge/RESUME-SMART_HISTORY-1e40af?style=flat-square" alt="Historial" /><br/>
      <b>Historial Unificado & Discord RPC</b><br/>
      Reanudación en el segundo exacto para todo el catálogo (Anime, Series, Películas y Streams Web) mediante <code>moki continuar</code>, con purga ágil de registros y presencia enriquecida en Discord.
    </td>
  </tr>
</table>

---

## Instalación

```bash
# 1. Clonar el repositorio
git clone https://github.com/MAKIZAPA/moki.git

# 2. Entrar y ejecutar el instalador universal
cd moki && chmod +x install.sh && ./install.sh
```

> **Nota:** El instalador detecta automáticamente tu gestor de paquetes (`pacman`, `apt`, `dnf`), tu arquitectura de GPU y enlaza los binarios en tu `$PATH`.

---

## Atajos de Teclado

### En el reproductor (mpv)

Controles integrados optimizados para reproducción fluida:

| Tecla | Función |
| :---: | :--- |
| <kbd>L</kbd> / <kbd>Alt</kbd> + <kbd>L</kbd> | **Inyectar Audio Latino Web** (Monta el doblaje web sobre seeds de torrent) |
| <kbd>Alt</kbd> + <kbd>z</kbd> / <kbd>Alt</kbd> + <kbd>x</kbd> | **Sincronización de Audio** (Ajusta desfase en ±100 ms) |
| <kbd>Alt</kbd> + <kbd>Z</kbd> / <kbd>Alt</kbd> + <kbd>X</kbd> | **Sincronización Rápida** (Ajusta desfase en ±500 ms) |
| <kbd>Alt</kbd> + <kbd>0</kbd> | **Resetear desfase** de audio (0.000s) |
| <kbd>Shift</kbd> + <kbd>N</kbd> | **Siguiente capítulo** (Modo Maratón inmediato con la misma release/temporada) |
| <kbd>TAB</kbd> | **Saltar Opening** (AniSkip con base de datos oficial) |
| <kbd>a</kbd> / <kbd>#</kbd> | **Alternar audio** (Español Latino / Japonés / Castellano / Inglés) |
| <kbd>j</kbd> | **Alternar subtítulos** |
| <kbd>Ctrl</kbd> + <kbd>1</kbd> | **Anime4K (HQ)** — Máxima fidelidad y nitidez por IA en GPU |
| <kbd>Ctrl</kbd> + <kbd>2</kbd> | **Anime4K (Fast)** — Modo ligero para GPUs integradas o portátiles |
| <kbd>Ctrl</kbd> + <kbd>0</kbd> | **Desactivar Shaders** (Imagen original sin procesar) |
| <kbd>f</kbd> | Alternar pantalla completa |
| <kbd>q</kbd> | Guardar posición exacta y salir |

### En el historial (`continuar`)

Gestión ágil para navegar y depurar el historial:

| Tecla | Función |
| :---: | :--- |
| <kbd>Enter</kbd> | **Reanudar reproducción** en el segundo exacto o cargar siguiente capítulo |
| <kbd>Tab</kbd> / <kbd>Ctrl</kbd> + <kbd>D</kbd> | **Eliminar elemento** del historial (ideal para descartar pruebas de seeds) |
| <kbd>Esc</kbd> | Salir del menú sin cambios |

---

## Comandos

<details>
<summary><b>Haz clic aquí para ver todos los subcomandos de terminal</b></summary>
<br/>

| Comando | Descripción |
| :--- | :--- |
| `moki` | Menú principal interactivo con selector de categorías |
| `moki anime <nombre> [temp] [cap]` | Búsqueda y streaming de anime en Nyaa con filtrado por temporadas |
| `moki latino <nombre> [temp] [cap]` | Streaming directo web (Flixlatam, Cuevana 3, JKAnime) en Español Latino |
| `moki serie <nombre> [temp] [cap]` | Búsqueda de series en Cinemeta y Torrentio |
| `moki pelis <nombre>` | Búsqueda de películas en cartelera y catálogo 4K/1080p |
| `moki continuar` | Historial inteligente (reanuda segundo exacto o salta de episodio) |
| `moki voz` | Búsqueda manos libres por reconocimiento de voz |
| `moki limpiar` | Limpieza de búferes temporales y liberación de memoria RAM |

*Nota: También puedes invocar cada utilidad directamente en tu terminal: `anime`, `latino`, `serie`, `pelis`, `continuar` y `limpiar`.*

</details>

---

## Desinstalación

<details>
<summary><b>Instrucciones de desinstalación limpia</b></summary>
<br/>

Si en algún momento deseas desinstalar MOKI de tu equipo:

```bash
cd moki && ./uninstall.sh
```

Esto eliminará los ejecutables de `~/.local/bin/` y restaurará tu configuración previa de `mpv`.

</details>

---

## Autor & Agradecimientos

- **Desarrollado y mantenido por:** [@makizapa](https://github.com/MAKIZAPA)
- **Agradecimiento especial:** 💖 *Gracias a mi novia por el nombre (Moki).*

---

## Aviso Legal / Disclaimer

<details>
<summary><b>Términos legales y exención de responsabilidad</b></summary>
<br/>

Este software (**MOKI**) ha sido desarrollado exclusivamente con fines educativos, de investigación técnica sobre protocolos de red y desarrollo de interfaces terminal en entornos Linux.

- **Sin alojamiento de contenidos:** MOKI **no almacena, no aloja, no transmite, no sube ni distribuye** ningún archivo de video, audio, multimedia o contenido protegido por leyes de propiedad intelectual en ningún servidor ni en este repositorio.
- **Indexación y agregación pública:** El software opera estrictamente como un cliente de interfaz local y reproductor multimedia que consulta enlaces e índices públicos de la web abierta y redes descentralizadas (BitTorrent / P2P, HLS/m3u8 públicos, AniList, Kitsu, Cinemeta). No realiza elusión de sistemas de gestión de derechos digitales (DRM).
- **Responsabilidad del usuario:** Los creadores y colaboradores de este proyecto no se hacen responsables del uso que los usuarios finales puedan darle a esta herramienta, ni de los contenidos indexados o reproducidos. Es responsabilidad exclusiva del usuario verificar y cumplir con las leyes de propiedad intelectual aplicables en su respectiva jurisdicción.
- **Marcas comerciales:** Todas las marcas registradas, logotipos y nombres comerciales referenciados (Crunchyroll, Netflix, HBO Max, Disney+, Amazon Prime, AniList, etc.) pertenecen a sus respectivos propietarios y se utilizan únicamente con fines descriptivos e informativos.

</details>

---

## Licencia

Distribuido bajo la Licencia **MIT**. Consulta el archivo [`LICENSE`](LICENSE) para más información.
