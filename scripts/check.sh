#!/usr/bin/env bash
# Comprueba que el repositorio, por sí solo, produce una app que compila y pasa los tests:
# valida la app, vacía WRK_CLEAN, despliega desde cero, revisa la compilación y ejecuta los tests.
# Deja los hallazgos en check.json, y los detalles en .check/.
# Salida: 0 si no hay hallazgos, 1 si los hay, 2 si no se pudo comprobar.
set -uo pipefail
source "$(dirname "$0")/lib/common.sh"
rm -rf "$WORK"
mkdir -p "$WORK"
FINDINGS="$WORK/findings.tsv"
: > "$FINDINGS"
START=$SECONDS
CLEAN_APP_ID=$(sed -n 's/^parameter\.apex\.app_id=//p' "$ROOT/db/env/clean.properties")

add() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$FINDINGS"; }

finish() {
  local result="$1" code="$2"
  python3 -I "$ROOT/scripts/lib/report.py" json "$FINDINGS" "$ROOT/check.json" "$result" $((SECONDS - START))
  local count
  count=$(wc -l < "$FINDINGS")
  case "$code" in
    0) echo "check.sh: sin hallazgos ($((SECONDS - START)) s)." ;;
    1) echo "check.sh: $count hallazgos. Detalle en check.json:" >&2
       cut -f1,2,3 "$FINDINGS" | head -30 | sed 's/\t/ | /g' >&2 ;;
    2) echo "check.sh: no se pudo comprobar. Detalle en check.json y en .check/." >&2 ;;
  esac
  exit "$code"
}

# Fallo de la comprobación, no del código: termina con 2
abort() { add "gate" "$1" "$2"; finish error 2; }

step() { echo "-> $*"; }

# 1. La app en APEXlang. No necesita la base de datos.
step "Validando la app"
printf 'apex validate -input apex/f100\nexit\n' | run_sql /nolog "$WORK/validate.log" || true
if ! grep -aq "Validation successful." "$WORK/validate.log"; then
  grep -aE -B1 -A4 "^Error:|Type: (ERROR|SYNTAX)" "$WORK/validate.log" | grep -aE "^(File|Line|Error):" \
    | paste -d' ' - - - | head -20 | while read -r line; do add apex_validate "apex/f100" "$line"; done
  [ -s "$FINDINGS" ] || add apex_validate "apex/f100" "apex validate no terminó con 'Validation successful.'. Ver .check/validate.log"
fi

# 2. Todos los archivos de db/code/ están en db/code.sql, y todo lo de db/code.sql existe
step "Revisando db/code.sql"
listed=$(sed -n 's/^@//p' "$ROOT/db/code.sql" | sort)
present=$(cd "$ROOT" && find db/code -type f -name '*.sql' | sort)
comm -13 <(echo "$listed") <(echo "$present") | while read -r f; do
  [ -n "$f" ] && add code_list "$f" "No está en db/code.sql, así que no se despliega"
done
comm -23 <(echo "$listed") <(echo "$present") | while read -r f; do
  [ -n "$f" ] && add code_list "$f" "Está en db/code.sql, pero el archivo no existe"
done

# 3. Conexión y esquema vacío
step "Vaciando WRK_CLEAN"
check_connection wrk_clean || abort connection "No se pudo conectar a WRK_CLEAN. Ver .check/connection-wrk_clean.log"
echo "@scripts/lib/wipe-clean.sql $CLEAN_APP_ID" | run_sql wrk_clean "$WORK/wipe.log"
if [ $? -ne 0 ] || grep -aq "^ORA-" "$WORK/wipe.log"; then
  abort wipe "No se pudo vaciar WRK_CLEAN. Ver .check/wipe.log"
fi

# 4. Despliegue desde cero
step "Desplegando desde cero"
if ! lb_update wrk_clean clean "$WORK/deploy.log"; then
  is_network_error "$WORK/deploy.log" && abort connection "Se perdió la conexión al desplegar. Ver .check/deploy.log"
  msg=$(grep -aE "^ORA-[0-9]+|APEXlang Compile Errors|Error report" "$WORK/deploy.log" | head -3 | tr '\n' ' ')
  changeset=$(grep -a "Running Changeset" "$WORK/deploy.log" | tail -1 | sed 's/.*Running Changeset: //')
  add deploy "${changeset:--}" "${msg:-El despliegue falló. Ver .check/deploy.log}"
  finish findings 1
fi

# 5. Compilación
step "Revisando la compilación"
invalid_objects wrk_clean "$WORK/invalid.log"
is_network_error "$WORK/invalid.log" && abort connection "Se perdió la conexión. Ver .check/invalid.log"
grep -aE $'^(compile|invalid)\t' "$WORK/invalid.log" >> "$FINDINGS"

# 6. La app se ha importado en esta ejecución
step "Comprobando la app $CLEAN_APP_ID"
cat <<EOF | run_sql wrk_clean "$WORK/app.log"
set heading off pagesize 0 feedback off
select 'APP_COUNT=' || count(*) from apex_applications where application_id = $CLEAN_APP_ID;
exit
EOF
app_count=$(sed -n 's/^APP_COUNT=//p' "$WORK/app.log" | tr -d '[:space:]')
is_network_error "$WORK/app.log" && abort connection "Se perdió la conexión. Ver .check/app.log"
if [ "$app_count" != 1 ]; then
  add deploy "app $CLEAN_APP_ID" "La app no se importó en esta ejecución. Ver .check/deploy.log"
fi

# 7. Tests
step "Ejecutando los tests"
cat <<'EOF' | run_sql wrk_clean "$WORK/tests.log"
set heading off pagesize 0 feedback off linesize 32767 trimspool on long 10000000 longchunksize 10000000
spool .check/tests.xml
select * from table(ut3.ut.run(ut3.ut_varchar2_list(user), ut3.ut_junit_reporter()));
spool off
exit
EOF
is_network_error "$WORK/tests.log" && abort connection "Se perdió la conexión al ejecutar los tests. Ver .check/tests.log"
python3 -I "$ROOT/scripts/lib/report.py" junit "$WORK/tests.xml" >> "$FINDINGS"

if [ -s "$FINDINGS" ]; then finish findings 1; else finish pass 0; fi
