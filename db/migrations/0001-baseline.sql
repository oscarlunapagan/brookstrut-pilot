-- liquibase formatted sql
-- Esquema de Brookstrut tal como lo instala la galería de APEX 26.1, sin datos.
-- Las claves las asignan los triggers de db/code/triggers.
-- changeset brookstrut:0001-baseline
create sequence oow_demo_seq;

create table oow_demo_regions (
    id                 number constraint oow_demo_regions_pk primary key,
    row_version_number number,
    region_name        varchar2(255),
    region_zoom        varchar2(50),
    region_lat         number(9,6),
    region_lng         number(9,6),
    region_color       varchar2(7),
    is_default_yn      varchar2(1)
);

create table oow_demo_stores (
    id                 number constraint oow_demo_stores_pk primary key,
    row_version_number number,
    store_name         varchar2(255),
    store_type         varchar2(50),
    store_address      varchar2(255),
    store_open_date    timestamp with local time zone,
    store_city         varchar2(50),
    store_state        varchar2(50),
    region_id          number,
    store_zip          varchar2(12),
    store_lat          number(9,6),
    store_lng          number(9,6),
    n1                 number,
    n2                 number,
    n3                 number,
    n4                 number
);

create table oow_demo_items (
    id                 number constraint oow_demo_items_pk primary key,
    row_version_number number,
    item_type          varchar2(255) not null,
    item_name          varchar2(60) not null,
    item_desc          varchar2(255),
    msrp               number default 1 not null
);

create table oow_demo_store_products (
    id                 number constraint oow_demo_store_products_pk primary key,
    row_version_number number,
    store_id           number constraint oow_demo_store_products_fk2 references oow_demo_stores (id),
    item_id            number constraint oow_demo_store_products_fk1 references oow_demo_items (id),
    sale_start_date    date,
    discount_pct       number,
    sale_end_date      date,
    item_price         number
);

create index oow_demo_store_products_i1 on oow_demo_store_products (store_id);

create index oow_demo_store_products_i2 on oow_demo_store_products (item_id);

create table oow_demo_sales_history (
    id                 number constraint oow_demo_sales_history_pk primary key,
    store_id           number not null constraint oow_demo_sales_history_fk1 references oow_demo_stores (id),
    product_id         number not null constraint oow_demo_sales_history_fk2 references oow_demo_items (id),
    date_of_sale       timestamp with local time zone,
    quantity           number default 1,
    transaction_id     varchar2(30),
    item_price         number,
    created_on         timestamp with local time zone,
    sales_data         varchar2(4000)
);

create index oow_demo_sales_history_i1 on oow_demo_sales_history (store_id);

create index oow_demo_sales_history_i2 on oow_demo_sales_history (product_id);

create table oow_demo_event_log (
    id                 number constraint oow_demo_event_log_pk primary key,
    log_seq            number not null,
    event_type         varchar2(255) not null
                       constraint oow_demo_event_event_type_ck check (event_type in ('MESSAGE', 'WARNING', 'ERROR')),
    event_name         varchar2(255),
    event_detail       varchar2(4000),
    error_message      varchar2(4000),
    error_trace        clob,
    created_by         varchar2(255),
    created_on         timestamp with local time zone,
    a1                 varchar2(4000),
    a2                 varchar2(4000)
);

create table oow_demo_hist_gen_log (
    id                 number constraint oow_demo_hist_gen_log_pk primary key,
    app_session_id     varchar2(255),
    owner              varchar2(255) not null,
    num_days           number,
    max_orders         number,
    start_time         timestamp with local time zone,
    end_time           timestamp with local time zone,
    row_count          number
);

create table oow_demo_preferences (
    id                 number not null constraint oow_demo_preferences_pk primary key,
    preference_name    varchar2(255) not null
                       constraint oow_demo_prefs_prefname_ck check (upper(preference_name) = preference_name),
    preference_value   varchar2(255) not null,
    created_by         varchar2(255) not null,
    created_on         timestamp with local time zone,
    updated_by         varchar2(255),
    updated_on         timestamp with local time zone
);

create unique index oow_demo_preferences_uk on oow_demo_preferences (preference_name);
