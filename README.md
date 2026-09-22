<div align="center">

  <h1>モキ MOKI</h1>

  <p><b>La Streaming Suite de Terminal para Linux</b></p>
  <p><i>Streaming P2P directo a memoria RAM, Anime en Nyaa, Series & Películas con mpv, AniSkip y Anime4K.</i></p>

  <p>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-10b981?style=for-the-badge" alt="License" /></a>
    <img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux" />
    <img src="https://img.shields.io/badge/mpv-8B0000?style=for-the-badge&logo=mpv&logoColor=white" alt="mpv" />
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
      <b>Zero-Wear SSD</b><br/>
      El búfer de streaming corre directamente en <code>/tmp</code> (memoria RAM), evitando cualquier desgaste o escritura en tu disco SSD.
    </td>
    <td width="50%">
      <img src="https://img.shields.io/badge/AUTONOMOUS-FANSUB_CHAIN-blue?style=flat-square" alt="Fansub" /><br/>
      <b>Fansub Memory</b><br/>
      Detecta y memoriza tu grupo de release preferido (ej. <code>VARYG</code>, <code>Puya</code>) y auto-encadena los siguientes capítulos sin prompts.
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="https://img.shields.io/badge/STREAMING-4K_&_1080P-purple?style=flat-square" alt="Streams" /><br/>
      <b>Series & Películas</b><br/>
      Catálogo verificado mediante Cinemeta y streams de Torrentio con soporte para Netflix, HBO Max, Disney+, Prime y estrenos de cine.
    </td>
    <td width="50%">
      <img src="https://img.shields.io/badge/AUDIO_FILTER-LATINO_&_ESPAÑA-10b981?style=flat-square" alt="Audio" /><br/>
      <b>Filtro Estricto de Audio</b><br/>
      Prioridad absoluta a <b>1080p Latino</b> y detección de encoders (<code>dem3nt3</code>, <code>Cinecalidad</code>, <code>LasCositas</code>). Diferenciación de subtítulos y bloqueo de falsos positivos.
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="https://img.shields.io/badge/PLAYBACK-ANISKIP_V2-e11d48?style=flat-square" alt="AniSkip" /><br/>
      <b>Modo Maratón & AniSkip</b><br/>
      Salto de Opening automático gracias a la API v2 de AniSkip y cuenta regresiva desatendida entre episodios.
    </td>
    <td width="50%">
      <img src="https://img.shields.io/badge/HARDWARE-MULTI--GPU_ACCEL-00f0ff?style=flat-square" alt="GPU" /><br/>
      <b>Multi-GPU Acelerada</b><br/>
      Aceleración por hardware en <b>NVIDIA</b> (NVDEC), <b>AMD Radeon</b> (RADV/VA-API) e <b>Intel</b> (ANV/VA-API) con shaders <b>Anime4K</b> por IA.
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

> **Nota:** El instalador detecta automáticamente tu distribución (`pacman`, `apt`, `dnf`), tu arquitectura de GPU e integra los comandos en tu `$PATH`.

---

## Atajos de Teclado

### En el reproductor (mpv)

Controles de teclado integrados inspirados en emuladores y reproductores de alto rendimiento:

| Tecla | Función |
| :---: | :--- |
| <kbd>Shift</kbd> + <kbd>N</kbd> | **Siguiente capítulo** (Modo Maratón inmediato con la misma seed) |
| <kbd>TAB</kbd> | **Saltar Opening** (AniSkip con base de datos oficial) |
| <kbd>a</kbd> / <kbd>#</kbd> | **Alternar audio** (Español Latino / Japonés / Castellano / Inglés) |
| <kbd>j</kbd> | **Alternar subtítulos** |
| <kbd>Ctrl</kbd> + <kbd>1</kbd> | **Anime4K (HQ)** — Máxima fidelidad y nitidez con IA en GPU |
| <kbd>Ctrl</kbd> + <kbd>2</kbd> | **Anime4K (Fast)** — Modo ligero para GPUs integradas o laptops |
| <kbd>Ctrl</kbd> + <kbd>0</kbd> | **Desactivar Shaders** (Imagen original sin procesar) |
| <kbd>f</kbd> | Pantalla completa |
| <kbd>q</kbd> | Guardar posición exacta y salir |

### En el historial (`continuar`)

Gestión ágil para descartar semillas no deseadas o pruebas de archivos:

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
| `moki` | Menú interactivo principal con selección visual |
| `moki anime <nombre> [cap]` | Búsqueda y streaming directo de anime en Nyaa |
| `moki serie <nombre> [temp] [cap]` | Búsqueda de series en Cinemeta y Torrentio |
| `moki pelis <nombre>` | Búsqueda de películas con prioridad de cine |
| `moki continuar` | Historial inteligente (reanuda segundo exacto o salta de episodio) |
| `moki voz` | Búsqueda por reconocimiento de voz mediante micrófono |
| `moki limpiar` | Limpieza de búferes temporales y liberación de memoria RAM |

*Nota: También puedes invocar cada utilidad directamente en tu terminal: `anime`, `serie`, `pelis`, `continuar` y `limpiar`.*

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

Este software (**MOKI**) ha sido desarrollado exclusivamente con fines educativos, de investigación técnica y uso personal.

- **Sin alojamiento de contenidos:** MOKI **no almacena, no aloja, no transmite, no sube ni distribuye** ningún archivo de video, audio, multimedia o contenido protegido por leyes de propiedad intelectual en ningún servidor.
- **Cliente P2P e Indexación pública:** El software funciona estrictamente como un cliente de terminal y reproductor local que consulta metadatos y APIs públicas de libre acceso en internet (BitTorrent / P2P, AniList, Kitsu, Cinemeta).
- **Responsabilidad del usuario:** Los creadores y colaboradores de este proyecto no se hacen responsables del uso indebido que los usuarios puedan darle a esta herramienta, ni de la naturaleza de los contenidos que decidan reproducir. Es responsabilidad exclusiva de cada usuario final verificar y cumplir con las leyes de derechos de autor y regulaciones vigentes en su respectivo país o jurisdicción.
- **Marcas comerciales:** Todas las marcas registradas, títulos, logotipos y nombres de servicios mencionados (Crunchyroll, Netflix, HBO Max, Disney+, Amazon Prime, AniList, etc.) pertenecen a sus respectivos propietarios y se utilizan únicamente con propósitos informativos y de referencia descriptiva.

</details>

---

## Licencia

Distribuido bajo la Licencia **MIT**. Consulta el archivo [`LICENSE`](LICENSE) para más información.
