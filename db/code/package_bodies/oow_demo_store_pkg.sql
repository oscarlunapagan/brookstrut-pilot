create or replace package body oow_demo_store_pkg as

    procedure save_inventory (
        p_store_id in oow_demo_stores.id%type,
        p_item_ids in apex_t_number
    ) is
        l_item_ids apex_t_number;
    begin
        -- Productos seleccionados, sin nulos ni repetidos
        if p_item_ids is not null then
            select distinct s.column_value
            bulk collect into l_item_ids
            from table(p_item_ids) s
            where s.column_value is not null;
        end if;

        -- Sin productos seleccionados, el inventario no cambia
        if l_item_ids is null or l_item_ids.count = 0 then
            return;
        end if;

        savepoint save_inventory;

        -- Quita los productos deseleccionados. Si un producto está repetido en la tienda,
        -- se quitan todas sus filas
        delete from oow_demo_store_products sp
        where sp.store_id = p_store_id
          and sp.item_id not in (select s.column_value from table(l_item_ids) s);

        -- Añade los productos nuevos sin precio de tienda ni oferta. Los que ya estaban no se tocan
        insert into oow_demo_store_products (store_id, item_id)
        select p_store_id, s.column_value
        from table(l_item_ids) s
        where not exists (select null
                          from oow_demo_store_products sp
                          where sp.store_id = p_store_id
                            and sp.item_id = s.column_value);
    exception
        when others then
            -- No deja el inventario a medias: deshace lo hecho aquí y propaga el error
            rollback to save_inventory;
            raise;
    end save_inventory;

    procedure save_inventory (
        p_store_id in oow_demo_stores.id%type,
        p_item_ids in varchar2
    ) is
    begin
        save_inventory(
            p_store_id => p_store_id,
            p_item_ids => apex_string.split_numbers(p_item_ids, ':'));
    end save_inventory;

end oow_demo_store_pkg;
/
