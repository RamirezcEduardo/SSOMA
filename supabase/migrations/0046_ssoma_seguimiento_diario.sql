-- ============================================================
-- BLOQUE 46: Auditoría de Inventario — Seguimiento Diario
--
-- Mismo reporte "Pendientes de Operación" (hoja "Bultos Pendientes")
-- que alimenta Bultos Pendientes de Operación, pero acá se guardan
-- TODOS los demás procesos — todo lo que NO es Perdido ERU, Por
-- Ubicar ni Sin Ubicación (esos tres van a ssoma_bpo_registros).
--
-- A diferencia de esos dos, esto no es un flujo de "recuperación" por
-- unidades: son procesos que el supervisor responsable debe finalizar
-- (cerrar) — sin unidades ni valor parcial, solo pendiente/finalizado.
-- Si un LPN queda sin finalizar, puede terminar como ajuste perdido en
-- Control de Bolsa (de ahí el nombre "Seguimiento Diario").
-- ============================================================

create table if not exists ssoma_seguimiento_diario_registros (
  id                  bigint generated always as identity primary key,

  proceso             text not null,
  responsable         text,
  supervisor          text,
  semana              text,
  familia             text,
  nro_lpn             text not null unique,
  producto            text,
  cod_alternat        text,
  descripcion         text,
  cantidad_actual     numeric,
  nro_lote            text,
  val_tot             numeric,

  estado              text not null default 'pendiente' check (estado in ('pendiente', 'finalizado')),
  finalizado_en       timestamptz,
  finalizado_por_id   bigint,

  archivo_origen      text,
  created_at          timestamptz not null default now()
);

comment on table ssoma_seguimiento_diario_registros is 'Seguimiento Diario (Auditoría de Inventario): filas de "Bultos Pendientes" (Pendientes de Operación) cuyo Proceso NO es Perdido ERU/Por Ubicar/Sin Ubicación — procesos que el supervisor debe finalizar. Si queda pendiente, el LPN puede terminar como ajuste perdido en Control de Bolsa.';
comment on column ssoma_seguimiento_diario_registros.nro_lpn is 'Único por bulto — si el LPN ya está cargado, el import lo detecta como duplicado y NO lo vuelve a insertar.';
comment on column ssoma_seguimiento_diario_registros.estado is 'pendiente hasta que el supervisor lo marca finalizado en la app. Sin seguimiento de unidades/valor parcial (no es un flujo de recuperación).';

alter table ssoma_seguimiento_diario_registros enable row level security;

create policy ssoma_seguimiento_diario_registros_select on ssoma_seguimiento_diario_registros
  for select to anon, authenticated using (true);
create policy ssoma_seguimiento_diario_registros_insert on ssoma_seguimiento_diario_registros
  for insert to anon, authenticated with check (true);
create policy ssoma_seguimiento_diario_registros_update on ssoma_seguimiento_diario_registros
  for update to anon, authenticated using (true);
create policy ssoma_seguimiento_diario_registros_delete on ssoma_seguimiento_diario_registros
  for delete to anon, authenticated using (true);

alter table ssoma_importaciones_log drop constraint if exists ssoma_importaciones_log_modulo_check;
alter table ssoma_importaciones_log add constraint ssoma_importaciones_log_modulo_check
  check (modulo in ('shortpick', 'bolsa_auditoria', 'bolsa_wms', 'bultos_pendientes_operacion', 'sin_ubicacion_wms', 'seguimiento_diario'));
