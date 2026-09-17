-- ============================================================
-- BLOQUE 59: Programación de Contenedores — recepción por el operador
--
-- La vista interna (Inbound → Programación de Contenedores) le muestra
-- al operador lo que COMEX programó (bloque 58) agrupado por día, y le
-- deja marcar si recibió la totalidad programada o fue parcial —mismo
-- patrón que la Conciliación de Shortpick (bloque de "¿Encontró la
-- totalidad?" Sí/No + cantidad), incluyendo que la cantidad recibida
-- NO tiene tope: puede llegar más de lo programado sin que se bloquee.
-- ============================================================

alter table ssoma_inbound_programacion_contenedores add column if not exists cantidad_recibida numeric;

alter table ssoma_inbound_programacion_contenedores drop constraint if exists ssoma_inbound_programacion_contenedores_estado_check;
alter table ssoma_inbound_programacion_contenedores add constraint ssoma_inbound_programacion_contenedores_estado_check
  check (estado in ('pendiente', 'parcial', 'recibido'));

comment on column ssoma_inbound_programacion_contenedores.cantidad_recibida is 'Cantidad realmente recibida (contenedores o pallets, según tipo_carga) — puede ser mayor, menor o igual a "cantidad" (lo programado). Null mientras esté pendiente.';
comment on column ssoma_inbound_programacion_contenedores.estado is 'pendiente hasta que el operador lo marca: recibido (cantidad_recibida >= cantidad) o parcial (cantidad_recibida < cantidad).';
