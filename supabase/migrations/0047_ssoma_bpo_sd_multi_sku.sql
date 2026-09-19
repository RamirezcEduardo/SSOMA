-- ============================================================
-- BLOQUE 47: LPNs multi-SKU en Bultos Perdidos/Sin Ubicación y
-- Seguimiento Diario
--
-- Un mismo bulto (Nro LPN) puede traer varios productos distintos
-- (un Cod Alternat por fila) en el reporte de origen. Hasta ahora
-- nro_lpn era único por sí solo, así que si un LPN traía 2+ filas
-- (una por cada producto) solo la primera se guardaba y el resto
-- se descartaba como "duplicado", perdiendo esos productos sin
-- avisar.
--
-- Ahora lo único es la combinación (nro_lpn, cod_alternat): el
-- mismo LPN con el mismo producto no se duplica, pero el mismo LPN
-- con un producto distinto sí se guarda como fila aparte.
-- ============================================================

alter table ssoma_bpo_registros drop constraint if exists ssoma_bpo_registros_nro_lpn_key;
alter table ssoma_bpo_registros add constraint ssoma_bpo_registros_nro_lpn_cod_alternat_key unique (nro_lpn, cod_alternat);
comment on column ssoma_bpo_registros.nro_lpn is 'Único junto con cod_alternat — un LPN multi-SKU trae varias filas (una por producto) y todas se guardan; reimportar la misma combinación LPN+producto no la duplica.';

alter table ssoma_seguimiento_diario_registros drop constraint if exists ssoma_seguimiento_diario_registros_nro_lpn_key;
alter table ssoma_seguimiento_diario_registros add constraint ssoma_seguimiento_diario_registros_nro_lpn_cod_alternat_key unique (nro_lpn, cod_alternat);
comment on column ssoma_seguimiento_diario_registros.nro_lpn is 'Único junto con cod_alternat — un LPN multi-SKU trae varias filas (una por producto) y todas se guardan; reimportar la misma combinación LPN+producto no la duplica.';
