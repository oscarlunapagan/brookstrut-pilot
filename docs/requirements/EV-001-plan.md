# EV-001: plan de implementación

Plan del correctivo [EV-001](EV-001.md): conservar los precios y las ofertas al guardar una tienda.

## 1. Causa

El proceso "Save Inventory" de la página 7 borra todas las filas de `OOW_DEMO_STORE_PRODUCTS` de la tienda y vuelve a insertar una por producto seleccionado, solo con `STORE_ID` e `ITEM_ID`. Se pierden el precio de tienda, el descuento, las fechas de oferta y los `ID` de las filas, aunque el usuario no cambie el inventario.

## 2. Solución

1. **Paquete nuevo `oow_demo_store_pkg`** (`db/code/package_specs/` y `db/code/package_bodies/`), con el procedimiento `save_inventory(p_store_id, p_item_ids)`. Recibe los productos seleccionados y aplica solo las diferencias con el inventario actual:
   - Borra las filas de la tienda cuyo producto no está en la selección.
   - Inserta, sin precio de tienda ni oferta, los productos de la selección que la tienda no tiene.
   - No toca las filas de los productos que siguen seleccionados.
2. **Dos versiones del procedimiento:** una recibe `apex_t_number`, para reutilizarlo desde PL/SQL, y otra la cadena separada por `:` que devuelve el shuttle `P7_STORE_ITEMS`, que la convierte con `apex_string.split_numbers` y llama a la primera.
3. **Página 7:** el proceso "Save Inventory" se limita a llamar a `oow_demo_store_pkg.save_inventory(p_store_id => :P7_ID, p_item_ids => :P7_STORE_ITEMS)`. Mantiene su secuencia, su condición (`P7_STORE_ITEMS` no nulo), su mensaje "Inventory updated." y su mensaje de error.
4. **Tests:** paquete `test_oow_demo_store_pkg`, escrito antes que el paquete, con al menos un test por criterio.
5. **`db/code.sql`:** añadir las dos especificaciones y los dos cuerpos en su grupo.

No hace falta migración: el modelo de datos no cambia.

## 3. Interpretación de los criterios de aceptación

Los tests llaman directamente a `oow_demo_store_pkg.save_inventory`, que es lo que hace la página 7 al guardar. Como `check.sh` ejecuta los tests en un esquema vacío, cada test crea su tienda y sus productos. La "Moscone Store" de los tests reproduce la de los datos de ejemplo: 11 productos, Free range Beef con precio de tienda 20, y Dr. Bronners Liquid Soap, Macademia nuts y Rea-Dee Protein Bars con un 15 % de descuento del 11 al 16 de junio de 2011. En los datos de ejemplo Free range Beef también tiene esas fechas de oferta, sin descuento, y así se reproduce.

"Sin cambios" se comprueba comparando, antes y después de guardar, `ID`, `ITEM_ID`, `ITEM_PRICE`, `DISCOUNT_PCT`, `SALE_START_DATE`, `SALE_END_DATE` y `ROW_VERSION_NUMBER` de cada fila. Que no cambie `ROW_VERSION_NUMBER` demuestra que la fila ni siquiera se ha actualizado.

| ID | Interpretación | Test |
|---|---|---|
| RF001-CA1 | Se cambia la dirección de Moscone Store (`update` de `STORE_ADDRESS`, como hace el proceso de fila de la página) y se guarda el inventario con sus 11 productos. Los 11 siguen, con el mismo precio, descuento y fechas que antes | `ca1_address_change_keeps_prices_and_offers` |
| RF001-CA2 | Se guarda una tienda con los mismos productos. Las filas del inventario son las mismas: mismo `ID` y misma versión de fila, ni borradas ni recreadas | `ca2_same_items_keep_row_ids` |
| RF001-CA3 | Se guarda Moscone Store sin Apples. Apples desaparece del inventario y las otras 10 filas no cambian | `ca3_deselected_item_is_removed` |
| RF001-CA4 | Se guarda Moscone Store con sus 11 productos y uno nuevo. Hay una fila nueva para ese producto con precio, descuento y fechas nulos, y las 11 anteriores no cambian | `ca4_new_item_is_added_without_price` |
| RF001-CA5 | Se crea una tienda y se guarda con 3 productos. Su inventario tiene exactamente esas 3 filas, una por producto, con precio, descuento y fechas nulos | `ca5_new_store_gets_selected_items` |
| RF001-CA6 | Se aplica dos veces el mismo cambio (quitar un producto y añadir otro). Tras la segunda, el inventario es idéntico al de la primera, filas e `ID` incluidos, y ningún producto aparece dos veces. Un segundo test cubre una selección que trae el mismo producto repetido: se añade una sola vez | `ca6_same_change_twice_is_idempotent`, `ca6_repeated_item_in_selection_added_once` |

Tests adicionales de reglas del requisito que no tienen criterio propio:

| Regla | Test |
|---|---|
| RF001: si no se selecciona ningún producto, el inventario no cambia | `rf001_empty_selection_keeps_inventory` |
| CU03, flujo alternativo: si falla el guardado del inventario, no se guarda ningún cambio del inventario | `rf001_error_keeps_inventory_unchanged` |

## 4. Decisiones donde el requisito no es explícito

1. **Nombre del paquete:** `oow_demo_store_pkg`, con el prefijo del esquema y el sufijo `_pkg` como `oow_demo_gen_data_pkg` y `oow_demo_event_pkg`. Puede alojar más lógica de tiendas en el futuro.
2. **Selección vacía:** el procedimiento no hace nada si la lista es nula o vacía. Así cumple la regla "si no se selecciona ningún producto, el inventario no cambia" aunque se llame desde otro sitio. La página conserva su condición, así que el comportamiento de la app es el mismo que hoy.
3. **Productos repetidos en la selección:** se insertan una sola vez (regla de CU05: un producto no puede quedar dos veces en el inventario al guardar). Los valores nulos de la lista se ignoran.
4. **Filas sin producto** (`ITEM_ID` nulo): no son un producto que se pueda deseleccionar, así que se conservan. Hoy se borraban al guardar.
5. **Productos ya repetidos en la tienda:** el requisito excluye corregirlos. Si siguen seleccionados, se conservan todas sus filas; si se deseleccionan, se borran todas, porque el producto deja de estar en el inventario.
6. **Atomicidad:** el procedimiento no hace `commit`. Si falla, deshace sus propios cambios con un `savepoint` y vuelve a lanzar el error, para que el inventario no quede a medias aunque quien lo llame capture la excepción. En la página, APEX deshace además el guardado de la tienda y muestra el error, como pide el flujo alternativo de CU03.
7. **Orden de las operaciones:** primero se borran los deseleccionados y después se insertan los nuevos.
8. **Fuera de alcance**, aunque se vea: el botón "Delete" de la página 7 sigue fallando si la tienda tiene inventario (lo describe el análisis funcional como comportamiento actual), no se toca el cálculo de precios de ventas ni del informe de rendimiento, y no se corrigen las filas repetidas de los datos de ejemplo.

## 5. Comprobación

1. Ejecutar los tests en `wrk_dev` y verlos fallar antes de la implementación.
2. Implementar el paquete y cambiar la página 7.
3. `scripts/deploy-dev.sh` y los tests en `wrk_dev`.
4. Reproducir el caso del requisito en `wrk_dev`, llamando al paquete como lo hace la página, y deshacer.
5. `scripts/check.sh` hasta que termine con 0.
