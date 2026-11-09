create or replace package test_oow_demo_store_pkg as
    --%suite(Inventario de la tienda al guardar el formulario (EV-001))

    --%test(RF001-CA1: conserva los 11 productos con su precio, descuento y fechas al cambiar solo la dirección)
    procedure ca1_address_change_keeps_prices_and_offers;

    --%test(RF001-CA2: guardar con los mismos productos no borra ni recrea filas, cada fila conserva su ID)
    procedure ca2_same_items_keep_row_ids;

    --%test(RF001-CA3: deseleccionar Apples lo quita y conserva sin cambios los otros 10 productos)
    procedure ca3_deselected_item_is_removed;

    --%test(RF001-CA4: un producto nuevo se añade sin precio ni oferta y los 11 anteriores no cambian)
    procedure ca4_new_item_is_added_without_price;

    --%test(RF001-CA5: una tienda nueva con 3 productos tiene exactamente esos 3, sin precio ni oferta)
    procedure ca5_new_store_gets_selected_items;

    --%test(RF001-CA6: aplicar dos veces el mismo cambio deja el mismo inventario, sin productos repetidos)
    procedure ca6_same_change_twice_is_idempotent;

    --%test(RF001-CA6: un producto repetido en la selección se añade una sola vez)
    procedure ca6_repeated_item_in_selection_added_once;

    --%test(RF001: si no se selecciona ningún producto, el inventario no cambia)
    procedure rf001_empty_selection_keeps_inventory;

    --%test(RF001: si falla el guardado, el inventario queda como estaba)
    procedure rf001_error_keeps_inventory_unchanged;
end test_oow_demo_store_pkg;
/
