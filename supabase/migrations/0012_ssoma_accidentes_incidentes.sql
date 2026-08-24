-- ============================================================
-- BLOQUE 12: Reportes de Accidentes / Incidentes
--
-- Reemplaza el informe en PDF/Excel que arma SSOMA a mano.
-- Sigue el método de investigación de causas ya usado por el
-- equipo: causa inmediata (acto/condición subestándar) -> causas
-- básicas (factores personales / laborales) -> plan de acciones.
--
-- Decisiones de diseño (confirmadas con el usuario):
-- - "Causa inmediata" reutiliza el mismo catálogo que RACS
--   (ssoma_ocurrencias / ssoma_condiciones) en vez de uno nuevo,
--   por eso usa el tipo ssoma_tipo_hallazgo ya existente.
-- - "Factores personales" y "Factores laborales" no tienen
--   catálogo: se escriben libres y se pueden agregar varios. La
--   numeración (causa inmediata = 1, primer factor personal = 2,
--   los siguientes 2.2/2.3/…, primer factor laboral = 3, los
--   siguientes 3.2/3.3/…) la calcula el HTML según la posición en
--   la lista y se guarda tal cual en el jsonb (es una foto del
--   momento, no se recalcula después si se edita).
-- - "Personal involucrado" combina el catálogo ssoma_personal
--   (buscador) con texto libre (terceros/proveedores que no están
--   en ese catálogo), por eso es jsonb de texto y no una FK.
-- - "Reportado por" sí es un catálogo nuevo (ssoma_equipo_ssoma):
--   es el equipo interno de SSOMA que investiga y reporta, un rol
--   distinto de los "observadores/supervisores" de ssoma_personal.
-- - El plan de acciones nace "en proceso" (ssoma_accidentes_acciones
--   sin evidencia_cierre) y solo se puede finalizar subiendo un
--   archivo (PDF o imagen) como sustento — sin archivo no hay forma
--   de marcarla como finalizada, es una regla de negocio, no un
--   flag editable.
-- ============================================================

create type ssoma_tipo_evento as enum ('ACCIDENTE', 'INCIDENTE');

create table if not exists ssoma_equipo_ssoma (
  id              bigint generated always as identity primary key,
  nombre_completo text not null,
  activo          boolean not null default true,
  created_at      timestamptz not null default now()
);

comment on table ssoma_equipo_ssoma is 'Equipo interno de SSOMA que investiga y reporta accidentes/incidentes (rol distinto a los observadores/supervisores de ssoma_personal).';

insert into ssoma_equipo_ssoma (nombre_completo) values
  ('FERNANDEZ BONELLI ROO BERTH'),
  ('LAMOCCA MENDOZA JHAN'),
  ('KENYI SOLIS ORTIZ');

create table if not exists ssoma_accidentes_incidentes (
  id                     bigint generated always as identity primary key,
  codigo                 text generated always as (
    (case when tipo = 'ACCIDENTE' then 'ACC-' else 'INC-' end) || lpad(id::text, 4, '0')
  ) stored,

  tipo                   ssoma_tipo_evento not null,
  fecha                  date not null,
  reportado_por_id       bigint not null references ssoma_equipo_ssoma (id),
  cliente                text not null,
  ubicacion_id           bigint not null references ssoma_ubicaciones (id),
  personal_involucrado   jsonb not null default '[]'::jsonb,
  descripcion            text not null,

  -- Causa inmediata (mismo catálogo que RACS)
  causa_inmediata_tipo     ssoma_tipo_hallazgo not null,
  causa_inmediata_item     text not null,
  causa_inmediata_detalle  text,

  -- Causas básicas (texto libre, numeración calculada en el cliente)
  factores_personales    jsonb not null default '[]'::jsonb,
  factores_laborales     jsonb not null default '[]'::jsonb,

  evidencia              jsonb not null default '[]'::jsonb,

  created_at             timestamptz not null default now(),

  constraint ssoma_accidentes_involucrado_array_check check (jsonb_typeof(personal_involucrado) = 'array'),
  constraint ssoma_accidentes_factores_pers_array_check check (jsonb_typeof(factores_personales) = 'array'),
  constraint ssoma_accidentes_factores_lab_array_check check (jsonb_typeof(factores_laborales) = 'array'),
  constraint ssoma_accidentes_evidencia_array_check check (jsonb_typeof(evidencia) = 'array')
);

create index if not exists ssoma_accidentes_tipo_idx on ssoma_accidentes_incidentes (tipo);
create index if not exists ssoma_accidentes_fecha_idx on ssoma_accidentes_incidentes (fecha desc);
create index if not exists ssoma_accidentes_ubicacion_idx on ssoma_accidentes_incidentes (ubicacion_id);
create index if not exists ssoma_accidentes_reportante_idx on ssoma_accidentes_incidentes (reportado_por_id);

comment on table ssoma_accidentes_incidentes is 'Reportes de accidentes/incidentes con investigación de causas (causa inmediata + causas básicas).';
comment on column ssoma_accidentes_incidentes.codigo is 'Código de visualización tipo ACC-0001 / INC-0001, derivado del id (nunca se repite).';
comment on column ssoma_accidentes_incidentes.personal_involucrado is 'Array jsonb de texto: nombres de ssoma_personal elegidos por el buscador, o texto libre para terceros/proveedores.';
comment on column ssoma_accidentes_incidentes.factores_personales is 'Array jsonb de {numero, item, detalle}, ej. [{"numero":"2","item":"...","detalle":"..."},{"numero":"2.2",...}].';
comment on column ssoma_accidentes_incidentes.factores_laborales is 'Igual formato que factores_personales, numeración empieza en 3.';

create table if not exists ssoma_accidentes_acciones (
  id                bigint generated always as identity primary key,
  accidente_id      bigint not null references ssoma_accidentes_incidentes (id) on delete cascade,

  accion            text not null,
  responsable       text not null,
  plazo             date not null,

  evidencia_cierre  jsonb,        -- {nombre, tipo, contenido(base64)} — null = "En proceso"
  finalizado_at     timestamptz,  -- se llena junto con evidencia_cierre

  created_at        timestamptz not null default now(),

  constraint ssoma_accidentes_acciones_finalizado_check check (
    (evidencia_cierre is null and finalizado_at is null) or
    (evidencia_cierre is not null and finalizado_at is not null)
  )
);

create index if not exists ssoma_accidentes_acciones_accidente_idx on ssoma_accidentes_acciones (accidente_id);

comment on table ssoma_accidentes_acciones is 'Plan de acciones/aprendizaje de cada accidente/incidente. Una acción pasa de "En proceso" a "Finalizada" solo subiendo evidencia_cierre (PDF o imagen) — nunca por un simple cambio de estado.';

alter table ssoma_equipo_ssoma enable row level security;
alter table ssoma_accidentes_incidentes enable row level security;
alter table ssoma_accidentes_acciones enable row level security;

create policy ssoma_equipo_ssoma_select on ssoma_equipo_ssoma
  for select to anon, authenticated using (true);

create policy ssoma_accidentes_select on ssoma_accidentes_incidentes
  for select to anon, authenticated using (true);
create policy ssoma_accidentes_insert on ssoma_accidentes_incidentes
  for insert to anon, authenticated with check (true);
create policy ssoma_accidentes_delete on ssoma_accidentes_incidentes
  for delete to anon, authenticated using (true);

create policy ssoma_accidentes_acciones_select on ssoma_accidentes_acciones
  for select to anon, authenticated using (true);
create policy ssoma_accidentes_acciones_insert on ssoma_accidentes_acciones
  for insert to anon, authenticated with check (true);
create policy ssoma_accidentes_acciones_update on ssoma_accidentes_acciones
  for update to anon, authenticated using (true) with check (true);
