#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: install.sh
# DESCRIPCIÓN:
#   Instala los scripts del repositorio como comandos del sistema mediante
#   enlaces simbólicos en /usr/local/bin.
#     - common/   → se instalan en todas las distribuciones.
#     - <distro>/ → solo en esa distribución. El nombre de la carpeta debe
#                   coincidir con el campo ID de /etc/os-release
#                   (ubuntu, debian, fedora, arch, etc.).
#   Si un script existe en common/ y en la carpeta de la distribución con el
#   mismo nombre, se instala el de la distribución.
#
#   Deja /usr/local/bin exactamente sincronizado con el repositorio:
#     1. Quita los enlaces al repositorio que ya no corresponden (scripts
#        borrados, movidos, renombrados, sin permiso de ejecución o de otra
#        distribución).
#     2. Crea los enlaces nuevos y corrige los rotos o desactualizados.
#     3. Verifica que no haya quedado ningún enlace roto al repositorio.
#   Es seguro ejecutarlo todas las veces que quieras.
#
# GARANTÍAS DE SEGURIDAD
#   - Solo crea y borra ENLACES SIMBÓLICOS: nunca borra ni modifica archivos.
#   - Solo toca enlaces de /usr/local/bin que apuntan a este repositorio;
#     nunca toca programas, archivos ni enlaces ajenos.
#   - Antes de tocar nada, verifica que su carpeta sea realmente el
#     repositorio (que contenga common/).
#   - Si no encuentra ningún script para instalar, no modifica nada (evita
#     borrar todos los comandos por error, p. ej. con el repositorio a medias).
#   - Pide la contraseña de administrador ANTES de hacer cualquier cambio.
#   - Al terminar verifica que no haya quedado ningún enlace roto.
#   - Avisa si un script tiene el mismo nombre que un comando del sistema
#     (lo taparía, porque /usr/local/bin tiene prioridad en el PATH).
#
# USO:
#   ./install.sh               Instala o sincroniza los comandos.
#   ./install.sh --uninstall   Elimina todos los comandos de este repositorio.
#   ./install.sh --help        Muestra la ayuda.
#
#   Ejecutalo después de clonar y cada vez que agregues, muevas, renombres o
#   borres un script. Editar el contenido de un script NO requiere reinstalar.
#   Antes de mover o renombrar la carpeta del repositorio, ejecutá
#   ./install.sh --uninstall; después, install.sh desde la nueva ubicación.
#
# REQUISITOS:
#   bash 4.4 o superior, coreutils (readlink -m) y sudo.
#   En un sistema sin sudo, ejecutalo como root.
# ==============================================================================

set -euo pipefail

BIN="/usr/local/bin"
# Ruta real del repositorio (sin enlaces simbólicos intermedios)
REPO=$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)

usage() {
	cat <<'EOF'
Uso: ./install.sh [--uninstall | --help]

Sin opciones, instala o sincroniza en /usr/local/bin los scripts de common/
y los de la carpeta de tu distribución.

Opciones:
  -u, --uninstall   Elimina todos los comandos instalados desde este repositorio.
  -h, --help        Muestra esta ayuda.
EOF
}

MODE=install
case ${1:-} in
"") ;;
-u | --uninstall) MODE=uninstall ;;
-h | --help)
	usage
	exit 0
	;;
*)
	echo "❌ Opción desconocida: $1" >&2
	usage >&2
	exit 2
	;;
esac

# ------------------------------------------------------------------------------
# COMPROBACIONES DE SEGURIDAD
# ------------------------------------------------------------------------------
# Todo enlace que apunte dentro de REPO se considera "propio", así que antes
# de tocar nada hay que asegurarse de que REPO es realmente el repositorio.
if [[ $REPO == / || ! -d $REPO/common ]]; then
	echo "❌ '$REPO' no parece ser el repositorio de scripts (falta common/)." >&2
	echo "   No se modificó nada." >&2
	exit 1
fi

# Usar sudo solo si no hay permiso de escritura en el destino
SUDO=()
if [[ ! -w $BIN ]]; then
	SUDO=(sudo)
fi

# ------------------------------------------------------------------------------
# FUNCIONES AUXILIARES
# ------------------------------------------------------------------------------
# Pide la contraseña antes de cualquier cambio: si falla, no queda nada a medias
ensure_sudo() {
	((${#SUDO[@]} > 0)) || return 0
	echo "🔐 Se necesitan permisos de administrador para modificar $BIN."
	if ! sudo -v; then
		echo "❌ No se pudieron obtener permisos de administrador. No se modificó nada." >&2
		exit 1
	fi
}

# Devuelve 0 si el enlace apunta a un archivo dentro del repositorio, aunque
# ese archivo ya no exista. readlink -m resuelve la ruta real completa, así
# que reconoce el enlace sin importar cómo esté escrito.
points_to_repo() {
	local dest
	dest=$(readlink -m -- "$1") || return 1
	[[ $dest == "$REPO"/* ]]
}

# Imprime, uno por línea, los enlaces de BIN que apuntan al repositorio
repo_links() {
	local link
	for link in "$BIN"/*; do
		if [[ -L $link ]] && points_to_repo "$link"; then
			printf '%s\n' "$link"
		fi
	done
}

# Avisa si el comando tapa a uno del sistema con el mismo nombre
warn_shadow() {
	local d
	for d in /usr/sbin /usr/bin /sbin /bin; do
		if [[ -e $d/$1 ]]; then
			echo "      ⚠️  Tapa al comando del sistema $d/$1 (/usr/local/bin tiene prioridad)."
			return 0
		fi
	done
	return 0
}

# ------------------------------------------------------------------------------
# MODO DESINSTALACIÓN
# ------------------------------------------------------------------------------
if [[ $MODE == uninstall ]]; then
	mapfile -t links < <(repo_links)
	if ((${#links[@]} == 0)); then
		echo "ℹ️  No hay comandos instalados desde $REPO."
		exit 0
	fi
	ensure_sudo
	echo "🗑️  Eliminando los comandos instalados desde $REPO..."
	for link in "${links[@]}"; do
		"${SUDO[@]}" rm -f -- "$link"
		echo "   🗑️  $(basename "$link")"
	done
	echo "✅ Se eliminaron ${#links[@]} enlace(s). Los scripts del repositorio no se tocaron."
	exit 0
fi

# ------------------------------------------------------------------------------
# QUÉ DEBERÍA ESTAR INSTALADO
# ------------------------------------------------------------------------------
DISTRO=$(. /etc/os-release 2>/dev/null && printf '%s' "${ID:-}") || DISTRO=""
if [[ ! $DISTRO =~ ^[a-z0-9][a-z0-9._-]*$ ]]; then
	echo "❌ No se pudo detectar la distribución (campo ID de /etc/os-release)." >&2
	exit 1
fi

dirs=("$REPO/common")
if [[ -d $REPO/$DISTRO ]]; then
	dirs+=("$REPO/$DISTRO")
else
	echo "⚠️  No existe la carpeta '$DISTRO/': solo se instalarán los scripts comunes."
fi

# WANTED: nombre del comando → ruta del script. La carpeta de la distribución
# se procesa después de common/, así que su versión tiene prioridad.
declare -A WANTED=()
for dir in "${dirs[@]}"; do
	for f in "$dir"/*; do
		[[ -f $f ]] || continue
		if [[ ! -x $f ]]; then
			echo "⚠️  ${f#"$REPO"/}: no tiene permiso de ejecución (chmod +x). Se omite."
			continue
		fi
		WANTED[$(basename "$f")]=$f
	done
done

if ((${#WANTED[@]} == 0)); then
	echo "❌ No se encontró ningún script ejecutable para instalar. No se modificó nada." >&2
	exit 1
fi

echo "📦 Distribución: $DISTRO — scripts a instalar: ${#WANTED[@]}"
ensure_sudo

# ------------------------------------------------------------------------------
# PASO 1: QUITAR ENLACES QUE YA NO CORRESPONDEN
# ------------------------------------------------------------------------------
echo "🧹 1/3 - Quitando enlaces que ya no corresponden..."
removed=0
mapfile -t links < <(repo_links)
for link in "${links[@]}"; do
	cmd=$(basename "$link")
	if [[ -z ${WANTED[$cmd]+x} ]]; then
		if [[ -e $link ]]; then
			reason="ya no forma parte de la instalación"
		else
			reason="enlace roto: el script ya no existe"
		fi
		"${SUDO[@]}" rm -f -- "$link"
		echo "   🗑️  $cmd ($reason)"
		removed=$((removed + 1))
	fi
done
if ((removed == 0)); then
	echo "   Nada que quitar."
fi

# ------------------------------------------------------------------------------
# PASO 2: CREAR Y ACTUALIZAR ENLACES
# ------------------------------------------------------------------------------
echo "🔗 2/3 - Creando y actualizando enlaces..."
conflicts=0
mapfile -t cmds < <(printf '%s\n' "${!WANTED[@]}" | sort)
for cmd in "${cmds[@]}"; do
	[[ -n $cmd ]] || continue
	src=${WANTED[$cmd]}
	target="$BIN/$cmd"

	if [[ -L $target ]] && points_to_repo "$target"; then
		# Ya es nuestro: ¿apunta al lugar correcto y funciona?
		if [[ -e $target && $(readlink -m -- "$target") == "$src" ]]; then
			echo "   ✔ $cmd (sin cambios)"
			warn_shadow "$cmd"
			continue
		fi
		state="corregido"
	elif [[ -e $target || -L $target ]]; then
		# Existe algo con ese nombre que no es del repositorio: no se toca
		echo "   ⚠️  $cmd: ya existe en $BIN y no pertenece al repositorio. Se omite."
		echo "      Si es un enlace viejo de otra ubicación del repositorio, borralo con: sudo rm $target"
		conflicts=$((conflicts + 1))
		continue
	else
		state="nuevo"
	fi

	"${SUDO[@]}" ln -sfn -- "$src" "$target"
	echo "   ✔ $cmd → ${src#"$REPO"/} ($state)"
	warn_shadow "$cmd"
done

# ------------------------------------------------------------------------------
# PASO 3: VERIFICACIÓN FINAL
# ------------------------------------------------------------------------------
echo "🔎 3/3 - Verificando que no haya enlaces rotos..."
broken=0
mapfile -t links < <(repo_links)
for link in "${links[@]}"; do
	if [[ ! -e $link ]]; then
		echo "   ❌ Enlace roto: $link → $(readlink -- "$link")"
		broken=$((broken + 1))
	fi
done

if ((broken > 0)); then
	echo "❌ Quedaron $broken enlace(s) roto(s). Revisá los mensajes anteriores." >&2
	exit 1
fi

echo "✅ Listo: ${#links[@]} comando(s) instalados y ningún enlace roto."
if ((conflicts > 0)); then
	echo "⚠️  $conflicts comando(s) omitidos por conflicto de nombre (ver arriba)."
fi
