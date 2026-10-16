-- "Subir desde WMS" en Bultos Perdidos (export de LPN por Estado = "Perdido")
-- registra el archivo importado en ssoma_importaciones_log bajo el módulo
-- 'bultos_perdidos_wms' — para el aviso de "este archivo ya se cargó". Ese
-- valor no estaba permitido por el CHECK de la columna, así que el insert del
-- log fallaba en silencio (el import en sí funcionaba, pero nunca quedaba
-- registrado el archivo). Se amplía la lista, igual que en 0045/0046/0055.
alter table ssoma_importaciones_log drop constraint if exists ssoma_importaciones_log_modulo_check;
alter table ssoma_importaciones_log add constraint ssoma_importaciones_log_modulo_check
  check (modulo in ('shortpick', 'bolsa_auditoria', 'bolsa_wms', 'bultos_pendientes_operacion', 'sin_ubicacion_wms', 'seguimiento_diario', 'inbound_solicitudes_ot', 'bultos_perdidos_wms'));
