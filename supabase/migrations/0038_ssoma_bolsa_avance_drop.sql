-- Revierte la migración 0037: se eliminó el módulo "Avance de Bolsa" por pedido de Eduardo.
drop table if exists ssoma_bolsa_avance_lineas;

delete from ssoma_importaciones_log where modulo = 'bolsa_avance';

alter table ssoma_importaciones_log drop constraint if exists ssoma_importaciones_log_modulo_check;
alter table ssoma_importaciones_log add constraint ssoma_importaciones_log_modulo_check
  check (modulo in ('shortpick', 'sin_ubicacion', 'bolsa_auditoria', 'bolsa_wms'));
