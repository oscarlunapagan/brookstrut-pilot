# Funciones comunes de deploy-dev.sh y check.sh. Se carga con source.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="$ROOT/.check"
SQL_TIMEOUT=900

# Errores de red o de sesión: la comprobación no se pudo hacer, no es un fallo del código
NETWORK_ERRORS='ORA-12[0-9]{3}|ORA-0311[34]|ORA-17002|ORA-17008|IO Error|Connection reset|Closed Connection'

# run_sql <conexión | /nolog> <salida> : ejecuta en SQLcl lo que llega por la entrada estándar, desde la raíz del repositorio
run_sql() {
  local conn="$1" out="$2"
  if [ "$conn" = /nolog ]; then
    (cd "$ROOT" && timeout "$SQL_TIMEOUT" sql -S /nolog) > "$out" 2>&1
  else
    (cd "$ROOT" && timeout "$SQL_TIMEOUT" sql -S -name "$conn") > "$out" 2>&1
  fi
}

# is_network_error <salida> : cierto si la salida muestra un error de red o de sesión
is_network_error() {
  grep -aqE "$NETWORK_ERRORS" "$1"
}

# check_connection <conexión> : cierto si la base de datos responde con esa conexión
check_connection() {
  local out="$WORK/connection-$1.log"
  echo "select 'CONNECTION_OK' from dual;" | run_sql "$1" "$out"
  grep -aq CONNECTION_OK "$out"
}

# lb_update <conexión> <entorno> <salida> : despliega el repositorio; cierto si termina bien
lb_update() {
  local conn="$1" env="$2" out="$3"
  mkdir -p "$WORK/liquibase"
  printf 'whenever sqlerror exit failure\nlb update -changelog-file db/changelog.xml -defaults-file db/env/%s.properties -log-path %s\nexit\n' \
    "$env" "$WORK/liquibase" | run_sql "$conn" "$out"
  local rc=$?
  [ "$rc" -eq 0 ] && grep -aq "Operation completed successfully" "$out" && ! grep -aqE "^ORA-|Error report|APEXlang Compile Errors" "$out"
}

# invalid_objects <conexión> <salida> : lista errores de compilación y objetos inválidos, uno por línea.
# El SQL solo emite ASCII: los textos en español se ponen aquí, porque SQLcl no lee la entrada en UTF-8.
invalid_objects() {
  cat <<'EOF2' | run_sql "$1" "$2.raw"
set heading off pagesize 0 feedback off linesize 32767 trimspool on
select 'compile' || chr(9) || type || ' ' || name || ' LINE ' || line || chr(9) || replace(text, chr(10), ' ')
from user_errors where attribute = 'ERROR'
union all
select 'invalid' || chr(9) || object_type || ' ' || object_name || chr(9) || 'INVALID_OBJECT'
from user_objects where status <> 'VALID' and object_name not like 'BIN$%';
exit
EOF2
  sed -E -e 's/ LINE ([0-9]+)\t/, línea \1\t/' -e 's/\tINVALID_OBJECT\s*$/\tObjeto inválido/' "$2.raw" > "$2"
}
