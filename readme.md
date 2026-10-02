# 🛠️ Mis Scripts de Automatización (Linux)

Este repositorio contiene mi colección personal de scripts de Bash y Zsh para automatizar tareas cotidianas en Linux (actualizaciones del sistema, OCR de PDFs, instalación de programas, etc.). Los scripts están organizados por distribución, así que cada equipo instala solo los que le corresponden.

La arquitectura de este proyecto utiliza **lo mejor de los dos mundos**: los archivos físicos viven en la carpeta personal del usuario (para poder editarlos y usar Git sin permisos de administrador), pero se conectan al sistema operativo mediante **enlaces simbólicos** en `/usr/local/bin`, permitiendo ejecutarlos desde cualquier carpeta como comandos nativos.

---

## 📁 Estructura del repositorio

```
~/.mis-scripts/
├── common/                      # Scripts para todas las distribuciones
│   ├── auto-ocr
│   ├── discord-canary-updater
│   ├── discord-updater
│   └── md2pdf
├── debian/                      # Solo para Debian
│   └── debian-updater
├── ubuntu/                      # Solo para Ubuntu
│   └── ubuntu-updater
├── install.sh                   # Instalador
└── readme.md
```

*   **`common/`**: scripts que funcionan en cualquier distribución. Se instalan siempre.
*   **Carpetas de distribución** (`ubuntu/`, `debian/`, ...): scripts exclusivos de una distribución. Solo se instalan en esa distribución.

El nombre de cada carpeta de distribución debe coincidir con el campo `ID` de `/etc/os-release`. Para saber cuál es el de tu sistema:
```bash
grep '^ID=' /etc/os-release
```

---

## 🚀 Instalación

### Paso 1: Clonar el repositorio
Vamos a descargar este repositorio directamente en una carpeta oculta llamada `.mis-scripts` dentro de tu directorio Home (`/home/tu_usuario`).

Abre tu terminal y ejecuta:
```bash
git clone https://github.com/TU-USUARIO/TU-REPO.git ~/.mis-scripts
cd ~/.mis-scripts
```
*(Nota: Reemplaza `TU-USUARIO/TU-REPO` con la URL real de tu repositorio).*

### Paso 2: Ejecutar el instalador
```bash
./install.sh
```

El instalador detecta tu distribución y crea en `/usr/local/bin` los enlaces simbólicos a los scripts de `common/` y a los de la carpeta de tu distribución. Te pedirá tu contraseña de administrador, porque `/usr/local/bin` pertenece al sistema.

¡Y listo! 🎉 Ya puedes abrir una nueva terminal y ejecutar cualquiera de los scripts desde cualquier carpeta de tu computadora.

*No hace falta dar permisos de ejecución a mano: Git los conserva al clonar.*

> **¿Y los demás usuarios de la PC?** Los comandos quedan disponibles para todos, pero solo podrán ejecutarlos si tu carpeta personal es accesible para ellos. En las instalaciones nuevas de Ubuntu (desde la 21.04), la carpeta personal es privada por defecto. Puedes comprobarlo con `ls -ld ~`: si ves `drwxr-x---`, solo tú podrás ejecutarlos.

---

## 🔄 Mantenimiento

| Situación | Qué hacer |
|---|---|
| Editaste el contenido de un script | Nada: el cambio se aplica al instante. |
| Agregaste, moviste, renombraste o borraste un script | `./install.sh` |
| Bajaste cambios desde GitHub | `git pull && ./install.sh` |
| Quieres quitar todos los comandos | `./install.sh --uninstall` |
| Vas a mover o renombrar la carpeta del repositorio | `./install.sh --uninstall` **antes** de moverla, y luego `./install.sh` desde la nueva ubicación. |

El instalador se puede ejecutar todas las veces que quieras. Sincroniza `/usr/local/bin` con el repositorio, elimina los enlaces que ya no corresponden y al final verifica que no quede ninguno roto. Además:

*   Solo crea y borra **enlaces simbólicos**: nunca borra ni modifica archivos, y **nunca toca** nada de `/usr/local/bin` que no pertenezca al repositorio.
*   Pide la contraseña **antes** de hacer cualquier cambio; si no la ingresas, no modifica nada.
*   Si no encuentra scripts para instalar, no hace nada, para evitar borrar todos los comandos por error.
*   Te avisa si algún script tiene el mismo nombre que un comando del sistema, porque lo taparía (`/usr/local/bin` tiene prioridad).

En un sistema sin `sudo`, ejecútalo como root (por ejemplo, con `su -c ./install.sh`).

### Agregar un script nuevo
```bash
nvim ~/.mis-scripts/common/mi-script     # o la carpeta de tu distribución
chmod +x ~/.mis-scripts/common/mi-script
cd ~/.mis-scripts && ./install.sh
```

### Agregar una distribución nueva
Crea una carpeta con el `ID` de la distribución (por ejemplo `fedora/`), coloca ahí sus scripts y ejecuta `./install.sh` en ese equipo. Si una distribución no tiene carpeta propia, el instalador igual instala los scripts de `common/`.

Si un script existe en `common/` y en la carpeta de una distribución con el mismo nombre, en esa distribución se instala la versión de su carpeta.

---

## 📜 Scripts Incluidos

### Comunes (`common/`)

*   **`auto-ocr`**: Recibe uno o varios archivos PDF por parámetro, los limpia, endereza las páginas escaneadas y les aplica Reconocimiento Óptico de Caracteres en español sin tocar el archivo original.
*   **`md2pdf`**: Convierte apuntes de Markdown (`.md`) a PDF utilizando `pandoc` y LaTeX. Puede convertir un archivo específico o todos los de una carpeta a la vez de forma interactiva.
*   **`discord-updater`**: Descarga e instala inteligentemente la última versión estable de Discord (`.deb`). Inspecciona los servidores primero para no descargar la actualización si ya tienes la última versión.
*   **`discord-canary-updater`**: Igual que el anterior, pero para la versión Canary (Alpha) de Discord.

### Ubuntu (`ubuntu/`)

*   **`ubuntu-updater`**: Actualización completa de Ubuntu: APT (incluido el kernel), Snap, Flatpak y firmware (fwupd), con limpieza de paquetes huérfanos. Nunca cambia de versión de Ubuntu, pero avisa si hay una nueva. Por defecto muestra qué va a instalar y pide confirmación; con `-y` instala todo sin preguntar. Protege las fases críticas de interrupciones y repara automáticamente ejecuciones anteriores interrumpidas. Ver `ubuntu-updater --help`.

### Debian (`debian/`)

*   **`debian-updater`**: Actualización completa de Debian: verifica la conexión, previene bloqueos de `apt`, actualiza paquetes (APT, Snap, Flatpak), limpia dependencias huérfanas y avisa si se requiere reiniciar. Soporta el flag `-s` para apagar la PC al terminar.

Las dependencias de cada script están detalladas en su encabezado.

---

## ✍️ Flujo de trabajo (¿Cómo editar los scripts?)

Como los archivos reales viven en tu carpeta `~/.mis-scripts`, **NO necesitas usar `sudo` para editarlos ni para subirlos a GitHub**.

1. Edita el archivo normalmente con tu editor favorito:
   ```bash
   nvim ~/.mis-scripts/ubuntu/ubuntu-updater
   ```
2. Guarda los cambios. El comando global se actualizará automáticamente (¡porque es un acceso directo!).
3. Sube los cambios a GitHub como cualquier otro repositorio:
   ```bash
   cd ~/.mis-scripts
   git add .
   git commit -m "Mejora en el actualizador"
   git push origin main
   ```
