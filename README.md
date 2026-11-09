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
