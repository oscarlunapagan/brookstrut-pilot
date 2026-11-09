#!/usr/bin/env bash
# Despliega el repositorio en WRK_DEV: migraciones pendientes, todo el código y la app 100.
# Sirve para ver y probar los cambios mientras se desarrolla. El veredicto lo da check.sh.
# Salida: 0 si despliega sin errores ni objetos inválidos, 1 si no, 2 si no se pudo conectar.
set -uo pipefail
source "$(dirname "$0")/lib/common.sh"
mkdir -p "$WORK"

if ! check_connection wrk_dev; then
  echo "No se pudo conectar a WRK_DEV. Detalle en $WORK/connection-wrk_dev.log" >&2
  exit 2
fi

echo "Desplegando en WRK_DEV..."
if ! lb_update wrk_dev dev "$WORK/deploy-dev.log"; then
  if is_network_error "$WORK/deploy-dev.log"; then
    echo "Se perdió la conexión durante el despliegue. Detalle en $WORK/deploy-dev.log" >&2
    exit 2
  fi
  echo "El despliegue falló:" >&2
  grep -aE -A8 "Running Changeset|^ORA-|Error report|APEXlang Compile Errors" "$WORK/deploy-dev.log" | tail -40 >&2
  echo "Salida completa en $WORK/deploy-dev.log" >&2
  exit 1
fi
grep -aE "Running Changeset|Importing application" "$WORK/deploy-dev.log"

invalid_objects wrk_dev "$WORK/invalid-dev.log"
if grep -aqE $'^(compile|invalid)\t' "$WORK/invalid-dev.log"; then
  echo "Desplegado, pero hay errores de compilación u objetos inválidos:" >&2
  grep -aE $'^(compile|invalid)\t' "$WORK/invalid-dev.log" | cut -f2- | tr '\t' ':' >&2
  exit 1
fi
echo "Desplegado en WRK_DEV sin errores."
