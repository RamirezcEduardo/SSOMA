-- ============================================================
-- BLOQUE 71: Reabastecimiento — auditoría de olas vs. ejecución real
--
-- Dos exports del WMS, cruzados por Numero Ejecuc (el número de Ola):
--   - "Allocation Run Header": 1 fila por Ola, con el total planeado
--     en Texto de mensaje ("Cantidad asignada: 15349(867 LPNs)") ->
--     se guarda en ssoma_reabasto_olas.
--   - "Allocation" (detalle): 1 fila por LPN/cartón realmente
--     ejecutado dentro de esa Ola -> ssoma_reabasto_lineas.
--
-- El objetivo es auditar si el reabasto se gestionó bien: comparar
-- cantidad/LPN planeados (header) contra lo realmente ejecutado
-- (conteo de líneas del detalle) para detectar olas incompletas o
-- "sobre-reabastecidas" (más líneas ejecutadas que las planeadas,
-- posible ubicación con cantidad de más). De momento solo se trabaja
-- con Ubic destino (adónde se reabasteció) — la mayoría de filas de
-- este export no trae "De ubicación" (origen) confiable.
--
-- No hay FK entre ambas tablas: el detalle se vincula por Numero
-- Ejecuc como texto libre, no por referencia dura, porque el archivo
-- de detalle puede subirse aunque esa Ola todavía no tenga su header
-- cargado (o nunca lo tenga, si el header es muy viejo).
-- ============================================================

create table if not exists ssoma_reabasto_olas (
  numero_ejecuc         text primary key,

  ola                   text,
  plantilla_ciclo       text,
  estado                text,
  cantidad_asignada_hdr numeric,
  lpns_asignados_hdr    integer,
  fecha_crea            timestamptz,
  fecha_modif           timestamptz,

  archivo_origen        text,
  creado_por_id         bigint,
  actualizado_en        timestamptz not null default now()
);

comment on table ssoma_reabasto_olas is 'Reabastecimiento: 1 fila por Ola (Numero Ejecuc), desde el export "Allocation Run Header" del WMS. cantidad_asignada_hdr/lpns_asignados_hdr se extraen de "Texto de mensaje" ("Cantidad asignada: 15349(867 LPNs)").';

alter table ssoma_reabasto_olas enable row level security;

create policy ssoma_reabasto_olas_select on ssoma_reabasto_olas
  for select to anon, authenticated using (true);
create policy ssoma_reabasto_olas_insert on ssoma_reabasto_olas
  for insert to anon, authenticated with check (true);
create policy ssoma_reabasto_olas_update on ssoma_reabasto_olas
  for update to anon, authenticated using (true);
create policy ssoma_reabasto_olas_delete on ssoma_reabasto_olas
  for delete to anon, authenticated using (true);

create table if not exists ssoma_reabasto_lineas (
  id                bigint generated always as identity primary key,
  numero_ejecuc     text not null,

  producto          text,
  descripcion       text,
  cod_alternat      text,
  cantidad_asignada numeric,
  nro_lpn           text,
  ubic_destino      text,
  estado            text,
  fecha_modif       timestamptz,

  archivo_origen    text,
  creado_por_id     bigint,
  creado_en         timestamptz not null default now(),

  unique (numero_ejecuc, nro_lpn, cod_alternat)
);

comment on table ssoma_reabasto_lineas is 'Reabastecimiento: 1 fila por LPN/cartón ejecutado dentro de una Ola, desde el export "Allocation" (detalle) del WMS. Se vincula a ssoma_reabasto_olas por numero_ejecuc (texto, sin FK — el detalle puede subirse sin que la Ola tenga header cargado).';
comment on column ssoma_reabasto_lineas.nro_lpn is 'Nro LPN Entrada o Num Carton, el que venga con dato en esa fila (son excluyentes).';

create index if not exists ssoma_reabasto_lineas_numero_ejecuc_idx on ssoma_reabasto_lineas (numero_ejecuc);

alter table ssoma_reabasto_lineas enable row level security;

create policy ssoma_reabasto_lineas_select on ssoma_reabasto_lineas
  for select to anon, authenticated using (true);
create policy ssoma_reabasto_lineas_insert on ssoma_reabasto_lineas
  for insert to anon, authenticated with check (true);
create policy ssoma_reabasto_lineas_update on ssoma_reabasto_lineas
  for update to anon, authenticated using (true);
create policy ssoma_reabasto_lineas_delete on ssoma_reabasto_lineas
  for delete to anon, authenticated using (true);

-- "bultos_perdidos_wms" quedó usándose en el import de "Subir desde WMS" de Bultos
-- Perdidos sin haberse agregado nunca a este check (quedaba fallando en silencio solo
-- el registro del log de duplicados, no el import en sí) — se agrega junto con los dos
-- módulos nuevos de Reabastecimiento.
alter table ssoma_importaciones_log drop constraint if exists ssoma_importaciones_log_modulo_check;
alter table ssoma_importaciones_log add constraint ssoma_importaciones_log_modulo_check
  check (modulo in ('shortpick', 'bolsa_auditoria', 'bolsa_wms', 'bultos_pendientes_operacion', 'sin_ubicacion_wms', 'seguimiento_diario', 'inbound_solicitudes_ot', 'bultos_perdidos_wms', 'reabasto_olas', 'reabasto_lineas'));
