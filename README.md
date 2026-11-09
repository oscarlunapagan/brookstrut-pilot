# Brookstrut pilot

Sample app Brookstrut de Oracle APEX 26.1, usada para probar el desarrollo con agentes de IA.

## Estructura

| Ruta | Contenido |
|---|---|
| `db/changelog.xml` | Orden del despliegue: migraciones, código y app |
| `db/migrations/` | Tablas y cambios de estructura. Solo se añaden, un changeset por cambio |
| `db/code/` | Un archivo por objeto de código, sin cabecera de Liquibase |
| `db/code.sql` | Recompila todo `db/code/` en cada despliegue. Debe listar todos sus archivos |
| `db/apex.sql` | Importa la app en cada despliegue |
| `db/env/` | Workspace, esquema, ID y alias de la app en cada entorno |
| `apex/f100/` | La app en APEXlang |

## Despliegue

Desde la raíz del repositorio, con SQLcl conectado al esquema del entorno:

```sql
whenever sqlerror exit failure
lb update -changelog-file db/changelog.xml -defaults-file db/env/dev.properties
```

## Scripts

| Script | Qué hace | Código de salida |
|---|---|---|
| `scripts/deploy-dev.sh` | Despliega el repositorio en `WRK_DEV`: migraciones pendientes, todo el código y la app 100 | 0 sin errores, 1 si el despliegue falla o hay objetos inválidos, 2 si no conecta |
| `scripts/check.sh` | Valida la app, comprueba `db/code.sql`, vacía `WRK_CLEAN`, despliega desde cero como app 1100, revisa la compilación y ejecuta todos los tests. Deja los hallazgos en `check.json` y los detalles en `.check/` | 0 sin hallazgos, 1 con hallazgos, 2 si no se pudo comprobar |

Necesitan las conexiones `wrk_dev` y `wrk_clean` guardadas en SQLcl, y Python 3.
