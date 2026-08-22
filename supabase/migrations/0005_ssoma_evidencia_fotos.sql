-- ============================================================
-- BLOQUE 5: Evidencia fotográfica (corrige un desajuste con la
-- versión actual del HTML)
--
-- Los bloques 2 y 3 asumían que "evidencia" era una nota de texto
-- ("dónde se guardó la foto"). La versión actual del HTML ya no
-- hace eso: comprime hasta 3 fotos por sección a JPEG en el
-- navegador (canvas, calidad 0.65, máx 700px) y las guarda como
-- data URLs base64 en un array. Se ajusta el esquema para reflejar
-- eso: "evidencia" pasa de texto a jsonb (array de data URLs), y
-- se agrega la misma columna a comportamental (el HTML también
-- permite adjuntar fotos ahí, cosa que el bloque 3 no contemplaba).
--
-- NOTA sobre escalabilidad: guardar fotos en base64 dentro de la
-- fila es simple pero infla la tabla — cada foto comprimida puede
-- pesar 50-150 KB en base64, así que 3 fotos por reporte son
-- ~150-450 KB por fila, y loadReports() los trae TODOS de una vez
-- al listar (no solo al abrir el detalle). Con pocos reportes no
-- es problema; si el volumen crece mucho, conviene migrar a
-- Supabase Storage (guardar solo la URL del archivo, no el blob).
-- No se hace ahora para no rehacer también la parte del HTML que
-- ya funciona con data URLs.
-- ============================================================

alter table ssoma_racs_reports
  alter column evidencia type jsonb using (
    case
      when evidencia is null or evidencia = '' then '[]'::jsonb
      else jsonb_build_array(evidencia)
    end
  ),
  alter column evidencia set default '[]'::jsonb,
  alter column evidencia set not null;

alter table ssoma_levantamientos
  alter column evidencia type jsonb using (
    case
      when evidencia is null or evidencia = '' then '[]'::jsonb
      else jsonb_build_array(evidencia)
    end
  ),
  alter column evidencia set default '[]'::jsonb,
  alter column evidencia set not null;

alter table ssoma_comportamental_evaluaciones
  add column if not exists evidencia jsonb not null default '[]'::jsonb;

comment on column ssoma_racs_reports.evidencia is 'Array jsonb de data URLs (fotos JPEG comprimidas en base64 por el navegador, hasta 3). Ver nota de escalabilidad en 0005.';
comment on column ssoma_levantamientos.evidencia is 'Array jsonb de data URLs, igual que ssoma_racs_reports.evidencia.';
comment on column ssoma_comportamental_evaluaciones.evidencia is 'Array jsonb de data URLs, igual que ssoma_racs_reports.evidencia.';
