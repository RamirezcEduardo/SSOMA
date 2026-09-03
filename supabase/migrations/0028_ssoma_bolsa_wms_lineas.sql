-- ============================================================
-- BLOQUE 28: Respaldo permanente del bruto WMS — Control de Bolsa
--
-- Documenta una tabla que ya existía en el proyecto (aplicada
-- directamente contra la base en una sesión anterior, sin dejar
-- este archivo) — se reconstruye aquí tal cual está hoy en
-- producción, para que el historial de migraciones no quede
-- incompleto. No se debe volver a aplicar contra el proyecto
-- zlukrktpjffiycarpduc (la tabla ya existe); sirve para poder
-- levantar el esquema completo desde cero en un proyecto nuevo.
--
-- Cada línea válida del export "Historial Inventario" del WMS
-- (bruto, sin procesar) que subes en Inventario → Control de
-- Bolsa queda guardada aquí al importar — es el sustento que
-- respalda cada disputa, y no se pierde al recargar la página.
-- ============================================================

create table if not exists ssoma_bolsa_wms_lineas (
  id                bigint generated always as identity primary key,

  historial_actividad text,
  nro_lpn           text,
  cod_alternat      text not null,
  producto          text,
  descripcion       text,
  ubicacion         text,
  fecha_crea        timestamptz,
  semana            text,
  mes               text,
  anio              text,
  trimestre         text,
  usuario_creado    text,
  nombre_pantalla   text,
  cod_razon         text,
  motivo            text,
  area              text,
  origen            text,
  un_ajust          numeric,
  valor_actual      numeric,
  proveedor         text,
  archivo_origen    text,

  importado_en      timestamptz not null default now(),
  created_at        timestamptz not null default now()
);

create index if not exists ssoma_bolsa_wms_semana_idx on ssoma_bolsa_wms_lineas (semana);
create index if not exists ssoma_bolsa_wms_motivo_idx on ssoma_bolsa_wms_lineas (motivo);
create index if not exists ssoma_bolsa_wms_cod_alternat_idx on ssoma_bolsa_wms_lineas (cod_alternat);
create index if not exists ssoma_bolsa_wms_ubicacion_idx on ssoma_bolsa_wms_lineas (ubicacion);

comment on table ssoma_bolsa_wms_lineas is 'Detalle línea por línea de tu export interno del WMS (ej. Plantilla CD 9053, hoja DATA) — el respaldo operativo para disputar líneas de la auditoría.';

alter table ssoma_bolsa_wms_lineas enable row level security;

create policy ssoma_bolsa_wms_select on ssoma_bolsa_wms_lineas for select using (true);
create policy ssoma_bolsa_wms_insert on ssoma_bolsa_wms_lineas for insert with check (true);
