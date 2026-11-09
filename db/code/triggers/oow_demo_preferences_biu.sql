create or replace trigger oow_demo_preferences_biu
before insert or update on oow_demo_preferences
    for each row
begin
    if inserting and :new.id is null then
       select to_number(sys_guid(),'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX') into :new.id from dual;
    end if;
    if inserting then
        :new.created_by := nvl(v('APP_USER'),USER);
        :new.created_on := localtimestamp;
    end if;
    if updating then
        :new.updated_by := nvl(v('APP_USER'),USER);
        :new.updated_on := localtimestamp;
    end if;
    :new.preference_name := upper(:new.preference_name);
end;
/
