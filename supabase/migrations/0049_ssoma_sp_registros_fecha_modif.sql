-- ============================================================
-- BLOQUE 49: Shortpick — guardar Fe y Hr Modif
--
-- Hasta ahora solo se guardaba la fecha de creación del pedido ("Fe y
-- Hr Crea", columna fecha) — la fecha de modificación ("Fe y Hr
-- Modif") solo se usaba de paso para calcular el turno cuando el
-- archivo no lo traía, pero nunca se persistía. Se necesita mostrarla
-- en las tarjetas de Conciliación para diferenciar pedidos que se ven
-- idénticos (mismo producto, misma ubicación) pero corresponden a
-- movimientos distintos del WMS.
-- ============================================================

alter table ssoma_sp_registros add column if not exists fecha_modif timestamptz;

comment on column ssoma_sp_registros.fecha_modif is 'Columna "Fe y Hr Modif" del export del WMS — último movimiento del pedido en el WMS, distinto de "fecha" (Fe y Hr Crea). Null en registros cargados antes de este cambio.';
