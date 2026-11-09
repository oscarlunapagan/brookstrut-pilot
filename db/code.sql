-- liquibase formatted sql
-- Todo el código se recompila en cada despliegue. Debe listar todos los archivos de db/code/:
-- uno que falte no se despliega y no da error. Orden: especificaciones, cuerpos y triggers.
-- changeset brookstrut:code runAlways:true stripComments:false
@db/code/package_specs/oow_demo_event_pkg.sql
@db/code/package_specs/oow_demo_gen_data_pkg.sql
@db/code/package_specs/oow_demo_sample_data.sql
@db/code/package_specs/oow_demo_timing.sql
@db/code/package_specs/test_oow_demo_triggers.sql
@db/code/package_bodies/oow_demo_event_pkg.sql
@db/code/package_bodies/oow_demo_gen_data_pkg.sql
@db/code/package_bodies/oow_demo_sample_data.sql
@db/code/package_bodies/oow_demo_timing.sql
@db/code/package_bodies/test_oow_demo_triggers.sql
@db/code/triggers/bi_oow_demo_hist_gen_log.sql
@db/code/triggers/biu_oow_demo_event_log.sql
@db/code/triggers/biu_oow_demo_items.sql
@db/code/triggers/biu_oow_demo_regions.sql
@db/code/triggers/biu_oow_demo_sales_hist.sql
@db/code/triggers/biu_oow_demo_store_products.sql
@db/code/triggers/biu_oow_demo_stores.sql
@db/code/triggers/oow_demo_preferences_biu.sql
