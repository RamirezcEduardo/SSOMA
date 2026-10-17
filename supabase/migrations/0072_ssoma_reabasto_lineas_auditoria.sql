-- ============================================================
-- BLOQUE 72: Auditoría de Abastecimientos — reporte por ubicación
--
-- Pantalla nueva (mobile-first, agrupada por Área = prefijo de Ubic
-- destino, calculado en el cliente) donde el kardista valida, línea
-- por línea de ssoma_reabasto_lineas, si lo que encontró coincide con
-- lo que el sistema asignó. Se guarda directo en la misma tabla (no
-- hace falta una tabla aparte: es 1 reporte por línea, no un
-- historial de varios reportes sobre la misma línea).
-- ============================================================

alter table ssoma_reabasto_lineas add column if not exists resultado_auditoria text
  check (resultado_auditoria in ('coincide', 'de_mas', 'de_menos'));
alter table ssoma_reabasto_lineas add column if not exists cantidad_real numeric;
alter table ssoma_reabasto_lineas add column if not exists auditado_en timestamptz;
alter table ssoma_reabasto_lineas add column if not exists auditado_por_id bigint;

comment on column ssoma_reabasto_lineas.resultado_auditoria is 'Resultado de la Auditoría de Abastecimientos para esta línea: coincide con cantidad_asignada, o de_mas/de_menos con la cantidad real en cantidad_real. Null = todavía no auditada.';
comment on column ssoma_reabasto_lineas.cantidad_real is 'Cantidad total REAL encontrada en esa ubicación (no la diferencia) — solo se llena cuando resultado_auditoria es de_mas o de_menos.';
