# 🛠️ Mis Scripts de Automatización (Linux / Debian)

Este repositorio contiene mi colección personal de scripts de Bash y Zsh para automatizar tareas cotidianas en sistemas basados en Debian/Ubuntu (actualizaciones de sistema, OCR de PDFs, instalación de programas, etc.).

La arquitectura de este proyecto utiliza **lo mejor de los dos mundos**: los archivos físicos viven en la carpeta personal del usuario (para poder editarlos y usar Git sin permisos de administrador), pero se conectan al sistema operativo mediante **enlaces simbólicos**, permitiendo que cualquier usuario de la PC pueda ejecutarlos globalmente como comandos nativos.

---

## 🚀 Instalación y Configuración Rápida

Sigue estos pasos para clonar el repositorio y dejar los comandos listos para usar en tu terminal.

### Paso 1: Clonar el repositorio
Vamos a descargar este repositorio directamente en una carpeta oculta llamada `.mis-scripts` dentro de tu directorio Home (`/home/tu_usuario`). 

Abre tu terminal y ejecuta:
```bash
git clone https://github.com/TU-USUARIO/TU-REPO.git ~/.mis-scripts
cd ~/.mis-scripts
```
*(Nota: Reemplaza `TU-USUARIO/TU-REPO` con la URL real de tu repositorio).*

### Paso 2: Dar permisos de ejecución
Para que Linux reconozca que estos archivos de texto son en realidad "programas" que puede ejecutar, debemos otorgarles permisos de ejecución (`+x`).
```bash
chmod +x ~/.mis-scripts/*
```
*Este comando le da permisos de ejecución a todos los archivos dentro de la carpeta al mismo tiempo.*

### Paso 3: Crear los enlaces simbólicos (Accesos directos globales)
Aquí ocurre la magia. Vamos a crear enlaces simbólicos (`ln -s`) en la carpeta `/usr/local/bin/` (la carpeta donde Linux busca comandos globales). 
De esta forma, cuando escribas un comando, el sistema irá a buscarlo ahí y será redirigido a tu carpeta personal.

Copia y pega este bloque completo en tu terminal (te pedirá tu contraseña de administrador):

```bash
sudo ln -s ~/.mis-scripts/auto-ocr /usr/local/bin/auto-ocr
sudo ln -s ~/.mis-scripts/discord-updater /usr/local/bin/discord-updater
sudo ln -s ~/.mis-scripts/discord-canary-updater /usr/local/bin/discord-canary-updater
sudo ln -s ~/.mis-scripts/md2pdf /usr/local/bin/md2pdf
sudo ln -s ~/.mis-scripts/debian-updater /usr/local/bin/debian-updater
```

¡Y listo! 🎉 Ya puedes abrir una nueva terminal y ejecutar cualquiera de los scripts desde cualquier carpeta de tu computadora.

---

## 📜 Scripts Incluidos

Aquí tienes un resumen de lo que hace cada herramienta:

*   **`debian-updater`**: Actualizador definitivo para Debian/Ubuntu. Verifica conexión, previene bloqueos de `apt`, actualiza paquetes (APT, Snap, Flatpak), limpia dependencias huérfanas y avisa si se requiere reiniciar. Soporta el flag `-s` para apagar la PC al terminar.
*   **`discord-updater`**: Descarga e instala inteligentemente la última versión estable de Discord. Inspecciona los servidores primero para no descargar la actualización si ya tienes la última versión.
*   **`discord-canary-updater`**: Igual que el anterior, pero para la versión Canary (Alpha) de Discord.
*   **`auto-ocr`**: Recibe uno o varios archivos PDF por parámetro, los limpia, endereza las páginas escaneadas y les aplica Reconocimiento Óptico de Caracteres en español sin tocar el archivo original.
*   **`md2pdf`**: Convierte apuntes de Markdown (`.md`) a PDF utilizando `pandoc` y LaTeX. Puede convertir un archivo específico o todos los de una carpeta a la vez de forma interactiva.

---

## ✍️ Flujo de trabajo (¿Cómo editar los scripts?)

Como los archivos reales viven en tu carpeta `~/.mis-scripts`, **NO necesitas usar `sudo` para editarlos ni para subirlos a GitHub**. 

1. Edita el archivo normalmente con tu editor favorito:
   ```bash
   nvim ~/.mis-scripts/debian-updater
   ```
2. Guarda los cambios. El comando global se actualizará automáticamente (¡porque es un acceso directo!).
3. Sube los cambios a GitHub como cualquier otro repositorio:
   ```bash
   cd ~/.mis-scripts
   git add .
   git commit -m "Mejora en el actualizador"
   git push origin main
   ```
