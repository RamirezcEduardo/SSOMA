-- ============================================================
-- BLOQUE 43: Inspecciones mensuales — "Líder de Vida"
--
-- Digitaliza 5 formatos oficiales (Google Drive, SSOMA-FR107 a
-- FR112) como CUESTIONARIO dentro de la app — no solo un archivo
-- subido: el Líder de Vida llena el formulario acá, queda el
-- registro en la base, y la propia app genera el documento final
-- (PDF con el mismo contenido del formato oficial) para descargar.
--
-- Cuatro comparten el mismo esqueleto — equipo por equipo, marcando
-- una leyenda de ítems A..M como Conforme/No cumple/NA:
--   FR108 ESTOCA · FR110 CUCHILLAS · FR111 ENCINTADOR · FR112 COCHES
-- El quinto (FR107) es distinto: es por trabajador, no por equipo
-- (qué EPP tiene cada uno, marcado B/M/RC/NA), así que va en su
-- propio par de tablas.
--
-- La leyenda de cada tipo de equipo (qué es A, qué es B, etc.) vive
-- en el HTML (IE_TIPOS/EPP_GRUPOS), no acá: no cambia sin tocar
-- también el formulario, así que no vale la pena una tabla aparte.
-- ============================================================

create table if not exists ssoma_insp_equipo_cabecera (
  id                    bigint generated always as identity primary key,
  codigo                text generated always as ('INSP-' || tipo || '-' || lpad(id::text, 4, '0')) stored,

  tipo                  text not null check (tipo in ('ESTOCA', 'CUCHILLAS', 'ENCINTADOR', 'COCHES')),
  cliente               text,
  area                  text,
  fecha                 date not null default current_date,

  acciones_correctivas  text,
  responsables          text,
  fecha_acciones        date,

  inspeccionado_por     text,
  inspeccionado_cargo   text,
  revisado_por          text,
  revisado_cargo        text,

  creado_por            text,
  creado_en             timestamptz not null default now()
);

comment on table ssoma_insp_equipo_cabecera is 'Cabecera de inspección mensual de equipo (ESTOCA/Cuchillas/Encintador/Coches) — formatos SSOMA-FR108/110/111/112.';
comment on column ssoma_insp_equipo_cabecera.codigo is 'Código de visualización tipo INSP-ESTOCA-0001, derivado del id (nunca se repite).';
comment on column ssoma_insp_equipo_cabecera.tipo is 'Decide qué leyenda de ítems (A, B, C…) aplica — la leyenda vive en el HTML, no acá.';

create table if not exists ssoma_insp_equipo_detalle (
  id             bigint generated always as identity primary key,
  cabecera_id    bigint not null references ssoma_insp_equipo_cabecera (id) on delete cascade,

  n_orden        int not null,
  herramienta    text,
  cantidad       int,
  resultados     jsonb not null default '{}'::jsonb,
  observaciones  text
);

comment on column ssoma_insp_equipo_detalle.resultados is 'Mapa {letra: estado}, ej. {"A":"OK","B":"NC","C":"NA"} — una entrada por cada ítem de la leyenda del tipo. OK=Conforme, NC=No cumple, NA=No aplica.';

alter table ssoma_insp_equipo_cabecera enable row level security;
alter table ssoma_insp_equipo_detalle enable row level security;

create policy ssoma_insp_equipo_cab_select on ssoma_insp_equipo_cabecera for select to anon, authenticated using (true);
create policy ssoma_insp_equipo_cab_insert on ssoma_insp_equipo_cabecera for insert to anon, authenticated with check (true);
create policy ssoma_insp_equipo_cab_update on ssoma_insp_equipo_cabecera for update to anon, authenticated using (true);

create policy ssoma_insp_equipo_det_select on ssoma_insp_equipo_detalle for select to anon, authenticated using (true);
create policy ssoma_insp_equipo_det_insert on ssoma_insp_equipo_detalle for insert to anon, authenticated with check (true);

create index if not exists idx_insp_equipo_cab_tipo on ssoma_insp_equipo_cabecera (tipo);
create index if not exists idx_insp_equipo_det_cabecera on ssoma_insp_equipo_detalle (cabecera_id);

-- ------------------------------------------------------------
-- EPP (formato SSOMA-FR107) — por trabajador, no por equipo
-- ------------------------------------------------------------

create table if not exists ssoma_insp_epp_cabecera (
  id                    bigint generated always as identity primary key,
  codigo                text generated always as ('INSP-EPP-' || lpad(id::text, 4, '0')) stored,

  cliente               text,
  area                  text,
  fecha                 date not null default current_date,
  tipo_inspeccion       text check (tipo_inspeccion in ('PLANEADA', 'NO PLANEADA')),

  acciones_correctivas  text,
  responsables          text,
  fecha_acciones        date,

  inspeccionado_por     text,
  inspeccionado_cargo   text,
  revisado_por          text,
  revisado_cargo        text,

  creado_por            text,
  creado_en             timestamptz not null default now()
);

comment on table ssoma_insp_epp_cabecera is 'Cabecera de inspección mensual de EPP por trabajador — formato SSOMA-FR107.';

create table if not exists ssoma_insp_epp_detalle (
  id             bigint generated always as identity primary key,
  cabecera_id    bigint not null references ssoma_insp_epp_cabecera (id) on delete cascade,

  n_orden        int not null,
  trabajador     text,
  cargo          text,
  resultados     jsonb not null default '{}'::jsonb,
  observaciones  text
);

comment on column ssoma_insp_epp_detalle.resultados is 'Mapa {clave: estado}, ej. {"GEN-1":"B","GEN-3":"M"} — clave = GRUPO-índice (ver EPP_GRUPOS en el HTML). B=Bueno, M=Malo, RC=Requiere cambio, NA=No aplica.';

alter table ssoma_insp_epp_cabecera enable row level security;
alter table ssoma_insp_epp_detalle enable row level security;

create policy ssoma_insp_epp_cab_select on ssoma_insp_epp_cabecera for select to anon, authenticated using (true);
create policy ssoma_insp_epp_cab_insert on ssoma_insp_epp_cabecera for insert to anon, authenticated with check (true);
create policy ssoma_insp_epp_cab_update on ssoma_insp_epp_cabecera for update to anon, authenticated using (true);

create policy ssoma_insp_epp_det_select on ssoma_insp_epp_detalle for select to anon, authenticated using (true);
create policy ssoma_insp_epp_det_insert on ssoma_insp_epp_detalle for insert to anon, authenticated with check (true);

create index if not exists idx_insp_epp_det_cabecera on ssoma_insp_epp_detalle (cabecera_id);
