-- ============================================================
-- BLOQUE 50: Seguimiento Diario — riesgo de cobro y regularización automática
--
-- 1) en_riesgo: el equipo marca a mano (botón 🚩 en la tarjeta del grupo)
--    los casos que corren riesgo real de que LATAM los cobre, aunque su
--    proceso no sea Perdido ERU/Por Ubicar/Sin Ubicación. Su valorizado
--    se suma al indicador "En riesgo" del Informe Semanal.
--
-- 2) estado gana un tercer valor, "regularizado_auto": cuando un import
--    posterior detecta que un LPN pendiente ya no aparece en su mismo
--    Proceso+Ubicación (el auditor actualiza el reporte a diario y puede
--    quitar LPN que ya se resolvieron fuera de la app), se marca así en
--    vez de "finalizado" — no se borra, y queda claro que nadie del
--    equipo lo cerró a mano. Cuenta como resuelto (ya no pendiente) para
--    el % de avance, la Bitácora y el indicador "Regularizado".
-- ============================================================

alter table ssoma_seguimiento_diario_registros drop constraint if exists ssoma_seguimiento_diario_registros_estado_check;
alter table ssoma_seguimiento_diario_registros add constraint ssoma_seguimiento_diario_registros_estado_check
  check (estado in ('pendiente', 'finalizado', 'regularizado_auto'));

alter table ssoma_seguimiento_diario_registros add column if not exists en_riesgo boolean not null default false;
alter table ssoma_seguimiento_diario_registros add column if not exists regularizado_en timestamptz;

comment on column ssoma_seguimiento_diario_registros.estado is 'pendiente hasta que el equipo lo finaliza a mano, o hasta que un import posterior detecta que el LPN ya no aparece en su Proceso+Ubicación (regularizado_auto).';
comment on column ssoma_seguimiento_diario_registros.en_riesgo is 'Marcado a mano por el equipo cuando el caso corre riesgo real de que LATAM lo cobre — se suma al indicador "En riesgo" del Informe Semanal junto con Bultos Perdidos/Sin Ubicación.';
comment on column ssoma_seguimiento_diario_registros.regularizado_en is 'Cuándo se detectó automáticamente que el LPN ya no aparecía en el archivo del día — null si se finalizó a mano (ver finalizado_en).';
