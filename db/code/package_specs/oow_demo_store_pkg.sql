create or replace package oow_demo_store_pkg as
    -- Lógica de las tiendas (CU03 y CU05)

    -- Actualiza el inventario de una tienda con los productos seleccionados (RF001):
    -- conserva sin modificar los que ya tenía, quita los que no están en la selección
    -- y añade los nuevos sin precio de tienda ni oferta.
    -- Si la selección es nula o vacía, el inventario no cambia. No hace commit: si falla,
    -- deshace sus cambios y vuelve a lanzar el error.
    procedure save_inventory (
        p_store_id in oow_demo_stores.id%type,
        p_item_ids in apex_t_number
    );

    -- Igual que la anterior, con los productos en una cadena separada por ':',
    -- como la devuelve la lista de selección doble de la página 7
    procedure save_inventory (
        p_store_id in oow_demo_stores.id%type,
        p_item_ids in varchar2
    );
end oow_demo_store_pkg;
/
