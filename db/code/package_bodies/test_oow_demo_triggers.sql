create or replace package body test_oow_demo_triggers as

    procedure item_insert_sets_id_and_version is
        l_item oow_demo_items%rowtype;
    begin
        insert into oow_demo_items (item_type, item_name, msrp)
        values ('Food', 'Test item', 10)
        returning id, row_version_number into l_item.id, l_item.row_version_number;

        ut3.ut.expect(l_item.id).not_to_be_null();
        ut3.ut.expect(l_item.row_version_number).to_equal(1);
    end item_insert_sets_id_and_version;

    procedure item_update_increments_version is
        l_id      oow_demo_items.id%type;
        l_version oow_demo_items.row_version_number%type;
    begin
        insert into oow_demo_items (item_type, item_name, msrp)
        values ('Food', 'Test item', 10)
        returning id into l_id;

        update oow_demo_items set msrp = 12 where id = l_id
        returning row_version_number into l_version;

        ut3.ut.expect(l_version).to_equal(2);
    end item_update_increments_version;

end test_oow_demo_triggers;
/
