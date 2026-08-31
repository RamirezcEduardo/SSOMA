-- ============================================================
-- BLOQUE 26: Auditoría Bultos Perdidos — flujo real de 2 archivos
--
-- Corrige el flujo original (import único filtrado a "Perdido ERU"):
-- ahora la fuente es DATA_LATAM (bruto), filtrado por Ubicación
-- (whitelist de zonas DROP-*/CONTROL-INVENTARIO-01-01) o Proceso
-- ("Sin Ubicacion"/"Por ubicar"), y la conciliación es automática
-- cruzando Nro LPN contra el export de cajas del WMS (Estado
-- Ubicado/Cancelado = conciliado, Perdido = sigue pendiente).
--
-- Columnas nuevas: ubicacion/proceso/estado_latam (tal como venían
-- en DATA_LATAM, para trazabilidad) y categoria (distingue los casos
-- de CONTROL-INVENTARIO-01-01 vinculados a Reinyectado, que quedan
-- pendientes pero catalogados como consulta al área de Reinyectado
-- en vez de un pendiente normal).
-- ============================================================

alter table ssoma_bp_registros add column if not exists ubicacion text;
alter table ssoma_bp_registros add column if not exists proceso text;
alter table ssoma_bp_registros add column if not exists estado_latam text;
alter table ssoma_bp_registros add column if not exists categoria text not null default 'normal';

comment on column ssoma_bp_registros.ubicacion is 'Columna "Ubicacion" de DATA_LATAM al momento de importar (una de la whitelist DROP-*/CONTROL-INVENTARIO-01-01, o vacía si entró por Proceso=Sin Ubicación/Por ubicar).';
comment on column ssoma_bp_registros.proceso is 'Columna "Proceso" de DATA_LATAM (ej. "Perdido ERU", "Sin Ubicacion", "Por ubicar").';
comment on column ssoma_bp_registros.estado_latam is 'Columna "Estado" de DATA_LATAM al momento de importar — solo referencia; la conciliación real usa el Estado del export de cajas del WMS (segundo archivo), no este valor.';
comment on column ssoma_bp_registros.categoria is 'normal | consulta_reinyectado. CONTROL-INVENTARIO-01-01 vinculado a Reinyectado queda pendiente pero catalogado como consulta al área de Reinyectado en vez de un pendiente normal.';

comment on table ssoma_bp_registros is 'Casos candidatos a "Perdido" filtrados de DATA_LATAM: Ubicación en la whitelist de zonas DROP-*/CONTROL-INVENTARIO-01-01, o Proceso = Sin Ubicación/Por ubicar (sin importar la ubicación). Se concilian cruzando Nro LPN contra el export de cajas del WMS.';
comment on table ssoma_bp_verificaciones is 'Conciliación de cada caso — automática por el cruce con el export de cajas del WMS (Estado Ubicado/Cancelado) o manual (sustento a mano). Un registro sin fila aquí sigue pendiente.';
