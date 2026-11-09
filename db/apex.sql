-- liquibase formatted sql
-- La app se reinstala en cada despliegue: su checksum no ve los cambios en apex/f100.
-- Workspace, esquema, ID y alias llegan como parámetros desde db/env/<entorno>.properties.
-- En APEXlang se fijan con las opciones de apex import: apex_application_install no cambia el esquema.
-- changeset brookstrut:apex-f100 runAlways:true stripComments:false
apex import -input apex/f100 -workspace ${apex.workspace} -schema ${apex.schema} -id ${apex.app_id} -alias ${apex.alias}
