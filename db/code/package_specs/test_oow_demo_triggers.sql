create or replace package test_oow_demo_triggers as
    --%suite(Triggers de las tablas de Brookstrut)

    --%test(Al insertar un producto se le asigna un ID y la versión de fila 1)
    procedure item_insert_sets_id_and_version;

    --%test(Al modificar un producto su versión de fila aumenta en 1)
    procedure item_update_increments_version;
end test_oow_demo_triggers;
/
