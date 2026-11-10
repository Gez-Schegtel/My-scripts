# Reglas del repositorio (`~/.mis-scripts`)

Este archivo define las convenciones y reglas que deben seguir los asistentes de IA (Antigravity, Claude Code, etc.) al analizar o modificar este repositorio.

---

## 1. Arquitectura y propósito

* **Estructura por distribución**:
  * `common/`: scripts que se instalan en cualquier distribución de Linux.
  * `<distro>/` (`ubuntu/`, `debian/`, ...): scripts exclusivos de esa distribución. El nombre de la carpeta debe coincidir con el campo `ID` de `/etc/os-release`. Si un script existe con el mismo nombre en `common/` y en `<distro>/`, prevalece el de la distribución.
  * `install.sh`: sincroniza enlaces simbólicos en `/usr/local/bin` hacia los scripts ejecutables del repositorio (y los quita con `--uninstall`). Nunca modifica ni borra nada en `/usr/local/bin` que no sea un enlace apuntando a este repositorio.
* **Separación con Pandoc config**:
  * `common/md2pdf` **no define el aspecto visual de los PDF** (motor LaTeX, fuentes, márgenes, colores, cuadros, filtros). Todo eso vive en el repositorio separado **[Pandoc config](https://github.com/Gez-Schegtel/My-Pandoc-Config)** (`~/.local/share/pandoc`), que `md2pdf` invoca mediante `pandoc -d estilo`. Nunca agregar opciones de estilo visual dentro de `md2pdf`.

---

## 2. Regla de oro: mantener la documentación al día

Cada vez que se agregue, modifique o quite un script, una opción de línea de comandos, una dependencia o un comportamiento visible para el usuario, **en el mismo cambio** se deben revisar y actualizar los **tres lugares** donde se documenta:

1. **El encabezado del script** (`DESCRIPCIÓN`, `USO`, `CÓDIGO(S) DE SALIDA`, `DEPENDENCIAS`).
2. **La ayuda en pantalla del script** (`usage()` / `--help` o la cadena `uso` en los mensajes de error).
3. **`readme.md`**:
   * La descripción del script en la sección `## 📜 Scripts Incluidos`.
   * El árbol de directorios en `## 📁 Estructura del repositorio` (si se agregó, renombró, movió o borró algún script o carpeta).
   * Las secciones de instalación o mantenimiento si cambió el funcionamiento de `install.sh`.

---

## 3. Scripts hermanos (mantener sincronizados)

Hay tres pares de scripts que comparten lógica. Al corregir un error o cambiar un comportamiento compartido en uno, revisá siempre si corresponde aplicar el mismo cambio en su par:

1. **`common/md2pdf` ↔ `common/mdnorm`**
   * **Qué comparten**: búsqueda de imágenes (`carpeta_de_busqueda`, prioridad de carpetas, índice del vault `.obsidian` / repositorio git / carpetas hermanas), normalización Unicode de acentos (`NFC` y `NFD`), decodificación de `%XX` sobre bytes UTF-8 crudos, limpieza de texto alternativo genérico de Notion (`image.png`, `Untitled`, `Pasted image...`), atributos de imágenes de Obsidian (`![[...|ancho|izquierda/derecha]]`) y detección de bloques de código (` ``` ` o `~~~`) y código en línea.
   * **Diferencia intencional**: `md2pdf` traduce al vuelo en una copia temporal sin tocar el `.md` original (incluyendo enlaces `[[Nota]]` y avisos `> [!NOTE]`) y acepta `-i`/`--imagenes`; `mdnorm` corrige y guarda el archivo `.md` para que `pandoc` lo lea bien, sin tocar enlaces `[[Nota]]` ni avisos `> [!NOTE]`.
2. **`ubuntu/ubuntu-updater` ↔ `debian/debian-updater`**
   * **Qué comparten**: estructura de 7 pasos (reparación previa con `dpkg --audit`, `apt-get update`, `apt-get full-upgrade` separado en descarga e instalación, Snap, Flatpak con `run_flatpak`, firmware con `fwupdmgr` y `fw_classify`, limpieza de APT y de Flatpak), manejo de señales (`on_signal`, `stop_if_interrupted`), protección de fases críticas (`critical` con `stty -isig` y `systemd-inhibit`), bloqueo de ejecución única (`flock`) y mantenimiento de `sudo`.
   * **Diferencia intencional**: `debian-updater` contempla además el cambio de etiqueta `stable` → `oldstable` (`--allow-releaseinfo-change-suite`), el aviso si las fuentes usan el alias `stable` en vez del nombre clave, la detección de ramas continuas (`testing`/`sid`), la comprobación de reinicio por kernel (`kernel_reboot_needed`) y la consulta de versión nueva leyendo `dists/stable/Release`.
3. **`common/discord-updater` ↔ `common/discord-canary-updater`**
   * **Qué comparten**: toda la lógica es idéntica; solo cambian `PACKAGE`, `DOWNLOAD_URL`, `DEB_FILE` y el nombre mostrado en pantalla (`Discord` vs `Discord Canary`).

---

## 4. Estilo, idioma y convenciones de código

* **Idioma y tono**:
  * Todo el repositorio (comentarios, ayuda, mensajes al usuario, `readme.md` y mensajes de commit) está escrito en **español rioplatense** claro y natural (voseo: *Ejecutalo, Revisala, Instalalo, Usá, podés, querés*).
  * Explicar los motivos de las decisiones técnicas en los comentarios con lenguaje llano y directo, sin jerga innecesaria.
* **Encabezado y permisos**:
  * Línea 1: shebang (`#!/usr/bin/env bash`, `#!/bin/bash` o `#!/usr/bin/env zsh`).
  * Línea 2: `# SPDX-License-Identifier: GPL-3.0-or-later`.
  * Todo script dentro de `common/` o `<distro>/` debe tener permiso de ejecución (`chmod +x`, modo `100755` en Git).
* **Seguridad y experiencia de usuario**:
  * Comprobar las dependencias requeridas al inicio del script (antes de pedir confirmación o procesar archivos) y mostrar cómo instalarlas en Debian/Ubuntu.
  * Pedir confirmación antes de modificar archivos o el sistema (ofreciendo `-y` / `--yes` para modo automático). Si la lectura de confirmación falla (`Ctrl+D` o ejecución sin terminal), cancelar sin aplicar cambios.
  * Limpiar siempre los archivos o directorios temporales al salir (`trap ... EXIT`) y manejar interrupciones (`INT TERM HUP`).
  * Pasar `--` antes de las rutas de archivo en los comandos para evitar que un nombre que empieza con `-` se tome como opción.
  * En `mdnorm`, cualquier transformación debe ser **idempotente** (pasarlo dos veces seguidas no debe volver a cambiar el archivo) y preservar los permisos del archivo original (`cat -- "$temporal" > "$archivo"`).

---

## 5. Verificación antes de finalizar un cambio

1. **Sintaxis**: verificar con `bash -n` (scripts en Bash) o `zsh -n` (scripts en Zsh) que no haya errores de sintaxis.
2. **Pruebas**: si se modificó lógica de procesamiento (como el código Perl de `mdnorm` o `md2pdf`), probar con casos reales y casos borde que el resultado sea el esperado.
3. **Formato de Markdown**: si se editó `readme.md` o este archivo, verificar con `./common/mdnorm` que no tenga problemas de formato para `pandoc`.
