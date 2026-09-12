-- ============================================================
-- BLOQUE 42: Bultos Pendientes de Operación — dedup real por Nro LPN
--
-- Corrige el comportamiento de 0041: ya NO se hace upsert (que
-- actualizaba/reseteaba a pendiente un LPN ya cargado). Ahora un
-- Nro LPN que ya existe en la tabla se detecta como duplicado y NO
-- se vuelve a insertar ni se pisa su estado — solo se cuenta en el
-- mensaje de import. Solo actualiza los comentarios para que
-- reflejen el comportamiento real (la tabla/constraint no cambian).
-- ============================================================

comment on table ssoma_bpo_registros is 'Bultos Pendientes de Operación: filas de la hoja "Bultos Pendientes" (reporte "Pendientes de Operación") con Proceso en Perdido ERU/Por Ubicar/Sin Ubicación. clasificacion agrupa Perdido ERU+Por Ubicar como "perdidos" y Sin Ubicación aparte.';
comment on column ssoma_bpo_registros.nro_lpn is 'Único por bulto — si el LPN ya está cargado, el import lo detecta como duplicado y NO lo vuelve a insertar (no se pisa el registro existente).';
