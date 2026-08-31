-- ============================================================
-- BLOQUE 23: Inventario — Auditoría Bultos Perdidos
--
-- Mismo patrón que ssoma_sp_registros/ssoma_sp_verificaciones
-- (migración 0019_ssoma_shortpick_registros_y_verificaciones):
-- registros importados aparte de las verificaciones,
-- para no perder cuándo se creó cada uno; un registro sin fila en
-- verificaciones = "Perdido" (pendiente), con fila = "Ubicado".
--
-- Fuente: hoja "Bultos Pendientes" del archivo "Pendientes de
-- Operación" que comparten a diario — filtrado a Proceso =
-- "Perdido ERU" (esa misma hoja también trae Drop/Averías/Canjes/
-- Sempar/Por Ubicar/Sin Ubicación, que no son de este módulo).
--
-- A diferencia de Shortpick, acá no hay "cantidad parcial
-- encontrada" (un bulto se encuentra completo o sigue perdido) ni
-- "otra ubicación" (el bulto no tenía una ubicación esperada que
-- contrastar) — por eso ssoma_bp_verificaciones es más simple: solo
-- el sustento de qué se encontró en Historial Inventario, con foto
-- opcional (no obligatoria, a diferencia de Shortpick).
-- ============================================================

create table if not exists ssoma_bp_registros (
  id                  bigint generated always as identity primary key,

  fecha               timestamptz not null,      -- Fe y Hr Crea del caso "Perdido ERU"
  nro_lpn             text not null,
  cod_alternat        text not null,
  codigo_barras       text,                       -- columna "Producto" del export (EAN), igual que en Shortpick
  descripcion         text not null,
  cantidad            integer not null,

  ubicacion_anterior  text,                       -- dónde estaba antes de darse por perdido
  area                text,
  familia             text,
  responsable         text,
  supervisor          text,
  semana              text,

  nro_lote            text,
  fecha_caducidad     date,
  nro_oc              text,
  usuario_recepcion   text,

  valorizado          numeric,

  creado_por_id       bigint,
  created_at          timestamptz not null default now()
);

comment on table ssoma_bp_registros is 'Casos "Perdido ERU" importados de la hoja Bultos Pendientes (Pendientes de Operación) — bultos que el WMS no encuentra.';
comment on column ssoma_bp_registros.codigo_barras is 'Columna "Producto" del export — es el código de barras/EAN, no el nombre del producto (igual que ssoma_sp_registros).';

create table if not exists ssoma_bp_verificaciones (
  id                  bigint generated always as identity primary key,
  registro_id         bigint not null references ssoma_bp_registros (id) on delete cascade,

  sustento            text not null,              -- qué se encontró en Historial Inventario (Nro LPN reapareció con movimiento)
  foto                jsonb,                       -- {nombre, tipo, contenido(base64)} — opcional, no obligatoria como en Shortpick

  verificado_por_id   bigint,
  fecha               timestamptz not null default now(),

  unique (registro_id)
);

comment on table ssoma_bp_verificaciones is 'Conciliación de cada caso: un registro sin fila aquí sigue "Perdido"; con fila pasa a "Ubicado". Esta tabla es la bitácora que usa Control de Bolsa para disputar AJUSTE PERDIDO.';

alter table ssoma_bp_registros enable row level security;
alter table ssoma_bp_verificaciones enable row level security;

create policy ssoma_bp_registros_select on ssoma_bp_registros
  for select to anon, authenticated using (true);
create policy ssoma_bp_registros_insert on ssoma_bp_registros
  for insert to anon, authenticated with check (true);
create policy ssoma_bp_registros_update on ssoma_bp_registros
  for update to anon, authenticated using (true);
create policy ssoma_bp_registros_delete on ssoma_bp_registros
  for delete to anon, authenticated using (true);

create policy ssoma_bp_verificaciones_select on ssoma_bp_verificaciones
  for select to anon, authenticated using (true);
create policy ssoma_bp_verificaciones_insert on ssoma_bp_verificaciones
  for insert to anon, authenticated with check (true);
create policy ssoma_bp_verificaciones_update on ssoma_bp_verificaciones
  for update to anon, authenticated using (true);
create policy ssoma_bp_verificaciones_delete on ssoma_bp_verificaciones
  for delete to anon, authenticated using (true);
