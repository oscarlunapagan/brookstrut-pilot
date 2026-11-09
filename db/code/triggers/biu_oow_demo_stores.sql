create or replace trigger biu_oow_demo_stores
BEFORE INSERT OR UPDATE ON OOW_DEMO_STORES
FOR EACH ROW
BEGIN
   if :new.ID is null then
     select to_number(sys_guid(),'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX') into :new.id from dual;
   end if;
   if inserting then
       :new.row_version_number := 1;
   elsif updating then
       :new.row_version_number := nvl(:old.row_version_number,1) + 1;
   end if;
   if :new.n1 is null then
     :new.n1 := round(dbms_random.value(1,1000000));
   end if;
   if :new.n2 is null then
     :new.n2 := round(dbms_random.value(1,1000000));
   end if;
   if :new.n3 is null then
     :new.n3 := round(dbms_random.value(1,1000000));
   end if;
   if :new.n4 is null then
     :new.n4 := round(dbms_random.value(1,1000000));
   end if;
END;
/
