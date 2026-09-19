-- ============================================================
-- BLOQUE 54: Seguimiento Diario — la unicidad de un LPN pasa a ser
-- por semana, no para siempre
--
-- La combinación (nro_lpn, cod_alternat) era única en toda la tabla,
-- sin importar la semana. En la práctica un mismo bulto (CJ) puede
-- cambiar de Proceso y Ubicación de una semana a otra (ej. pasa de
-- Abastecimiento/DROP-RECEP-CARTONIZ a Drop/DROP-RECEP-PN-CJ en la
-- semana siguiente) — con la restricción vieja, si ese LPN+Cod
-- Alternat ya existía de una semana anterior (pendiente, finalizado o
-- regularizado), el import o el agregado manual de la semana nueva se
-- descartaba en silencio como "duplicado" y la nueva aparición nunca
-- quedaba registrada.
--
-- Ahora la unicidad es (nro_lpn, cod_alternat, semana): reimportar el
-- mismo archivo de la misma semana sigue sin duplicar nada, pero el
-- mismo LPN puede volver a aparecer como un pendiente nuevo en una
-- semana distinta.
-- ============================================================

alter table ssoma_seguimiento_diario_registros
  drop constraint if exists ssoma_seguimiento_diario_registros_nro_lpn_cod_alternat_key;
alter table ssoma_seguimiento_diario_registros
  add constraint ssoma_seguimiento_diario_registros_nro_lpn_cod_alt_sem_key unique (nro_lpn, cod_alternat, semana);

comment on column ssoma_seguimiento_diario_registros.nro_lpn is 'Único junto con cod_alternat y semana — un LPN multi-SKU trae varias filas (una por producto) y todas se guardan; reimportar la misma combinación LPN+producto+semana no la duplica, pero si el mismo LPN reaparece en una semana distinta (aunque haya cambiado de Proceso/Ubicación) sí se guarda como un pendiente nuevo.';
