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
