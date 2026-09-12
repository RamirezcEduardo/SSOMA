-- ============================================================
-- BLOQUE 41: Inventario — Bultos Pendientes de Operación
--
-- Flujo nuevo (reemplaza a Bultos Perdidos/Sin Ubicación, retirados
-- en 0039/0040): se sube el reporte "Pendientes de Operación" tal
-- cual (hoja "Bultos Pendientes"), filtrado por Proceso = Perdido
-- ERU / Por Ubicar / Sin Ubicación, y clasificado en dos listas:
--   - perdidos: Proceso en (Perdido ERU, Por Ubicar)
--   - sin_ubicacion: Proceso = Sin Ubicación
--
-- A diferencia de Bultos Perdidos (que tenía tabla aparte de
-- verificaciones con sustento/foto), acá el estado se guarda
-- directo en el registro: "pendiente" hasta que se marca
-- "recuperado" a mano. Un mismo Nro LPN se reimporta cada vez que
-- se sube el reporte (es un archivo semanal/diario acumulativo) —
-- por eso nro_lpn es único: reimportar actualiza el registro
-- existente en vez de duplicarlo, y si reaparece como pendiente en
-- un archivo nuevo se resetea el estado (sigue sin resolverse).
-- ============================================================

create table if not exists ssoma_bpo_registros (
  id                bigint generated always as identity primary key,

  proceso           text not null,
  clasificacion     text not null check (clasificacion in ('perdidos', 'sin_ubicacion')),

  responsable       text,
  supervisor        text,
  semana            text,
  familia           text,
  nro_lpn           text not null unique,
  producto          text,
  cod_alternat      text,
  descripcion       text,
  cantidad_actual   numeric,
  nro_lote          text,
  val_tot           numeric,

  estado            text not null default 'pendiente' check (estado in ('pendiente', 'recuperado')),
  recuperado_en     timestamptz,
  recuperado_por_id bigint,

  archivo_origen    text,
  created_at        timestamptz not null default now(),
  actualizado_en    timestamptz not null default now()
);

comment on table ssoma_bpo_registros is 'Bultos Pendientes de Operación: filas de la hoja "Bultos Pendientes" (reporte "Pendientes de Operación") con Proceso en Perdido ERU/Por Ubicar/Sin Ubicación. clasificacion agrupa Perdido ERU+Por Ubicar como "perdidos" y Sin Ubicación aparte.';
comment on column ssoma_bpo_registros.nro_lpn is 'Único por bulto — reimportar el mismo LPN actualiza el registro en vez de duplicarlo.';
comment on column ssoma_bpo_registros.estado is 'pendiente hasta que se marca "recuperado" a mano en la app. Si un LPN ya recuperado reaparece pendiente en un import nuevo, se resetea a pendiente.';

alter table ssoma_bpo_registros enable row level security;

create policy ssoma_bpo_registros_select on ssoma_bpo_registros
  for select to anon, authenticated using (true);
create policy ssoma_bpo_registros_insert on ssoma_bpo_registros
  for insert to anon, authenticated with check (true);
create policy ssoma_bpo_registros_update on ssoma_bpo_registros
  for update to anon, authenticated using (true);
create policy ssoma_bpo_registros_delete on ssoma_bpo_registros
  for delete to anon, authenticated using (true);

alter table ssoma_importaciones_log drop constraint if exists ssoma_importaciones_log_modulo_check;
alter table ssoma_importaciones_log add constraint ssoma_importaciones_log_modulo_check
  check (modulo in ('shortpick', 'bolsa_auditoria', 'bolsa_wms', 'bultos_pendientes_operacion'));
