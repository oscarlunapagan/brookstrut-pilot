-- Vacía el esquema conectado y borra su app para desplegar desde cero. Solo funciona en WRK_CLEAN.
-- Uso: @scripts/lib/wipe-clean.sql <ID de la app>
whenever sqlerror exit failure
set serveroutput on feedback off verify off
declare
  l_left pls_integer;
begin
  if user <> 'WRK_CLEAN' then
    raise_application_error(-20001, 'Solo se vacía WRK_CLEAN, no ' || user);
  end if;
  -- La app se borra para que, si existe tras el despliegue, sea porque se ha importado ahora
  for a in (select application_id from apex_applications where application_id = &1) loop
    apex_application_install.set_workspace('WRK');
    apex_application_install.remove_application(a.application_id);
  end loop;
  -- Varias pasadas, porque borrar un objeto puede invalidar o arrastrar a otros
  for l_pass in 1 .. 3 loop
    for o in (select object_name, object_type
              from user_objects
              where object_type in ('TABLE', 'VIEW', 'MATERIALIZED VIEW', 'SEQUENCE', 'PACKAGE',
                                    'PROCEDURE', 'FUNCTION', 'TYPE', 'SYNONYM', 'TRIGGER')
                and object_name not like 'BIN$%'
              order by case object_type when 'MATERIALIZED VIEW' then 1 when 'TABLE' then 2 else 3 end) loop
      begin
        execute immediate 'drop ' || o.object_type || ' "' || o.object_name || '"'
          || case o.object_type when 'TABLE' then ' cascade constraints purge' when 'TYPE' then ' force' end;
      exception
        when others then
          -- Ya borrado al borrar otro objeto: tabla, secuencia, objeto o trigger que no existe
          if sqlcode not in (-942, -2289, -4043, -4080, -12003) then
            raise;
          end if;
      end;
    end loop;
  end loop;
  execute immediate 'purge recyclebin';
  select count(*) into l_left from user_objects where object_name not like 'BIN$%';
  if l_left > 0 then
    raise_application_error(-20002, 'Quedan ' || l_left || ' objetos en ' || user);
  end if;
end;
/
exit
