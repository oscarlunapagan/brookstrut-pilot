create or replace package body test_oow_demo_store_pkg as

    type t_ids_by_name is table of number index by varchar2(60);

    -- Productos de la tienda de prueba, por nombre
    g_items    t_ids_by_name;
    -- Tienda de prueba
    g_store_id oow_demo_stores.id%type;

    e_parent_key_not_found exception;
    pragma exception_init(e_parent_key_not_found, -2291);

    -- Crea un producto y devuelve su ID
    function create_item (
        p_name in varchar2,
        p_type in varchar2,
        p_msrp in number
    ) return number is
        l_id oow_demo_items.id%type;
    begin
        insert into oow_demo_items (item_type, item_name, msrp)
        values (p_type, p_name, p_msrp)
        returning id into l_id;
        return l_id;
    end create_item;

    -- Crea una tienda sin inventario y devuelve su ID
    function create_store (p_name in varchar2) return number is
        l_id oow_demo_stores.id%type;
    begin
        insert into oow_demo_stores (store_name, store_type, store_address, store_city, store_state, store_zip)
        values (p_name, 'Branch', '800 Howard St', 'San Francisco', 'CA', '94103')
        returning id into l_id;
        return l_id;
    end create_store;

    -- Añade un producto al inventario de una tienda, con su precio y su oferta
    procedure add_store_product (
        p_store_id   in number,
        p_item_name  in varchar2,
        p_price      in number default null,
        p_discount   in number default null,
        p_sale_start in date default null,
        p_sale_end   in date default null
    ) is
    begin
        insert into oow_demo_store_products (store_id, item_id, item_price, discount_pct, sale_start_date, sale_end_date)
        values (p_store_id, g_items(p_item_name), p_price, p_discount, p_sale_start, p_sale_end);
    end add_store_product;

    -- Reproduce Moscone Store de los datos de ejemplo: 11 productos, Free range Beef con precio
    -- de tienda 20 y tres productos con un 15 % de descuento del 11 al 16 de junio de 2011.
    -- Crea además Tennis Racket, que la tienda no vende.
    procedure create_moscone_store is
        l_start constant date := date '2011-06-11';
        l_end   constant date := date '2011-06-16';
    begin
        g_items.delete;
        g_items('Apples')                    := create_item('Apples', 'Fruit', 3.75);
        g_items('Chocolate Covered Peanuts') := create_item('Chocolate Covered Peanuts', 'Snacks', 16.99);
        g_items('Dr. Bronners Liquid Soap')  := create_item('Dr. Bronners Liquid Soap', 'Soap', 4.99);
        g_items('Free range Beef')           := create_item('Free range Beef', 'Food', 25);
        g_items('Macademia nuts')            := create_item('Macademia nuts', 'Snacks', 9.99);
        g_items('Orange Twist Bar')          := create_item('Orange Twist Bar', 'Snacks', 1.79);
        g_items('Oranges')                   := create_item('Oranges', 'Fruit', 4.55);
        g_items('Peanut Butter Bar')         := create_item('Peanut Butter Bar', 'Snacks', 1.59);
        g_items('Rea-Dee Protein Bars')      := create_item('Rea-Dee Protein Bars', 'Snacks', 11.99);
        g_items('Super Tasty Chocolate Bar') := create_item('Super Tasty Chocolate Bar', 'Snacks', 1.99);
        g_items('Tennis Balls')              := create_item('Tennis Balls', 'Miscellaneous', 6);
        g_items('Tennis Racket')             := create_item('Tennis Racket', 'Miscellaneous', 80);

        g_store_id := create_store('Moscone Store');

        add_store_product(g_store_id, 'Apples');
        add_store_product(g_store_id, 'Chocolate Covered Peanuts');
        add_store_product(g_store_id, 'Dr. Bronners Liquid Soap', p_discount => 15, p_sale_start => l_start, p_sale_end => l_end);
        add_store_product(g_store_id, 'Free range Beef', p_price => 20, p_sale_start => l_start, p_sale_end => l_end);
        add_store_product(g_store_id, 'Macademia nuts', p_discount => 15, p_sale_start => l_start, p_sale_end => l_end);
        add_store_product(g_store_id, 'Orange Twist Bar');
        add_store_product(g_store_id, 'Oranges');
        add_store_product(g_store_id, 'Peanut Butter Bar');
        add_store_product(g_store_id, 'Rea-Dee Protein Bars', p_discount => 15, p_sale_start => l_start, p_sale_end => l_end);
        add_store_product(g_store_id, 'Super Tasty Chocolate Bar');
        add_store_product(g_store_id, 'Tennis Balls');
    end create_moscone_store;

    -- Productos seleccionados en el formulario, como los devuelve la lista de selección doble:
    -- el inventario actual de la tienda, sin p_except_item y con p_extra_item
    function selection (
        p_store_id    in number,
        p_except_item in number default null,
        p_extra_item  in number default null
    ) return varchar2 is
        l_ids apex_t_varchar2;
    begin
        select to_char(item_id)
        bulk collect into l_ids
        from oow_demo_store_products
        where store_id = p_store_id
          and (p_except_item is null or item_id <> p_except_item)
        order by item_id;

        if p_extra_item is not null then
            apex_string.push(l_ids, to_char(p_extra_item));
        end if;
        return apex_string.join(l_ids, ':');
    end selection;

    -- Inventario de la tienda en JSON, con todo lo que debe conservarse de cada fila.
    -- La versión de fila demuestra que la fila no se ha actualizado.
    function inventory (
        p_store_id    in number,
        p_except_item in number default null
    ) return clob is
        l_json clob;
    begin
        select json_arrayagg(
                   json_object(
                       'id'                 value id,
                       'item_id'            value item_id,
                       'item_price'         value item_price,
                       'discount_pct'       value discount_pct,
                       'sale_start_date'    value to_char(sale_start_date, 'YYYY-MM-DD'),
                       'sale_end_date'      value to_char(sale_end_date, 'YYYY-MM-DD'),
                       'row_version_number' value row_version_number
                       null on null)
                   order by item_id, id
                   returning clob)
        into l_json
        from oow_demo_store_products
        where store_id = p_store_id
          and (p_except_item is null or item_id <> p_except_item);
        return l_json;
    end inventory;

    function row_count (
        p_store_id in number,
        p_item_id  in number default null
    ) return number is
        l_count number;
    begin
        select count(*)
        into l_count
        from oow_demo_store_products
        where store_id = p_store_id
          and (p_item_id is null or item_id = p_item_id);
        return l_count;
    end row_count;

    function distinct_item_count (p_store_id in number) return number is
        l_count number;
    begin
        select count(distinct item_id)
        into l_count
        from oow_demo_store_products
        where store_id = p_store_id;
        return l_count;
    end distinct_item_count;

    procedure ca1_address_change_keeps_prices_and_offers is
        l_before    clob;
        l_selection varchar2(4000);
        l_beef      oow_demo_store_products%rowtype;
        l_soap      oow_demo_store_products%rowtype;
    begin
        create_moscone_store;
        l_before    := inventory(g_store_id);
        l_selection := selection(g_store_id);

        -- Lo que hace la página 7 al pulsar "Apply Changes" cambiando solo la dirección
        update oow_demo_stores set store_address = '747 Howard St' where id = g_store_id;
        oow_demo_store_pkg.save_inventory(p_store_id => g_store_id, p_item_ids => l_selection);

        ut3.ut.expect(row_count(g_store_id)).to_equal(11);
        ut3.ut.expect(inventory(g_store_id)).to_equal(l_before);

        select * into l_beef from oow_demo_store_products
        where store_id = g_store_id and item_id = g_items('Free range Beef');
        ut3.ut.expect(l_beef.item_price).to_equal(20);

        select * into l_soap from oow_demo_store_products
        where store_id = g_store_id and item_id = g_items('Dr. Bronners Liquid Soap');
        ut3.ut.expect(l_soap.discount_pct).to_equal(15);
        ut3.ut.expect(l_soap.sale_start_date).to_equal(date '2011-06-11');
        ut3.ut.expect(l_soap.sale_end_date).to_equal(date '2011-06-16');
    end ca1_address_change_keeps_prices_and_offers;

    procedure ca2_same_items_keep_row_ids is
        l_ids_before apex_t_number;
        l_ids_after  apex_t_number;
        l_before     clob;
    begin
        create_moscone_store;
        select id bulk collect into l_ids_before
        from oow_demo_store_products where store_id = g_store_id order by id;
        l_before := inventory(g_store_id);

        oow_demo_store_pkg.save_inventory(p_store_id => g_store_id, p_item_ids => selection(g_store_id));

        select id bulk collect into l_ids_after
        from oow_demo_store_products where store_id = g_store_id order by id;
        ut3.ut.expect(anydata.convertcollection(l_ids_after)).to_equal(anydata.convertcollection(l_ids_before));
        ut3.ut.expect(inventory(g_store_id)).to_equal(l_before);
    end ca2_same_items_keep_row_ids;

    procedure ca3_deselected_item_is_removed is
        l_others_before clob;
    begin
        create_moscone_store;
        l_others_before := inventory(g_store_id, p_except_item => g_items('Apples'));

        oow_demo_store_pkg.save_inventory(
            p_store_id => g_store_id,
            p_item_ids => selection(g_store_id, p_except_item => g_items('Apples')));

        ut3.ut.expect(row_count(g_store_id, g_items('Apples'))).to_equal(0);
        ut3.ut.expect(row_count(g_store_id)).to_equal(10);
        ut3.ut.expect(inventory(g_store_id)).to_equal(l_others_before);
    end ca3_deselected_item_is_removed;

    procedure ca4_new_item_is_added_without_price is
        l_before clob;
        l_new    oow_demo_store_products%rowtype;
    begin
        create_moscone_store;
        l_before := inventory(g_store_id);

        oow_demo_store_pkg.save_inventory(
            p_store_id => g_store_id,
            p_item_ids => selection(g_store_id, p_extra_item => g_items('Tennis Racket')));

        ut3.ut.expect(row_count(g_store_id)).to_equal(12);
        ut3.ut.expect(inventory(g_store_id, p_except_item => g_items('Tennis Racket'))).to_equal(l_before);

        select * into l_new from oow_demo_store_products
        where store_id = g_store_id and item_id = g_items('Tennis Racket');
        ut3.ut.expect(l_new.item_price).to_be_null();
        ut3.ut.expect(l_new.discount_pct).to_be_null();
        ut3.ut.expect(l_new.sale_start_date).to_be_null();
        ut3.ut.expect(l_new.sale_end_date).to_be_null();
    end ca4_new_item_is_added_without_price;

    procedure ca5_new_store_gets_selected_items is
        l_store_id   number;
        l_selected   apex_t_number;
        l_expected   apex_t_number;
        l_inventory  apex_t_number;
        l_with_price number;
    begin
        create_moscone_store;
        -- Lo que hace la página 7 al pulsar "Add Store": crea la tienda y después guarda su inventario
        l_store_id := create_store('New Store');
        l_selected := apex_t_number(g_items('Apples'), g_items('Oranges'), g_items('Tennis Balls'));

        oow_demo_store_pkg.save_inventory(
            p_store_id => l_store_id,
            p_item_ids => apex_string.join(l_selected, ':'));

        select item_id bulk collect into l_inventory
        from oow_demo_store_products where store_id = l_store_id order by item_id;
        select column_value bulk collect into l_expected
        from table(l_selected) order by column_value;
        ut3.ut.expect(anydata.convertcollection(l_inventory)).to_equal(anydata.convertcollection(l_expected));

        select count(*) into l_with_price
        from oow_demo_store_products
        where store_id = l_store_id
          and (item_price is not null or discount_pct is not null
               or sale_start_date is not null or sale_end_date is not null);
        ut3.ut.expect(l_with_price).to_equal(0);
    end ca5_new_store_gets_selected_items;

    procedure ca6_same_change_twice_is_idempotent is
        l_selection   varchar2(4000);
        l_after_first clob;
    begin
        create_moscone_store;
        -- El cambio: quitar Apples y añadir Tennis Racket
        l_selection := selection(g_store_id, p_except_item => g_items('Apples'), p_extra_item => g_items('Tennis Racket'));

        oow_demo_store_pkg.save_inventory(p_store_id => g_store_id, p_item_ids => l_selection);
        l_after_first := inventory(g_store_id);
        oow_demo_store_pkg.save_inventory(p_store_id => g_store_id, p_item_ids => l_selection);

        ut3.ut.expect(inventory(g_store_id)).to_equal(l_after_first);
        ut3.ut.expect(row_count(g_store_id)).to_equal(11);
        ut3.ut.expect(distinct_item_count(g_store_id)).to_equal(row_count(g_store_id));
    end ca6_same_change_twice_is_idempotent;

    procedure ca6_repeated_item_in_selection_added_once is
    begin
        create_moscone_store;

        oow_demo_store_pkg.save_inventory(
            p_store_id => g_store_id,
            p_item_ids => selection(g_store_id) || ':' || g_items('Tennis Racket') || ':' || g_items('Tennis Racket')
                          || ':' || g_items('Apples'));

        ut3.ut.expect(row_count(g_store_id, g_items('Tennis Racket'))).to_equal(1);
        ut3.ut.expect(row_count(g_store_id, g_items('Apples'))).to_equal(1);
        ut3.ut.expect(row_count(g_store_id)).to_equal(12);
    end ca6_repeated_item_in_selection_added_once;

    procedure rf001_empty_selection_keeps_inventory is
        l_before    clob;
        l_no_items  varchar2(4000);
    begin
        create_moscone_store;
        l_before := inventory(g_store_id);

        oow_demo_store_pkg.save_inventory(p_store_id => g_store_id, p_item_ids => l_no_items);
        oow_demo_store_pkg.save_inventory(p_store_id => g_store_id, p_item_ids => apex_t_number());
        oow_demo_store_pkg.save_inventory(p_store_id => g_store_id, p_item_ids => apex_t_number(null));

        ut3.ut.expect(inventory(g_store_id)).to_equal(l_before);
    end rf001_empty_selection_keeps_inventory;

    procedure rf001_error_keeps_inventory_unchanged is
        l_before  clob;
        l_failed  boolean := false;
    begin
        create_moscone_store;
        l_before := inventory(g_store_id);

        -- Quita Apples y añade un producto que no existe: la inserción falla por la clave ajena
        begin
            oow_demo_store_pkg.save_inventory(
                p_store_id => g_store_id,
                p_item_ids => selection(g_store_id, p_except_item => g_items('Apples'), p_extra_item => -1));
        exception
            when e_parent_key_not_found then
                l_failed := true;
        end;

        ut3.ut.expect(l_failed).to_be_true();
        ut3.ut.expect(inventory(g_store_id)).to_equal(l_before);
    end rf001_error_keeps_inventory_unchanged;

end test_oow_demo_store_pkg;
/
