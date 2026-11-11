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
│   ├── md2pdf
│   ├── mdnorm
│   └── pdf2md
├── debian/                      # Solo para Debian
│   └── debian-updater
├── ubuntu/                      # Solo para Ubuntu
│   └── ubuntu-updater
├── install.sh                   # Instalador
├── LICENSE                      # Licencia (GPL-3.0)
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
git clone https://github.com/Gez-Schegtel/My-scripts.git ~/.mis-scripts
cd ~/.mis-scripts
```

### Paso 2: Ejecutar el instalador
```bash
./install.sh
```

El instalador detecta tu distribución y crea en `/usr/local/bin` los enlaces simbólicos a los scripts de `common/` y a los de la carpeta de tu distribución. Te pedirá tu contraseña de administrador, porque `/usr/local/bin` pertenece al sistema.

¡Y listo! 🎉 Ya puedes abrir una nueva terminal y ejecutar cualquiera de los scripts desde cualquier carpeta de tu computadora.

*No hace falta dar permisos de ejecución a mano: Git los conserva al clonar, siempre que el script se haya commiteado con ese permiso (`git ls-files -s` debe mostrar `100755`).*

> **¿Y los demás usuarios de la PC?** Los comandos quedan disponibles para todos, pero solo podrán ejecutarlos si tu carpeta personal es accesible para ellos. En Debian (desde la 12) y en las instalaciones nuevas de Ubuntu (desde la 21.04), la carpeta personal es privada por defecto. Puedes comprobarlo con `ls -ld ~`: si ves `drwx------` o `drwxr-x---`, solo tú podrás ejecutarlos.

---

## 🔄 Mantenimiento

| Situación | Qué hacer |
|---|---|
| Editaste el contenido de un script | Nada: el cambio se aplica al instante. |
| Agregaste, moviste, renombraste o borraste un script | `./install.sh` |
| Bajaste cambios desde GitHub | `git pull && ./install.sh` |
| Quieres quitar todos los comandos | `./install.sh --uninstall` |
| Vas a mover o renombrar la carpeta del repositorio | `./install.sh --uninstall` **antes** de moverla, y luego `./install.sh` desde la nueva ubicación. |

El instalador se puede ejecutar todas las veces que quieras. Sincroniza `/usr/local/bin` con el repositorio: crea los enlaces que faltan, corrige los que apuntan mal y quita los que ya no corresponden, diciéndote por qué. Si no hay nada que cambiar, solo te confirma que todo está al día. Además:

*   Solo crea y borra **enlaces simbólicos**: nunca borra ni modifica archivos, y **nunca toca** nada de `/usr/local/bin` que no pertenezca al repositorio.

*   Pide la contraseña solo si hay algo que cambiar, y **antes** del primer cambio; si no la ingresas, no modifica nada.

*   Si no encuentra scripts para instalar, no hace nada, para evitar borrar todos los comandos por error.

*   **No instala** un script si su nombre ya lo usa otro comando (del sistema, interno de bash o de cualquier lugar de tu `PATH`), porque lo taparía. Tampoco instala los que no tienen permiso de ejecución. En los dos casos te avisa al final con lo que tienes que hacer.

*   Lo que no puede detectar son los **alias y funciones de tu shell** (por ejemplo, los que define oh-my-zsh). Antes de elegir el nombre de un script nuevo, comprueba con `type nombre` en tu terminal que no esté en uso.

En un sistema sin `sudo`, ejecútalo como root (por ejemplo, con `su -c ./install.sh`).

### Agregar un script nuevo
```bash
type mi-script                           # tiene que decir "not found": el nombre está libre
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

*   **`auto-ocr`**: Recibe uno o varios archivos PDF por parámetro, los limpia, endereza las páginas escaneadas y les aplica Reconocimiento Óptico de Caracteres en español sin tocar el archivo original (guarda el resultado como `archivo_ocr.pdf`). Saltea los que ya procesó, así que puedes volver a ejecutarlo sobre la misma carpeta sin repetir trabajo.

*   **`md2pdf`**: Convierte apuntes de Markdown (`.md`) a PDF con `pandoc`, aplicando mi estilo (`pandoc -d estilo`). Convierte los archivos que le indiques (`md2pdf a.md b.md`) o, si no le pasas ninguno, todos los `.md` de la carpeta actual. Muestra la lista y pide confirmación antes de empezar (`y` o ENTER aceptan, cualquier otra cosa cancela; con `-y` o `--yes` convierte directo, sin preguntar: `md2pdf -y nota.md`), y guarda cada PDF al lado de su `.md`. Si un archivo falla, sigue con los demás y al final te dice cuáles no pudo convertir. Las imágenes se buscan en la carpeta del `.md`, así que funciona aunque lo ejecutes desde otra carpeta (`md2pdf ~/notas/*.md`). Si están en otro lado, se le indica la carpeta con `-i` (o `--imagenes`), que se puede repetir y también busca en sus subcarpetas: `md2pdf -i ~/imagenes nota.md`. También entiende las notas de **Obsidian**: traduce `![[imagen.png]]` (y `![[imagen.png|400]]`, con ancho; las imágenes salen centradas, y con `![[imagen.png|derecha]]` o `|izquierda` —combinables con el ancho: `|derecha|300`— quedan a un costado; en Obsidian esas palabras son solo texto alternativo) y los enlaces `[[Nota]]` a Markdown estándar en una copia temporal, sin tocar tu `.md`, y busca cada imagen por nombre en todo el vault (o, si no hay vault, en el repositorio git de la nota; y si tampoco hay, en la carpeta de la nota, sus subcarpetas y las carpetas hermanas). Lo mismo hace con las imágenes de Markdown estándar (`![texto](Pasted%20image.png)`) cuando el archivo no está donde dice la ruta, que es lo que pasa cuando Obsidian guarda las imágenes en otra carpeta (por ejemplo `assets/`). Si el texto de una imagen es solo el nombre del archivo (`![image.png](...)`, como exporta **Notion**), no lo usa, porque pandoc lo pondría de epígrafe ("Figura 1: image.png"); y acepta los acentos de las rutas escritos de las dos formas que existen en Unicode (las exportaciones de Notion a veces usan la menos común). Los avisos de GitHub y los callouts de Obsidian (`> [!NOTE]`) salen como una cita con el título en negrita. Las letras matemáticas Unicode ($A, f, x, α$) copiadas de IA se normalizan a sus caracteres estándar (NFKC) fuera de código. Las listas pegadas al párrafo de arriba (sin línea en blanco antes, algo que pandoc no reconoce) también se arreglan en la copia, con la misma regla que `mdnorm` (incluida la lista con sangría pegada a un párrafo, que pasa al margen). Un `.md` que no está en UTF-8 (por ejemplo en Latin-1) se convierte igual, sin esa traducción, y avisa cómo pasarlo a UTF-8. Los `.md` sin nada que traducir pasan directo a pandoc, y las imágenes que ya están donde dice su ruta no se tocan. **El script no define cómo se ve el PDF**: lo toma del repositorio *Pandoc config* (ver la sección siguiente).

*   **`mdnorm`**: Normaliza archivos Markdown para que pandoc los convierta bien a PDF, con cambios mínimos (no reformatea el resto del texto). Agrega la línea en blanco que pandoc necesita antes de listas, tablas, citas (`>`) y títulos (`#`) pegados a un párrafo (también en listas dentro de citas y citas dentro de listas), y alrededor de las imágenes sueltas; separa con una línea en blanco los ítems de las listas (también los de las sublistas y los de las listas dentro de citas), para que el Markdown quede más prolijo (en el PDF sale igual con o sin esas líneas); separa del último ítem un párrafo que quedó pegado a la lista (pandoc lo metería adentro del ítem), salvo que el ítem esté cortado a mitad de oración; un `.md` que no está en UTF-8 no se toca y se avisa cómo convertirlo; corrige la sangría de las sublistas que pandoc no anidaría (y corre con ellas sus renglones y su código); pasa al margen una lista con sangría (tabulación o 4 espacios) pegada a un párrafo, que pandoc tomaría como texto; agrega la línea en blanco antes de un bloque de código pegado a un texto con otra sangría (pandoc lo leería como código en línea); cambia los `<br>` fuera de las tablas y del HTML por saltos de línea (pandoc los borra y pega las palabras); junta en una sola línea las filas de tabla partidas en varias (típico al copiar de una página web o de un chat); en las tablas con columnas de más o con `<br>` (que pandoc borra sin avisar) agrega las columnas que faltan y cambia los `<br>` por un espacio, sin tocar las tablas que ya están bien; pasa las imágenes de Obsidian (`![[foto.png|300]]`) a Markdown estándar con la ruta relativa a la nota; y arregla los errores comunes de la cabecera YAML (valores con `:`, `#` o caracteres especiales sin comillas, un espacio o una comilla que falta, el `---` de cierre), avisa si hay claves repetidas y, si pandoc está instalado, comprueba que la cabecera se pueda leer. También cambia las fórmulas `\( \)` y `\[ \]` (de los chats de IA o LaTeX) por `$ $` y `$$ $$`, que son las que entiende pandoc (solo si parecen una fórmula: los paréntesis y corchetes escapados de un texto común quedan como están), y arregla lo típico de las exportaciones de **Notion**: el título de la página pasa a la cabecera YAML (y avisa qué propiedades, como `Created` o `Tags`, quedan visibles en el PDF), los callouts (`<aside>`) a citas, y se corrigen las rutas de imágenes y el texto de imagen que es solo el nombre del archivo (pandoc lo usaría de epígrafe); normaliza las letras matemáticas Unicode ($A, f, x, α$) copiadas de IA a sus caracteres estándar (NFKC); y no toca el código (tampoco los bloques con sangría). Sirve para Markdown de cualquier origen (Obsidian, Notion, GitHub, Typora...). Busca las imágenes en los mismos lugares que `md2pdf` y avisa de las que no encuentra, también de las que están en Markdown estándar. Muestra los avisos y cuántas líneas cambian, y pregunta antes de guardar; `-v` (o `--verbose`) muestra además los cambios línea por línea (si no te convencen, respondés que no y el archivo queda como estaba) y `-y` guarda sin preguntar (`mdnorm -v nota.md`).

*   **`pdf2md`**: Hace el camino inverso a `md2pdf`: convierte archivos PDF a Markdown (`.md`), reconstruyendo con precisión los documentos generados con `md2pdf` (`pandoc -d estilo`) y funcionando también con PDFs de texto comunes. Convierte los archivos que le indiques (`pdf2md a.pdf b.pdf`) o, si no le pasás ninguno, todos los `.pdf` de la carpeta actual; muestra la lista, pide confirmación antes de empezar (con `-y` o `--yes` convierte directo, sin preguntar) y guarda cada `.md` al lado de su `.pdf`. Recupera la cabecera YAML (`title`, `subtitle`, `author`, `date`, y si el PDF tiene índice, `toc`, `toc-depth`, `numbersections`, `documentclass: scrartcl` y `classoption: numbers=enddot`; también reconoce el índice de un documento con títulos sin número, que vuelven a llevar `{-}`), la jerarquía de títulos (`#` a `####`), el formato en línea (`**negrita**`, `*cursiva*`, `` `código` ``, `~~tachado~~`, enlaces y emojis), las listas con viñetas, numeradas y de tareas (`- [ ]` / `- [x]`) con su anidamiento, los cuadros de cita (`>`), los bloques de código con detección automática de lenguaje (`bash`, `sql`, `python`, `json`, `yaml`, `c`), las tablas Markdown con la alineación de cada columna (`:---`, `:---:`, `---:`), también las tablas con grilla completa de Google Docs, Word o LibreOffice (con celdas combinadas, celdas con un `-` y tablas que siguen en la página siguiente, que se unen en una sola, incluso si una fila quedó partida entre las dos páginas; si una celda tiene varias viñetas, la tabla se escribe como *grid table* de pandoc, que admite listas dentro de las celdas), las líneas horizontales (`---`), las fórmulas matemáticas en LaTeX (`$...$` y `$$...$$`), los superíndices y subíndices (`m^2^`, `H~2~O`) y las notas al pie (`[^1]` en el texto y `[^1]: texto` al final). Descarta los números de página sueltos al pie y pasa las ligaduras (`ﬁ`, `ﬂ`) a letras comunes. Si el PDF tiene imágenes incrustadas (ignorando los glifos de `Noto Color Emoji`), compara su contenido píxel a píxel con las imágenes que ya están en la carpeta: si encuentra la misma imagen (por ejemplo `./logo_utn.png`), la enlaza directamente con su tamaño en centímetros (`{width=2cm}`); si no existe en la carpeta, la extrae al lado del `.md` y la enlaza. Si un PDF contiene tipografías no soportadas, caracteres sin texto legible o carece por completo de capa de texto (por ejemplo si está escaneado), muestra un aviso y no realiza la conversión para evitar generar un documento incorrecto; lo mismo si el PDF pide contraseña para abrirse, está dañado o no es un PDF. El nivel de cada ítem de una lista sale de su posición en el PDF comparada con la de los ítems de arriba, así que también funciona con los PDF de LibreOffice, Word, Google Docs o un navegador, que corren las listas del margen; las sublistas numeradas llevan 4 espacios para que pandoc las anide, los ítems con la viñeta o el número en la misma posición son hermanos y los renglones de un ítem largo se mantienen en el ítem aunque el texto del primer renglón empiece en otro lugar (como en Google Docs); un párrafo aparte que empieza a la altura del texto de un ítem queda dentro de ese ítem; reconoce las viñetas de LaTeX, Google Docs, Word y LibreOffice (incluidas `◦` y la `–` del segundo nivel). En los PDF que no son de LaTeX también reconoce como títulos los subtítulos numerados en letra más chica que el texto, los renglones cortos sueltos (con más espacio arriba y abajo y sin punto final) y los que figuran en el índice del PDF; un renglón en negrita que empieza con un número solo es un título si está en el margen (corrido, es un ítem de una lista numerada). Los títulos centrados de la carátula se escriben como un bloque centrado de LaTeX (`\begin{center}`), y un renglón suelto justo antes de una imagen (como el título de un gráfico) lleva `\needspace{...}` para no quedar solo al pie de la página. En los PDF que no son de LaTeX (alineados a la izquierda), un renglón corto solo cuenta como salto de línea a propósito si la primera palabra del renglón siguiente entraba en el espacio libre; si no, se une al párrafo (lo mismo con los títulos largos de varios renglones). Con un PDF de `md2pdf`, el `.md` que genera vuelve a dar el mismo PDF si se exporta con la misma versión del estilo (si el estilo cambió después, el contenido es el mismo pero los saltos de página pueden moverse).

*   **`discord-updater`**: Descarga e instala inteligentemente la última versión estable de Discord (`.deb`). Inspecciona los servidores primero para no descargar la actualización si ya tienes la última versión.

*   **`discord-canary-updater`**: Igual que el anterior, pero para la versión Canary (Alpha) de Discord.

### Ubuntu (`ubuntu/`)

*   **`ubuntu-updater`**: Actualización completa de Ubuntu: APT (incluido el kernel), Snap, Flatpak y firmware (fwupd), con limpieza de paquetes huérfanos. Nunca cambia de versión de Ubuntu, pero avisa si hay una nueva y si hace falta reiniciar. Por defecto muestra qué va a instalar y pide confirmación; con `-y` instala todo sin preguntar. Protege las fases críticas de interrupciones y repara automáticamente ejecuciones anteriores interrumpidas. Ver `ubuntu-updater --help`.

### Debian (`debian/`)

*   **`debian-updater`**: Actualización completa de Debian: APT (incluido el kernel), Snap, Flatpak y firmware (fwupd), con limpieza de paquetes huérfanos. Nunca cambia de versión de Debian, pero avisa si hay una nueva y te explica cómo seguir si tus fuentes de APT usan el alias `stable`. Por defecto muestra qué va a instalar y pide confirmación; con `-y` instala todo sin preguntar. Protege las fases críticas de interrupciones, repara automáticamente ejecuciones anteriores interrumpidas y avisa si hace falta reiniciar (también cuando se actualizó el kernel). Ver `debian-updater --help`.

Las dependencias de cada script están detalladas en su encabezado.

### 📄 Dependencia de `md2pdf`: el repositorio [Pandoc config](https://github.com/Gez-Schegtel/My-Pandoc-Config)

El estilo de los PDF (fuentes, emojis a color, cuadros, tablas, márgenes) no vive en este repositorio, sino en otro aparte: **[Pandoc config](https://github.com/Gez-Schegtel/My-Pandoc-Config)**. `md2pdf` se limita a llamar a `pandoc -d estilo`, y pandoc busca esa configuración en su carpeta de datos, así que hay que instalarla ahí una sola vez:

```bash
git clone https://github.com/Gez-Schegtel/My-Pandoc-Config.git ~/.local/share/pandoc
```
*(Sus dependencias, los paquetes de LaTeX y las fuentes, están en el README de ese repositorio.)*

Para comprobar que pandoc usa esa carpeta:
```bash
pandoc --version | grep -i "user data"
```
Tiene que mostrar `/home/tu_usuario/.local/share/pandoc`. Si muestra `~/.pandoc`, es porque `~/.local/share/pandoc` no existe: pandoc usa esa carpeta vieja solo en ese caso.

Antes de convertir nada, `md2pdf` comprueba que estén `pandoc` y `lualatex` y que `-d estilo` se pueda cargar. Si falta algo, te lo dice una sola vez con cómo arreglarlo. Para cambiar cómo se ven los PDF se edita el repositorio Pandoc config, no el script.

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

---

## 📄 Licencia

Este proyecto es **software libre**: se distribuye bajo la [Licencia Pública General de GNU, versión 3 o posterior](LICENSE) (GPL-3.0-or-later).

En pocas palabras: puedes usar, estudiar, modificar y compartir estos scripts como quieras. Si distribuyes una versión modificada, tiene que seguir bajo la misma licencia y con su código fuente disponible. Se ofrecen sin ninguna garantía.

Cada script lo indica en su segunda línea con `# SPDX-License-Identifier: GPL-3.0-or-later`, una etiqueta estándar que identifica la licencia aunque el archivo se copie suelto.

Copyright © 2026 Gez-Schegtel.
