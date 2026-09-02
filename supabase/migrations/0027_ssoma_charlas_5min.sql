-- ============================================================
-- BLOQUE 27: Evidencia de Charla de 5 Minutos
--
-- Registro con evidencia fotográfica de que la charla diaria de
-- seguridad (5 minutos SST) se dictó de verdad — distinto de
-- ssoma_encuesta_charla (bloque 9), que es la encuesta ANÓNIMA de
-- satisfacción sobre esas mismas charlas. Aquí es un log interno
-- del equipo SSOMA, mismo patrón que RACS/Comportamental: fotos
-- comprimidas en el navegador, guardadas como array jsonb de data
-- URLs (ver comentario de columna en 0005_ssoma_evidencia_fotos).
-- ============================================================

create table if not exists ssoma_charlas_5min (
  id              bigint generated always as identity primary key,

  fecha           date not null,
  responsable_id  bigint not null references ssoma_personal (id),
  tema            text not null,
  ubicacion_id    bigint not null references ssoma_ubicaciones (id),
  evidencia       jsonb not null default '[]'::jsonb,

  created_at      timestamptz not null default now(),

  constraint ssoma_charlas_5min_evidencia_check check (jsonb_typeof(evidencia) = 'array')
);

create index if not exists ssoma_charlas_5min_fecha_idx on ssoma_charlas_5min (fecha desc);
create index if not exists ssoma_charlas_5min_responsable_idx on ssoma_charlas_5min (responsable_id);

comment on table ssoma_charlas_5min is 'Evidencia fotográfica de que se dictó la charla de 5 minutos de SST — log interno, no confundir con ssoma_encuesta_charla (encuesta anónima de satisfacción).';
comment on column ssoma_charlas_5min.evidencia is 'Array jsonb de data URLs (fotos JPEG comprimidas en base64 por el navegador, hasta 3), igual que ssoma_racs_reports.evidencia.';

alter table ssoma_charlas_5min enable row level security;

create policy ssoma_charlas_5min_select on ssoma_charlas_5min for select using (true);
create policy ssoma_charlas_5min_insert on ssoma_charlas_5min for insert with check (true);
create policy ssoma_charlas_5min_update on ssoma_charlas_5min for update using (true) with check (true);
create policy ssoma_charlas_5min_delete on ssoma_charlas_5min for delete using (true);
