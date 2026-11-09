# Brookstrut

Aplicación Oracle APEX 26.1 de una cadena de tiendas, sobre Oracle Autonomous Database 26ai. Este repositorio es la fuente de verdad: el esquema, el código PL/SQL y la app se despliegan desde aquí.

## Antes de empezar

- **Qué hace la app:** [`docs/functional-analysis.md`](docs/functional-analysis.md). Léelo entero antes de cambiar nada.
- **Qué hay que hacer:** el documento de requisitos de `docs/requirements/` que te indiquen. Implementa exactamente lo que dice, ni más ni menos. Lo que el requisito excluye no se toca, aunque veas un fallo.
- **Estructura y despliegue:** [`README.md`](README.md).

## Entorno

Hay dos conexiones guardadas en SQLcl. Abre SQLcl siempre desde la raíz del repositorio.

| Conexión | Para qué |
|---|---|
| `wrk_dev` | Desarrollo. Tiene la app 100 y datos de ejemplo. Puedes consultar todo lo que necesites |
| `wrk_clean` | Solo la usa `scripts/check.sh`, que la vacía en cada ejecución. No la uses |

```bash
sql -name wrk_dev                      # sesión interactiva
echo "select ..." | sql -S -name wrk_dev   # una consulta
```

La app 100 está en el workspace `WRK`. Para ver tus cambios en `WRK_DEV`, despliega con `scripts/deploy-dev.sh`.

## Cómo se hacen los cambios

**Todo cambio va en un archivo del repositorio.** No cambies nada directamente en la base de datos ni en el App Builder: lo que no está en el repositorio no existe, y `check.sh` lo detecta al desplegar desde cero.

| Qué cambias | Dónde |
|---|---|
| Tablas, columnas, índices, restricciones o datos de referencia | Una migración nueva en `db/migrations/NNNN-descripcion.sql`, con el número siguiente. Empieza por `-- liquibase formatted sql` y `-- changeset brookstrut:NNNN-descripcion`. Las migraciones existentes no se modifican nunca |
| Paquetes, triggers, vistas, funciones o procedimientos | Un archivo por objeto en `db/code/<tipo>/<objeto>.sql`, con `create or replace` y sin cabecera de Liquibase. Si es nuevo, añádelo a `db/code.sql`, en su grupo: especificaciones, cuerpos y triggers |
| Borrar un objeto de código | Una migración con `drop`, y quitar su archivo y su línea de `db/code.sql` |
| La app | Los archivos APEXlang de `apex/f100/`. Comprueba la sintaxis con `apex validate -input apex/f100` dentro de SQLcl |

**No modifiques** `scripts/`, `db/env/`, `db/changelog.xml`, `db/apex.sql` ni `apex/f100/deployments/`. Tampoco `docs/functional-analysis.md` ni los documentos de requisitos: los mantiene quien los aprueba. La única excepción es el plan del evolutivo, que escribes tú.

## Convenciones

- **Nombres** de objetos en inglés, con el prefijo `oow_demo_` como el resto del esquema. **Comentarios** en español.
- **PL/SQL** en minúsculas, como el código nuevo de este repositorio. Variables con bind, nunca concatenando valores en SQL dinámico. Nada de `when others then null`.
- **La lógica de negocio va en paquetes,** no en los procesos de las páginas. Una página llama al paquete.
- **El documento de requisitos manda** sobre estas convenciones si dice algo distinto.

## Tests

- **Al menos un test utPLSQL por criterio de aceptación,** escrito antes de la implementación. El nombre del test incluye el ID del criterio, por ejemplo `--%test(RF001-CA1: conserva precios y ofertas al cambiar la dirección)`.
- **Un paquete de tests por paquete probado:** `test_<paquete>`, en `db/code/package_specs/` y `db/code/package_bodies/`, y en `db/code.sql` como cualquier otro paquete.
- **Cada test crea sus propios datos.** `check.sh` ejecuta los tests en un esquema vacío, sin los datos de ejemplo. Si un criterio menciona datos de ejemplo, como "Moscone Store", reproduce esa situación en el test.
- **Deja una línea en blanco** después de `--%suite`, o utPLSQL no reconoce la suite.
- **Para ejecutarlos en `wrk_dev`:** `select * from table(ut3.ut.run('test_<paquete>'));`. Usa siempre `ut3.ut.run`, cualificado. utPLSQL deshace los cambios de cada test, así que no quedan datos de prueba.
- **No debilites, desactives ni borres un test para que pase.** Si un test está mal, corrígelo y explícalo en el PR.

## Comprobar el trabajo

| Script | Qué hace | Cuándo |
|---|---|---|
| `scripts/deploy-dev.sh` | Despliega el repositorio en `WRK_DEV` e importa la app 100 | Mientras desarrollas, para ver y probar tus cambios |
| `scripts/check.sh` | Vacía `WRK_CLEAN`, despliega desde cero, comprueba que todo compila y no hay objetos inválidos, ejecuta todos los tests y valida la app. Deja los hallazgos en `check.json` | Antes de dar el trabajo por terminado |

**Código de salida de `check.sh`:**

- **0:** todo pasa.
- **1:** hay hallazgos. Lee `check.json`, corrige y vuelve a ejecutarlo.
- **2:** no se pudo comprobar, por ejemplo porque la base de datos no responde. No es un fallo tuyo: espera un minuto y repite. Si persiste, para y explícalo.

**El trabajo está terminado cuando `check.sh` termina con 0.**

## Git y PR

- Trabaja en una rama `ev-nnn-descripcion` creada desde `main`. Nunca hagas commit en `main`.
- Commits en Conventional Commits, con la descripción en español y en imperativo: `fix(tiendas): conservar los precios al guardar el inventario`.
- Al terminar, abre un PR contra `main` con `gh pr create`. Su descripción incluye:
  - Qué has cambiado, en pocas líneas.
  - Una tabla con cada criterio de aceptación y el test que lo comprueba.
  - Las decisiones que has tomado donde los requisitos no eran explícitos.
  - Cómo lo has comprobado: el resultado de `check.sh` y lo que hayas probado en la app.

## Si algo no está claro

Toma la interpretación más razonable según los requisitos y el análisis funcional, y sigue. Anota cada decisión en el plan del evolutivo (`docs/requirements/EV-nnn-plan.md`) y en el PR. Para solo si no puedes avanzar sin una respuesta.
