-- ============================================================
-- BLOQUE 55: Inbound — Solicitudes/OT (Órdenes de Trabajo)
--
-- Los operadores reciben Órdenes de Trabajo en PDF (ej. "Orden de
-- trabajo reacondicionado de productos (QA)" de INRetail Pharma,
-- código IRP-AAR-QA-FR020). El PDF trae una tabla con una fila por
-- N° Protocolo — un mismo PDF puede traer varios protocolos bajo la
-- misma O/C. Cada fila se guarda como una "solicitud" para poder
-- mapearla y hacerle seguimiento individual.
--
-- No se sabe todavía si N° Protocolo se repite entre PDFs distintos
-- (el usuario no está seguro), así que NO es una llave única acá —
-- eso ya nos mordió una vez en Seguimiento Diario (bloque 54) con una
-- unicidad demasiado estricta que descartaba apariciones legítimas.
-- La única protección contra reimportar el mismo PDF dos veces es el
-- chequeo de hash de archivo que ya usan los demás importadores
-- (ssoma_importaciones_log), que avisa pero no bloquea.
--
-- "estado" arranca en 'pendiente' y hoy solo se puede pasar a
-- 'finalizado' a mano; el cruce automático contra el Excel del WMS
-- (para detectar solo qué de verdad ya se despachó/atendió) queda
-- pendiente de definir cuando se comparta ese archivo.
-- ============================================================

create table if not exists ssoma_inbound_solicitudes_ot (
  id                      bigint generated always as identity primary key,

  -- Detalle de la fila (uno por N° Protocolo)
  numero_protocolo        text not null,
  orden_compra            text,
  proveedor               text,
  cod_producto            text,
  producto                text,
  rs_nso                  text,
  crs                     text,
  lote                    text,
  fecha_vencimiento       text,
  cantidad                numeric,
  tipo_producto           text,
  temperatura             text,
  observacion             text,
  actividad_reacondicionado text,
  validacion              text,

  -- Cabecera del documento (se repite igual en cada fila del mismo PDF)
  fecha_emision           date,
  codigo_formato          text,
  version_formato         text,
  empresa                 text,
  titulo_documento        text,
  elaborado_por           text,
  elaborado_fecha_hora    text,
  vb_qa_por               text,
  vb_qa_fecha_hora        text,
  recibido_por            text,
  recibido_fecha_hora     text,
  entregado_por           text,
  entregado_fecha_hora    text,
  datos_adicionales       text,

  estado                  text not null default 'pendiente' check (estado in ('pendiente', 'finalizado')),
  finalizado_en           timestamptz,
  finalizado_por_id       bigint,

  archivo_origen          text,
  creado_por_id           bigint,
  created_at              timestamptz not null default now()
);

comment on table ssoma_inbound_solicitudes_ot is 'Inbound → Solicitudes/OT: una fila por N° Protocolo extraído de la Orden de Trabajo en PDF que sube el operador. N° Protocolo NO es único (no se sabe si se repite entre PDFs) — la protección contra reimportar el mismo PDF es el hash de archivo en ssoma_importaciones_log.';
comment on column ssoma_inbound_solicitudes_ot.estado is 'pendiente hasta que se marca finalizado a mano o (pendiente de definir) por un cruce contra el Excel del WMS.';

alter table ssoma_inbound_solicitudes_ot enable row level security;

create policy ssoma_inbound_solicitudes_ot_select on ssoma_inbound_solicitudes_ot
  for select to anon, authenticated using (true);
create policy ssoma_inbound_solicitudes_ot_insert on ssoma_inbound_solicitudes_ot
  for insert to anon, authenticated with check (true);
create policy ssoma_inbound_solicitudes_ot_update on ssoma_inbound_solicitudes_ot
  for update to anon, authenticated using (true);
create policy ssoma_inbound_solicitudes_ot_delete on ssoma_inbound_solicitudes_ot
  for delete to anon, authenticated using (true);

alter table ssoma_importaciones_log drop constraint if exists ssoma_importaciones_log_modulo_check;
alter table ssoma_importaciones_log add constraint ssoma_importaciones_log_modulo_check
  check (modulo in ('shortpick', 'bolsa_auditoria', 'bolsa_wms', 'bultos_pendientes_operacion', 'sin_ubicacion_wms', 'seguimiento_diario', 'inbound_solicitudes_ot'));
