-- ============================================================
-- BLOQUE 37: Avance de Bolsa — estimado diario corrido, construido solo con el WMS
--
-- La jefatura pidió poder ir armando, día a día, una versión propia del formato del
-- auditor usando únicamente la data que ya se tiene del WMS (sin esperar el archivo
-- trimestral real) — para llevar el pulso del "Considera bruto" antes de que llegue el
-- número oficial. Se guarda aparte del respaldo de Control de Bolsa
-- (ssoma_bolsa_wms_lineas) porque son conceptos distintos: aquel es el respaldo fiel de
-- lo que se cruzó contra un archivo real del auditor; esto es un ESTIMADO propio, sin
-- auditor de por medio, que se acumula import a import.
-- ============================================================

create table if not exists ssoma_bolsa_avance_lineas (
  id                bigint generated always as identity primary key,
  fecha             date,
  semana            text,
  mes               text,
  cod_alternat      text not null,
  producto          text,
  ubicacion         text,
  motivo            text,
  origen            text,
  un_ajust          numeric not null,
  valorizado        numeric,
  considera         boolean not null,
  archivo_origen    text,
  importado_en      timestamptz not null default now(),
  created_at        timestamptz not null default now()
);

comment on table ssoma_bolsa_avance_lineas is 'Estimado diario corrido de Avance de Bolsa: movimientos del WMS clasificados con la misma lógica de Control de Bolsa, pero sin cruzar contra un archivo real del auditor — es un estimado propio, no el número oficial.';

create index if not exists ssoma_bolsa_avance_semana_idx on ssoma_bolsa_avance_lineas (semana);
create index if not exists ssoma_bolsa_avance_motivo_idx on ssoma_bolsa_avance_lineas (motivo);
create index if not exists ssoma_bolsa_avance_considera_idx on ssoma_bolsa_avance_lineas (considera);
create index if not exists ssoma_bolsa_avance_cod_idx on ssoma_bolsa_avance_lineas (cod_alternat);

alter table ssoma_bolsa_avance_lineas enable row level security;
create policy ssoma_bolsa_avance_select on ssoma_bolsa_avance_lineas for select using (true);
create policy ssoma_bolsa_avance_insert on ssoma_bolsa_avance_lineas for insert with check (true);
create policy ssoma_bolsa_avance_delete on ssoma_bolsa_avance_lineas for delete using (true);

alter table ssoma_importaciones_log drop constraint ssoma_importaciones_log_modulo_check;
alter table ssoma_importaciones_log add constraint ssoma_importaciones_log_modulo_check
  check (modulo in ('shortpick', 'sin_ubicacion', 'bolsa_auditoria', 'bolsa_wms', 'bolsa_avance'));
