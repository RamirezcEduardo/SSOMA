-- BLOQUE 45: nuevo import directo desde WMS para "Sin Ubicación" (Auditoría de
-- Inventario) — alterno al reporte del auditor, para cuando el equipo no quiere
-- esperar a que llegue "Pendientes de Operación". Solo agrega el módulo al check
-- de ssoma_importaciones_log para el aviso de "archivo ya cargado".
alter table ssoma_importaciones_log drop constraint if exists ssoma_importaciones_log_modulo_check;
alter table ssoma_importaciones_log add constraint ssoma_importaciones_log_modulo_check
  check (modulo in ('shortpick', 'bolsa_auditoria', 'bolsa_wms', 'bultos_pendientes_operacion', 'sin_ubicacion_wms'));
