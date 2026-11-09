create or replace trigger biu_oow_demo_event_log
before insert or update on oow_demo_event_log
for each row
begin
   if :new.id is null then
       select to_number(sys_guid(),'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX') into :new.id from dual;
  end if;
  if :new.event_type is null then
     if :new.error_message is not null then
        :new.event_type := 'ERROR';
     else
        :new.event_type := 'MESSAGE';
     end if;
  end if;
  if inserting then
      :new.log_seq := oow_demo_seq.nextval;
      :new.created_on := localtimestamp;
      :new.created_by := nvl(v('APP_USER'),user);
  end if;
end;
/
