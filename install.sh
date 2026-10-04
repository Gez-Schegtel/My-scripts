#!/usr/bin/env bash
# ==============================================================================
# install.sh — Instala los scripts de este repositorio como comandos
#
# Crea en /usr/local/bin un enlace simbólico a cada script ejecutable de:
#   common/    → se instala en todas las distribuciones.
#   <distro>/  → solo en esa distribución. El nombre de la carpeta es el ID de
#                /etc/os-release (debian, ubuntu, fedora...). Si un script
#                está en las dos carpetas, se instala el de la distribución.
#
# Deja /usr/local/bin sincronizado con el repositorio: crea los enlaces que
# faltan, corrige los que apuntan mal y quita los de scripts que ya no están.
# Solo toca enlaces que apuntan a este repositorio; nada más.
#
# No instala un script (y avisa) si su nombre ya lo usa otro comando: uno del
# sistema, uno interno de bash o cualquier otro de tu PATH. Si ya estaba
# instalado y después apareció un programa con ese nombre, quita el enlace.
#
# Ejecutalo al agregar, borrar, renombrar o mover un script, o al cambiarle
# el permiso de ejecución. Editar un script NO requiere reinstalar.
#
# Uso:
#   ./install.sh               Instala o sincroniza.
#   ./install.sh --uninstall   Quita todos los enlaces de este repositorio.
#                              Usalo antes de mover o renombrar la carpeta.
# ==============================================================================
set -euo pipefail

BIN=/usr/local/bin
REPO=$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)
SHOW_REPO=${REPO/#"$HOME"/\~} # para mostrar rutas cortas (~/.mis-scripts)

if [[ ! -d $REPO/common ]]; then
  echo "❌ $REPO no parece el repositorio de scripts (falta common/)." >&2
  exit 1
fi

# Si no hay permiso de escritura en BIN, los cambios se hacen con sudo. La
# contraseña se pide recién en el primer cambio: si no hay nada que hacer,
# no se pide.
SUDO=()
[[ -w $BIN ]] || SUDO=(sudo)
priv() { "${SUDO[@]}" "$@"; }

# ¿Es un enlace que apunta a este repositorio? (este instalador siempre crea
# los enlaces con la ruta completa del script)
ours() { [[ -L $1 && $(readlink -- "$1") == "$REPO"/* ]]; }

# ¿Es un script? Un archivo que no empieza con "#!" (un README, por ejemplo)
# no lo es.
is_script() {
  local first=""
  IFS= read -r -n 2 first <"$1" || true
  [[ $first == '#!' ]]
}

# Si el nombre ya lo usa otro comando, imprime cuál y devuelve 0. Revisa los
# comandos internos de bash, todo tu PATH y también sbin (aunque no esté en
# tu PATH, sudo y root sí lo usan). Ignora el enlace propio del repositorio.
taken_by() {
  local p
  case $(type -t "$1" || true) in
  builtin | keyword)
    echo "un comando interno de bash"
    return 0
    ;;
  esac
  while IFS= read -r p; do
    [[ $(readlink -f -- "$p") == "$REPO"/* ]] && continue
    echo "$p"
    return 0
  done < <(
    type -ap "$1" || true
    for d in /usr/local/sbin /usr/sbin /usr/bin /sbin /bin; do
      if [[ -e $d/$1 ]]; then echo "$d/$1"; fi
    done
  )
  return 1
}

# Los avisos se juntan y se muestran una sola vez, al final
WARNINGS=()
warn() { WARNINGS+=("$*"); }

# ------------------------------------------------------------------------------
# DESINSTALAR
# ------------------------------------------------------------------------------
case ${1:-} in
"") ;;
--uninstall)
  n=0
  for link in "$BIN"/*; do
    if ours "$link"; then
      priv rm -- "$link"
      echo "  − ${link##*/}"
      n=$((n + 1))
    fi
  done
  echo "✅ Se quitaron $n enlace(s). Los scripts del repositorio no se tocaron."
  exit 0
  ;;
*)
  echo "Uso: ./install.sh [--uninstall]" >&2
  exit 2
  ;;
esac

# ------------------------------------------------------------------------------
# QUÉ HAY QUE INSTALAR
# ------------------------------------------------------------------------------
DISTRO=$(. /etc/os-release 2>/dev/null && echo "${ID:-}") || DISTRO=""
dirs=("$REPO/common")
label="common/"
if [[ -n $DISTRO && -d $REPO/$DISTRO ]]; then
  dirs+=("$REPO/$DISTRO")
  label+=" y $DISTRO/"
else
  warn "No existe la carpeta '${DISTRO:-?}/' en el repositorio: solo se instalan los scripts de common/."
fi

# Candidatos: nombre del comando → script (el de la distribución pisa al de
# common/ porque se procesa después). Los scripts sin +x se anotan aparte.
declare -A CAND=() NOEXEC_NAME=() TAKEN=()
NOEXEC=()
for dir in "${dirs[@]}"; do
  for f in "$dir"/*; do
    [[ -f $f ]] || continue
    if [[ -x $f ]]; then
      CAND[${f##*/}]=$f
    elif is_script "$f"; then
      NOEXEC+=("$f")
      NOEXEC_NAME[${f##*/}]=${f#"$REPO"/}
    fi
  done
done

# Si no hay ningún script, lo más probable es que el repositorio esté a medias
# (por ejemplo, en medio de una operación de git): no se toca nada, para no
# quitar todos los comandos por error.
if ((${#CAND[@]} == 0)); then
  echo "❌ No se encontró ningún script ejecutable en $label. No se modificó nada." >&2
  exit 1
fi

# Se instalan los candidatos cuyo nombre está libre
declare -A WANTED=()
mapfile -t names < <(printf '%s\n' "${!CAND[@]}" | sort)
for name in "${names[@]}"; do
  link=$BIN/$name
  if [[ -e $link || -L $link ]] && ! ours "$link"; then
    what="un archivo"
    [[ -L $link ]] && what="un enlace a $(readlink -- "$link")"
    warn "$name no está instalado: $link ya existe y es $what, que no es de este repositorio. Si sobra (por ejemplo, un enlace de antes de mover el repositorio), borralo con: sudo rm $link"
  elif where=$(taken_by "$name"); then
    TAKEN[$name]=$where
    warn "$name no está instalado: ese nombre ya lo usa $where. Cambiale el nombre al script."
  else
    WANTED[$name]=${CAND[$name]}
  fi
done

for f in "${NOEXEC[@]}"; do
  rel=${f#"$REPO"/}
  msg="$rel no tiene permiso de ejecución, así que no está instalado"
  if [[ -n ${WANTED[${f##*/}]+x} ]]; then
    msg+=" (por ahora se usa ${WANTED[${f##*/}]#"$REPO"/})"
  fi
  warn "$msg. Arreglalo con: chmod +x $SHOW_REPO/$rel"
done

if [[ ":$PATH:" != *":$BIN:"* ]]; then
  warn "$BIN no está en tu PATH: los comandos no se van a encontrar."
fi

echo "🔗 Sincronizando $BIN con $SHOW_REPO ($label)..."
added=0 fixed=0 removed=0

# ------------------------------------------------------------------------------
# 1. QUITAR LOS ENLACES QUE YA NO CORRESPONDEN
# ------------------------------------------------------------------------------
# Cada enlace quitado muestra el motivo. Si hay algo que hacer al respecto
# (dar permiso de ejecución, cambiar el nombre), el aviso del final lo dice.
for link in "$BIN"/*; do
  ours "$link" || continue
  name=${link##*/}
  [[ -z ${WANTED[$name]+x} ]] || continue

  target=$(readlink -- "$link")
  rel=${target#"$REPO"/}
  dir=${rel%%/*}
  if [[ -n ${TAKEN[$name]+x} ]]; then
    reason="ese nombre ahora lo usa ${TAKEN[$name]}"
  elif [[ -n ${NOEXEC_NAME[$name]+x} ]]; then
    reason="${NOEXEC_NAME[$name]} no tiene permiso de ejecución"
  elif [[ ! -e $target ]]; then
    reason="$rel se borró, se movió o se renombró"
  elif [[ $dir != common && $dir != "$DISTRO" ]]; then
    reason="es de $dir/, que no corresponde a esta distribución"
  elif [[ ! -x $target ]]; then
    reason="$rel ya no es ejecutable"
  else
    reason="no corresponde a ningún script de $label"
  fi

  priv rm -- "$link"
  echo "  − $name (quitado: $reason)"
  removed=$((removed + 1))
done

# ------------------------------------------------------------------------------
# 2. CREAR LOS QUE FALTAN Y CORREGIR LOS QUE APUNTAN A OTRO LADO
# ------------------------------------------------------------------------------
for name in "${names[@]}"; do
  [[ -n ${WANTED[$name]+x} ]] || continue
  src=${WANTED[$name]}
  link=$BIN/$name
  if ours "$link"; then
    [[ $(readlink -- "$link") == "$src" ]] && continue # ya está bien
    priv ln -sfn -- "$src" "$link"
    echo "  ~ $name → ${src#"$REPO"/} (corregido)"
    fixed=$((fixed + 1))
  else
    priv ln -s -- "$src" "$link"
    echo "  + $name → ${src#"$REPO"/}"
    added=$((added + 1))
  fi
done

# ------------------------------------------------------------------------------
# RESUMEN
# ------------------------------------------------------------------------------
icon="✅"
((${#WARNINGS[@]} == 0)) || icon="⚠️ "

if ((added + fixed + removed == 0)); then
  echo "$icon Todo al día: ${#WANTED[@]} comando(s) instalado(s)."
else
  parts=()
  ((added == 0)) || parts+=("$added nuevo(s)")
  ((fixed == 0)) || parts+=("$fixed corregido(s)")
  ((removed == 0)) || parts+=("$removed quitado(s)")
  detail=$(printf '%s, ' "${parts[@]}")
  echo "$icon Listo: ${#WANTED[@]} comando(s) instalado(s) (${detail%, })."
fi

if ((${#WARNINGS[@]} > 0)); then
  echo
  echo "Avisos:"
  printf '  • %s\n' "${WARNINGS[@]}"
fi
