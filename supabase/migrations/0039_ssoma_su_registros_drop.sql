-- Se retira el módulo "Auditoría Sin Ubicación" (tablas ya vacías) — Eduardo va a
-- rediseñar el flujo desde cero y pidió borrar lo anterior para no reescribir dos veces.
drop table if exists ssoma_su_verificaciones;
drop table if exists ssoma_su_registros;

delete from ssoma_importaciones_log where modulo = 'sin_ubicacion';

alter table ssoma_importaciones_log drop constraint if exists ssoma_importaciones_log_modulo_check;
alter table ssoma_importaciones_log add constraint ssoma_importaciones_log_modulo_check
  check (modulo in ('shortpick', 'bolsa_auditoria', 'bolsa_wms'));
