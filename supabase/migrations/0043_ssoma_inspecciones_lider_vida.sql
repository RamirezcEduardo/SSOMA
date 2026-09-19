-- ============================================================
-- BLOQUE 43: Inspecciones mensuales — "Líder de Vida"
--
-- El Líder de Vida llena estos 5 formatos (SSOMA-FR107 EPP, FR108
-- ESTOCA, FR110 Cuchillas, FR111 Encintador, FR112 Coches) fuera de
-- la app — en el Excel oficial o a mano — y acá solo SUBE el
-- archivo ya llenado (PDF o Excel) como respaldo mensual. No es un
-- formulario que replica cada celda del Excel: es un repositorio
-- con metadata mínima para encontrar el archivo correcto (tipo,
-- cliente, área, mes).
--
-- El archivo se guarda como data URL base64 en la misma fila,
-- igual que la evidencia fotográfica de RACS (ver 0005): simple y
-- consistente con el resto de la app. Si el volumen crece mucho,
-- migrar a Supabase Storage (guardar solo la URL, no el blob) —
-- no hace falta ahora.
-- ============================================================

create table if not exists ssoma_insp_lider_vida (
  id                bigint generated always as identity primary key,
  codigo            text generated always as ('INSP-' || tipo || '-' || lpad(id::text, 4, '0')) stored,

  tipo              text not null check (tipo in ('EPP', 'ESTOCA', 'CUCHILLAS', 'ENCINTADOR', 'COCHES')),
  cliente           text,
  area              text,
  mes               date not null,           -- primer día del mes que corresponde la inspección
  observaciones     text,

  archivo_nombre    text not null,
  archivo_tipo      text,                    -- mime type (application/pdf, .xlsx, etc.)
  archivo_tamano    int,                     -- bytes del archivo original, para mostrar sin decodificar
  archivo_contenido text not null,           -- data URL base64 del archivo completo

  creado_por        text,
  creado_en         timestamptz not null default now()
);

comment on table ssoma_insp_lider_vida is 'Repositorio de los 5 formatos mensuales de inspección "Líder de Vida" (SSOMA-FR107/108/110/111/112) — el archivo ya llenado se sube tal cual, no se replica campo por campo.';
comment on column ssoma_insp_lider_vida.codigo is 'Código de visualización tipo INSP-ESTOCA-0001, derivado del id.';
comment on column ssoma_insp_lider_vida.mes is 'Primer día del mes que corresponde la inspección (ej. 2026-09-01 para septiembre), no la fecha de subida.';
comment on column ssoma_insp_lider_vida.archivo_contenido is 'Data URL base64 del archivo completo (PDF o Excel), igual patrón que ssoma_racs_reports.evidencia (ver 0005).';

alter table ssoma_insp_lider_vida enable row level security;

create policy ssoma_insp_lv_select on ssoma_insp_lider_vida for select to anon, authenticated using (true);
create policy ssoma_insp_lv_insert on ssoma_insp_lider_vida for insert to anon, authenticated with check (true);
create policy ssoma_insp_lv_delete on ssoma_insp_lider_vida for delete to anon, authenticated using (true);

create index if not exists idx_insp_lv_tipo on ssoma_insp_lider_vida (tipo);
create index if not exists idx_insp_lv_mes on ssoma_insp_lider_vida (mes desc);
