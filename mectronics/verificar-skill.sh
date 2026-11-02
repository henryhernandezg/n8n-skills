#!/usr/bin/env bash
# Verificación estructural de la skill n8n-automation-mectronics.
# Uso: bash mectronics/verificar-skill.sh   (desde la raíz del repositorio)
# No ejecuta nada contra el n8n real: valida estructura, integridad y cobertura.
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
S="$RAIZ/mectronics/n8n-automation-mectronics"
OK=0; FALLA=0
ok()   { echo "  [OK]    $1"; OK=$((OK+1)); }
falla(){ echo "  [FALLA] $1"; FALLA=$((FALLA+1)); }
chk()  { if eval "$2" >/dev/null 2>&1; then ok "$1"; else falla "$1"; fi; }

echo "1. Estructura"
chk "SKILL.md existe" "[ -f '$S/SKILL.md' ]"
chk "Un solo SKILL.md en toda la skill (claude.ai rechaza anidados)" "[ \$(find '$S' -name SKILL.md | wc -l) -eq 1 ]"
chk "Frontmatter con name correcto" "head -5 '$S/SKILL.md' | grep -qE '^name: \"?n8n-automation-mectronics\"?\$'"
DESC=$(awk '/^description:/{sub(/^description: */,"");print;exit}' "$S/SKILL.md")
chk "Descripción <= 1024 caracteres (${#DESC})" "[ ${#DESC} -le 1024 ]"
chk "Descripción sin corchetes angulares" "! echo \"\$DESC\" | grep -q '[<>]'"

echo "2. Rutas citadas en SKILL.md existen"
FALTAN=0
while IFS= read -r ruta; do
  [ -e "$S/$ruta" ] || { echo "     falta: $ruta"; FALTAN=1; }
done < <(grep -o 'references/[A-Za-z0-9_./-]*\.md' "$S/SKILL.md" | sort -u)
chk "Todas las rutas references/*.md citadas existen" "[ $FALTAN -eq 0 ]"

echo "3. Sin pérdida de la skill original"
ORIG="$RAIZ/../../original.sha256"
if [ -f "$ORIG" ]; then
  H1=$(sha256sum "$S/references/mectronics/infraestructura-y-patrones.md" | cut -d' ' -f1)
  H2=$(sha256sum "$S/references/sdk-reference.md" | cut -d' ' -f1)
  chk "Contenido original de SKILL.md intacto" "[ '$H1' = '7d62e7500ed9798e02d4ce834f32d7d3a0ed2e635ec1aa2f574555b9feeb37c9' ]"
  chk "sdk-reference.md original intacto" "[ '$H2' = '920c50d84ecb3575460b9a5166a7d6e914a112dae55de5aa1774e3ed9527fdc4' ]"
else
  H1=$(sha256sum "$S/references/mectronics/infraestructura-y-patrones.md" | cut -d' ' -f1)
  H2=$(sha256sum "$S/references/sdk-reference.md" | cut -d' ' -f1)
  chk "Contenido original de SKILL.md intacto" "[ '$H1' = '7d62e7500ed9798e02d4ce834f32d7d3a0ed2e635ec1aa2f574555b9feeb37c9' ]"
  chk "sdk-reference.md original intacto" "[ '$H2' = '920c50d84ecb3575460b9a5166a7d6e914a112dae55de5aa1774e3ed9527fdc4' ]"
fi

echo "4. Guías oficiales idénticas al upstream (salvo renombre SKILL.md -> GUIA.md)"
N=0; IGUAL=0
for d in "$RAIZ"/skills/*/; do
  n=$(basename "$d"); N=$((N+1))
  if cmp -s "$d/SKILL.md" "$S/references/oficial/$n-official/GUIA.md" 2>/dev/null || \
     cmp -s "$d/SKILL.md" "$S/references/oficial/$n/GUIA.md" 2>/dev/null; then IGUAL=$((IGUAL+1)); fi
done
chk "Guías oficiales idénticas ($IGUAL de $N)" "[ $N -gt 0 ] && [ $IGUAL -eq $N ]"

echo "5. Cobertura del escenario correo -> Excel (modo guiado)"
G="$S/references/agente"
chk "Publicación por el usuario permitida (Nivel 1 y 2)"      "grep -q 'PUBLICA_USUARIO_FINAL.*true' '$G/riesgo.md'"
chk "publish_workflow en el flujo guiado"                      "grep -q 'publish_workflow' '$G/guiado.md'"
chk "Credenciales propias, nunca compartidas"                  "grep -qi 'No atar nunca un flujo de usuario a las credenciales compartidas' '$G/guiado.md'"
chk "Verificación con caso real tras publicar"                 "grep -qi 'caso real' '$G/guiado.md'"
chk "Ejemplo correo -> Excel presente"                         "[ -f '$G/ejemplo-correo-a-excel.md' ]"
chk "Excel: sesión de libro y una escritura por ejecución"     "grep -q 'createSession' '$G/ejemplo-correo-a-excel.md' && grep -q 'closeSession' '$G/ejemplo-correo-a-excel.md'"
chk "Dedup en Data Table, no staticData"                       "grep -q 'Data Table' '$G/ejemplo-correo-a-excel.md' && grep -q 'staticData' '$G/ejemplo-correo-a-excel.md'"
chk "Guardas anti-loop"                                        "grep -qi 'anti-loop' '$G/ejemplo-correo-a-excel.md'"
chk "Patrón del item vacío (sin alwaysOutputData)"             "grep -q 'alwaysOutputData' '$G/ejemplo-correo-a-excel.md'"
chk "Plan B sin MCP: importar JSON y publicar"                 "grep -q 'Import from file' '$G/sin-mcp.md' && grep -q 'Publish' '$G/sin-mcp.md'"
chk "Plan B: reintento único y búsqueda previa anti-duplicado" "grep -qi 'una sola vez' '$G/sin-mcp.md'"
chk "Requisito Entra de correo declarado como pendiente"       "grep -q 'AADSTS65001' '$G/ejemplo-correo-a-excel.md'"
chk "Nivel 3 reservado a DDS (WhatsApp, nómina, SIEF)"         "grep -qi 'WhatsApp' '$G/riesgo.md' && grep -qi 'DDS' '$G/riesgo.md'"

echo "6. Coherencia (frases contradictorias que ya se corrigieron)"
chk "Ninguna guía dice que el usuario NO publica"              "! grep -rniE 'no (puede|debe) publicar|solo DDS publica|DDS publica' '$G' '$S/SKILL.md'"

echo "7. Secretos"
chk "Sin claves, tokens ni secretos en la skill" "! grep -rniE '(client_secret|api[_-]?key|bearer [a-z0-9]{20,}|password)[\"'\\'' ]*[:=][\"'\\'' ]*[A-Za-z0-9+/_-]{12,}' '$S'"

echo
echo "Resultado: $OK correctas, $FALLA con fallas"
[ "$FALLA" -eq 0 ]
