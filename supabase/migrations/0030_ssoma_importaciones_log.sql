-- ============================================================
-- BLOQUE 30: Registro de archivos importados — evita reimportar el mismo
-- archivo por error y duplicar todo su contenido.
--
-- Se necesitó tras encontrar 1604 registros duplicados en Short Pick:
-- el mismo archivo "Ajustes de inventario" se subió dos veces (2 días
-- de diferencia) y, como ese import no tiene forma de deduplicar por
-- fila (no hay Nro LPN ni ningún ID propio del WMS en esa hoja), el
-- segundo import insertó una copia exacta de cada fila. Bultos Perdidos
-- no lo necesita: ya deduplica por Nro LPN al importar.
-- ============================================================

create table if not exists ssoma_importaciones_log (
  id                bigint generated always as identity primary key,
  modulo            text not null check (modulo in ('shortpick', 'sin_ubicacion')),
  archivo_nombre    text not null,
  archivo_hash      text not null,
  filas             integer not null,
  importado_por_id  bigint references ssoma_personal (id),
  importado_en      timestamptz not null default now(),

  unique (modulo, archivo_hash)
);

comment on table ssoma_importaciones_log is 'Huella (SHA-256) de cada archivo importado en Shortpick/Sin Ubicación — antes de importar se avisa si ese mismo archivo ya se cargó, para no duplicar todo su contenido.';

alter table ssoma_importaciones_log enable row level security;

create policy ssoma_importaciones_log_select on ssoma_importaciones_log for select using (true);
create policy ssoma_importaciones_log_insert on ssoma_importaciones_log for insert with check (true);
