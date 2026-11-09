create or replace package oow_demo_event_pkg
as
procedure log (
    p_event_name    in varchar2,
    p_event_type    in varchar2 default null,
    p_event_detail  in varchar2 default null,
    p_error_message in varchar2 default null,
    p_error_trace   in varchar2 default null,
    p_a1            in varchar2 default null,
    p_a2            in varchar2 default null
    );
end;
/
