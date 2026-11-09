create or replace trigger bi_oow_demo_hist_gen_log
    before insert or update on oow_demo_hist_gen_log
for each row
declare
    l_cnt number := null;
begin
    if :new.id is null then
        select to_number(sys_guid(),'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX') into :new.id from dual;
    end if;

    :new.owner := nvl(apex_application.g_user,user);
    :new.APP_SESSION_ID := v('APP_SESSION');

    --if inserting then
    --    select count(*) into l_cnt from oow_demo_hist_gen_log where start_time is not null and end_time is null;
    --    if l_cnt > 0 then
    --        raise_application_error(-20222,'Sales history generation already in progress.');
    --    end if;
    --end if;
end;
/
