#!/usr/bin/env bash
# Sincroniza las guías oficiales de n8n-io/skills (carpeta skills/ de este repo)
# dentro de la skill única de Mectronics. No modifica el contenido: solo renombra
# SKILL.md -> GUIA.md (claude.ai rechaza SKILL.md anidados en una skill).
# Uso: bash mectronics/sync-oficial.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/skills"
DEST="$ROOT/mectronics/n8n-automation-mectronics/references/oficial"
[ -d "$SRC" ] || { echo "ERROR: no existe $SRC" >&2; exit 1; }

rm -rf "$DEST"; mkdir -p "$DEST"
for d in "$SRC"/*/; do
  n="$(basename "$d")"
  cp -R "$d" "$DEST/$n"
  [ -f "$DEST/$n/SKILL.md" ] && mv "$DEST/$n/SKILL.md" "$DEST/$n/GUIA.md"
done
cp "$ROOT/LICENSE" "$DEST/LICENSE"

if find "$DEST" -name SKILL.md | grep -q .; then
  echo "ERROR: quedaron SKILL.md anidados" >&2; exit 1
fi

INFO="$(git -C "$ROOT" log -1 --format='%H|%cs|%s' -- skills)"
cat > "$DEST/UPSTREAM.md" <<EOT
# Origen de las guías oficiales

- Repositorio: https://github.com/n8n-io/skills (licencia Apache 2.0, ver LICENSE)
- Último commit que tocó skills/: ${INFO%%|*}
- Fecha: $(echo "$INFO" | cut -d'|' -f2)
- Título: $(echo "$INFO" | cut -d'|' -f3-)
- Sincronizado: $(date +%F)

## Cambios respecto al original
Ninguno en el contenido. Solo se renombró SKILL.md a GUIA.md en cada guía.
Donde el texto oficial dice "invoca la skill X con la herramienta Skill",
leer references/oficial/X/GUIA.md (ver tabla en el SKILL.md raíz).
EOT
echo "Guías sincronizadas: $(ls -d "$DEST"/*/ | wc -l)"
