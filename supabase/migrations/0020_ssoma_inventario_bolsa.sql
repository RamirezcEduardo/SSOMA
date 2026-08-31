-- ============================================================
-- BLOQUE 20: Inventario — Control de Bolsa
--
-- Objetivo: reducir el monto que el área auditora reversa/cobra
-- cada trimestre, cruzando dos fuentes:
--   1) El reporte oficial de diferencias que manda el auditor
--      (ej. "Dif Santa Anita Q3-2026.xlsb", hoja Data) -> guarda
--      en ssoma_bolsa_auditoria_lineas.
--   2) El export interno del WMS (ej. "Plantilla CD 9053.xlsx",
--      hoja DATA) -> guarda en ssoma_bolsa_wms_lineas.
--
-- La regla "Considerar / No considerar" es la que YA aplica el
-- auditor (confirmada contra sus propias hojas "Considerar" /
-- "No considerar" del Q3 2026: Total general = S/ -18,747.54 en
-- los motivos que sí cuentan). Se guarda en
-- ssoma_bolsa_reglas_considerar en vez de quedar fija en una
-- fórmula, porque el auditor puede cambiar el criterio de un
-- trimestre a otro.
--
-- Los nombres de motivo no calzan exacto entre ambos sistemas
-- (ej. "AJUSTES SIN UBICACIÓN" en el WMS vs. "AJUSTE SIN
-- UBICACION" en la auditoría) -> ssoma_bolsa_motivo_equivalencias
-- guarda el mapeo para poder cruzar ambas fuentes automáticamente.
--
-- Estado de la línea del auditor: cada una nace "sin_revisar" y
-- pasa a "en_disputa" (con sustento) mientras se investiga, y
-- termina en "descartado" (el auditor la retira, no se paga) o
-- "aceptado" (se confirma, sí se paga) — igual de espíritu que
-- ssoma_accidentes_acciones: sin evidencia/sustento no se puede
-- cerrar la disputa.
-- ============================================================

create type ssoma_bolsa_estado_disputa as enum ('sin_revisar', 'en_disputa', 'descartado', 'aceptado');

create table if not exists ssoma_bolsa_auditoria_lineas (
  id                bigint generated always as identity primary key,

  fecha             date not null,
  semana            text,
  mes               text,
  trimestre         text,

  cd_nombre         text,                 -- ORG_NAME_FULL, ej. "CENTRO DE DISTRIBUCION STA. ANITA"
  cod_producto      text not null,        -- PRD_LVL_NUMBER
  producto          text not null,        -- PRD_NAME_FULL
  familia           text,                 -- FARMACIA / PERFUMERIA / LACTEOS / CONTROLADOS / REFRIGERADOS / SUPERVISADO...

  cantidad          numeric,
  costo_unit        numeric,
  cant_reversada    numeric,
  monto_reversado   numeric not null,     -- lo que efectivamente te descuentan si "considera" = true

  ubicacion         text,
  area              text,
  origen            text,
  tipo              text not null,        -- TIPO (ej. "AJUSTE LPN", "CONTEO CICLICO")
  motivo_op         text not null,        -- MOTIVO OP (ej. "AJUSTE PERDIDO", "SHORTPICK")
  trans_ref         text,
  trans_user        text,

  considera         boolean not null,     -- calculado al importar contra ssoma_bolsa_reglas_considerar
  estado_disputa    ssoma_bolsa_estado_disputa not null default 'sin_revisar',
  sustento          text,                 -- por qué se disputa / por qué se descarta o acepta
  evidencia         jsonb not null default '[]'::jsonb,

  archivo_origen    text,                 -- nombre del Excel importado, para trazabilidad
  importado_en      timestamptz not null default now(),
  created_at        timestamptz not null default now(),

  constraint ssoma_bolsa_auditoria_evidencia_array_check check (jsonb_typeof(evidencia) = 'array'),
  constraint ssoma_bolsa_auditoria_disputa_sustento_check check (
    estado_disputa = 'sin_revisar' or sustento is not null
  )
);

create index if not exists ssoma_bolsa_auditoria_semana_idx on ssoma_bolsa_auditoria_lineas (semana);
create index if not exists ssoma_bolsa_auditoria_motivo_idx on ssoma_bolsa_auditoria_lineas (tipo, motivo_op);
create index if not exists ssoma_bolsa_auditoria_considera_idx on ssoma_bolsa_auditoria_lineas (considera);
create index if not exists ssoma_bolsa_auditoria_estado_idx on ssoma_bolsa_auditoria_lineas (estado_disputa);
create index if not exists ssoma_bolsa_auditoria_producto_idx on ssoma_bolsa_auditoria_lineas (cod_producto);

comment on table ssoma_bolsa_auditoria_lineas is 'Detalle línea por línea del reporte de diferencias que manda el área auditora cada trimestre (ej. Dif Santa Anita).';
comment on column ssoma_bolsa_auditoria_lineas.considera is 'true = este motivo cuenta contra el CD según la regla vigente del auditor (ver ssoma_bolsa_reglas_considerar). false = está excluido (ej. CREACION SUIZO, OBSERVADO).';
comment on column ssoma_bolsa_auditoria_lineas.evidencia is 'Array jsonb de {nombre, tipo, contenido(base64)} — sustento de la disputa (foto, captura del WMS, etc.), mismo formato que ssoma_accidentes_acciones.evidencia_cierre.';

create table if not exists ssoma_bolsa_wms_lineas (
  id                bigint generated always as identity primary key,

  historial_actividad  text,
  nro_lpn              text,
  cod_alternat          text not null,
  producto              text,
  descripcion           text,
  ubicacion             text,

  fecha_crea            timestamptz,
  semana                text,
  mes                   text,
  anio                  text,
  trimestre             text,

  usuario_creado        text,
  nombre_pantalla       text,
  cod_razon             text,
  motivo                text,             -- Motivos (WMS), ver ssoma_bolsa_motivo_equivalencias
  area                  text,
  origen                text,

  un_ajust              numeric,
  valor_actual          numeric,
  proveedor             text,

  archivo_origen        text,
  importado_en          timestamptz not null default now(),
  created_at            timestamptz not null default now()
);

create index if not exists ssoma_bolsa_wms_semana_idx on ssoma_bolsa_wms_lineas (semana);
create index if not exists ssoma_bolsa_wms_motivo_idx on ssoma_bolsa_wms_lineas (motivo);
create index if not exists ssoma_bolsa_wms_cod_alternat_idx on ssoma_bolsa_wms_lineas (cod_alternat);
create index if not exists ssoma_bolsa_wms_ubicacion_idx on ssoma_bolsa_wms_lineas (ubicacion);

comment on table ssoma_bolsa_wms_lineas is 'Detalle línea por línea de tu export interno del WMS (ej. Plantilla CD 9053, hoja DATA) — el respaldo operativo para disputar líneas de la auditoría.';

create table if not exists ssoma_bolsa_reglas_considerar (
  id              bigint generated always as identity primary key,
  tipo            text not null,
  motivo_op       text not null,
  considera       boolean not null,
  nota            text,
  vigente_desde   date not null default current_date,

  unique (tipo, motivo_op)
);

comment on table ssoma_bolsa_reglas_considerar is 'Regla vigente del auditor: qué combinaciones Tipo+Motivo OP cuentan ("considera") contra el CD. Editable sin tocar código si el auditor cambia el criterio.';

insert into ssoma_bolsa_reglas_considerar (tipo, motivo_op, considera, nota) values
  ('AJUSTE LPN',     'AJUSTE CARTONES',            true,  'Confirmado en hoja "Considerar" del auditor, Q3 2026.'),
  ('AJUSTE LPN',     'AJUSTE DROP',                true,  'Confirmado en hoja "Considerar" del auditor, Q3 2026.'),
  ('AJUSTE LPN',     'AJUSTE PERDIDO',             true,  'Confirmado en hoja "Considerar" del auditor, Q3 2026.'),
  ('AJUSTE LPN',     'VAS',                        true,  'Confirmado en hoja "Considerar" del auditor, Q3 2026.'),
  ('AJUSTE LPN',     'CREA LPN VAS',               true,  'Confirmado en hoja "Considerar" del auditor, Q3 2026.'),
  ('AJUSTE LPN',     'AJUSTE B2B',                 true,  'Confirmado en hoja "Considerar" del auditor, Q3 2026.'),
  ('AJUSTE LPN',     'CREA LPN MERMA',             true,  'Confirmado en hoja "Considerar" del auditor, Q3 2026.'),
  ('AJUSTE LPN',     'AJUSTE SIN UBICACION',       true,  'Confirmado en hoja "Considerar" del auditor, Q3 2026.'),
  ('AJUSTE LPN',     'CREACION LPN',               true,  'Confirmado en hoja "Considerar" del auditor, Q3 2026.'),
  ('AJUSTE LPN',     'AJUSTE TRASLADO',            true,  'Confirmado en hoja "Considerar" del auditor, Q3 2026.'),
  ('CONTEO CICLICO', 'AJUSTE ACTIVO',              true,  'Confirmado en hoja "Considerar" del auditor, Q3 2026.'),
  ('CONTEO CICLICO', 'AJUSTE RESERVA DETALLE LPN', true,  'Confirmado en hoja "Considerar" del auditor, Q3 2026.'),
  ('CONTEO CICLICO', 'AJUSTE RESERVA LPN',         true,  'Confirmado en hoja "Considerar" del auditor, Q3 2026.'),
  ('CONTEO CICLICO', 'SHORTPICK',                  true,  'Confirmado en hoja "Considerar" del auditor, Q3 2026.'),
  ('AJUSTE LPN',     'AJUSTE SIEMBRA',             false, 'Confirmado en hoja "No considerar" del auditor, Q3 2026.'),
  ('AJUSTE LPN',     'CREA LPN MULTISKU',          false, 'Confirmado en hoja "No considerar" del auditor, Q3 2026.'),
  ('AJUSTE LPN',     'CREACION SUIZO',             false, 'Confirmado en hoja "No considerar" del auditor, Q3 2026 — evento aislado, +S/276,241.'),
  ('AJUSTE LPN',     'OBSERVADO',                  false, 'Confirmado en hoja "No considerar" del auditor, Q3 2026.'),
  ('CONTEO CICLICO', 'OBSERVADO',                  false, 'Confirmado en hoja "No considerar" del auditor, Q3 2026.')
on conflict (tipo, motivo_op) do nothing;

create table if not exists ssoma_bolsa_motivo_equivalencias (
  id                 bigint generated always as identity primary key,
  motivo_wms         text not null,   -- Motivos (Plantilla CD 9053)
  motivo_op_auditor  text not null,   -- MOTIVO OP (reporte del auditor)
  nota               text,

  unique (motivo_wms, motivo_op_auditor)
);

comment on table ssoma_bolsa_motivo_equivalencias is 'Mapeo entre los nombres de Motivo del WMS interno y los MOTIVO OP del auditor (no calzan exacto) — necesario para cruzar ambas fuentes automáticamente.';

insert into ssoma_bolsa_motivo_equivalencias (motivo_wms, motivo_op_auditor, nota) values
  ('AJUSTE ACTIVO',        'AJUSTE ACTIVO',        'Mismo texto en ambos sistemas.'),
  ('CREACION LPN',         'CREACION LPN',         'Mismo texto en ambos sistemas.'),
  ('VAS',                  'VAS',                  'Mismo texto en ambos sistemas.'),
  ('CREACION LPN VAS',     'CREA LPN VAS',         'Abreviado distinto en el reporte del auditor.'),
  ('AJUSTES SIN UBICACIÓN','AJUSTE SIN UBICACION', 'Plural + tilde distinta en el WMS.'),
  ('AJUSTE PERDIDO',       'AJUSTE PERDIDO',       'Mismo texto en ambos sistemas.'),
  ('CREACION LPN MRM',     'CREA LPN MERMA',       'Abreviado distinto en el reporte del auditor.'),
  ('CREACION MULTISKU',    'CREA LPN MULTISKU',    'Abreviado distinto — este motivo cae en "No considerar".')
on conflict (motivo_wms, motivo_op_auditor) do nothing;

alter table ssoma_bolsa_auditoria_lineas enable row level security;
alter table ssoma_bolsa_wms_lineas enable row level security;
alter table ssoma_bolsa_reglas_considerar enable row level security;
alter table ssoma_bolsa_motivo_equivalencias enable row level security;

create policy ssoma_bolsa_auditoria_select on ssoma_bolsa_auditoria_lineas
  for select to anon, authenticated using (true);
create policy ssoma_bolsa_auditoria_insert on ssoma_bolsa_auditoria_lineas
  for insert to anon, authenticated with check (true);
create policy ssoma_bolsa_auditoria_update on ssoma_bolsa_auditoria_lineas
  for update to anon, authenticated using (true) with check (true);

create policy ssoma_bolsa_wms_select on ssoma_bolsa_wms_lineas
  for select to anon, authenticated using (true);
create policy ssoma_bolsa_wms_insert on ssoma_bolsa_wms_lineas
  for insert to anon, authenticated with check (true);

-- Reglas y equivalencias: solo lectura pública (se editan a mano/por un
-- admin cuando el auditor cambia el criterio, igual que los catálogos).
create policy ssoma_bolsa_reglas_select on ssoma_bolsa_reglas_considerar
  for select to anon, authenticated using (true);
create policy ssoma_bolsa_equivalencias_select on ssoma_bolsa_motivo_equivalencias
  for select to anon, authenticated using (true);
