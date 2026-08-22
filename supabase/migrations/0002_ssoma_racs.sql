-- ============================================================
-- BLOQUE 2: Reportes RACS (Actos y Condiciones Subestándar)
-- + historial de levantamientos.
--
-- Corrige el bug del HTML original: el id "RACS-0001" se
-- calculaba como reports.length + 1, así que al borrar un
-- reporte el siguiente id nuevo podía repetir uno existente.
-- Aquí el id real es "id bigint generated always as identity"
-- (nunca se reutiliza, incluso si se borran filas) y
-- "racs_code" es una columna generada a partir de ese id, solo
-- para mostrar el mismo formato "RACS-0001" en la interfaz.
--
-- También mejora el flujo de "Reabrir": en el HTML original,
-- reabrir un RACS BORRABA el levantamiento anterior
-- (delete r.levantamiento). Aquí se guarda como historial: cada
-- levantamiento es una fila con "activo", así que reabrir solo
-- desactiva la fila en vez de destruir el registro de qué
-- acción correctiva se había tomado antes.
-- ============================================================

create type ssoma_tipo_hallazgo as enum ('ACTO SUB ESTANDAR', 'CONDICION SUB ESTANDAR');
create type ssoma_estado_racs as enum ('Pendiente', 'Levantado');

create table if not exists ssoma_racs_reports (
  id             bigint generated always as identity primary key,
  racs_code      text generated always as ('RACS-' || lpad(id::text, 4, '0')) stored,

  fecha          date not null,
  observador_id  bigint not null references ssoma_personal (id),
  ubicacion_id   bigint not null references ssoma_ubicaciones (id),
  tipo           ssoma_tipo_hallazgo not null,
  estado         ssoma_estado_racs not null default 'Pendiente',

  -- campos de "ACTO SUB ESTANDAR"
  ocurrencia     text,
  trabajador     text,

  -- campos de "CONDICION SUB ESTANDAR"
  condicion      text,

  descripcion    text not null,
  evidencia      text,                          -- nota/enlace, no almacena archivos (igual que hoy)

  created_at     timestamptz not null default now(),

  constraint ssoma_racs_tipo_acto_check check (
    tipo <> 'ACTO SUB ESTANDAR' or (ocurrencia is not null and trabajador is not null)
  ),
  constraint ssoma_racs_tipo_cond_check check (
    tipo <> 'CONDICION SUB ESTANDAR' or condicion is not null
  )
);

create index if not exists ssoma_racs_reports_tipo_idx on ssoma_racs_reports (tipo);
create index if not exists ssoma_racs_reports_estado_idx on ssoma_racs_reports (estado);
create index if not exists ssoma_racs_reports_fecha_idx on ssoma_racs_reports (fecha desc);
create index if not exists ssoma_racs_reports_observador_idx on ssoma_racs_reports (observador_id);
create index if not exists ssoma_racs_reports_ubicacion_idx on ssoma_racs_reports (ubicacion_id);

comment on table ssoma_racs_reports is 'Reportes de Actos y Condiciones Subestándar (RACS).';
comment on column ssoma_racs_reports.racs_code is 'Código de visualización tipo RACS-0001, derivado del id (nunca se repite).';

create table if not exists ssoma_levantamientos (
  id               bigint generated always as identity primary key,
  racs_report_id   bigint not null references ssoma_racs_reports (id) on delete cascade,

  accion           text not null,
  responsable      text not null,
  fecha            date not null,
  evidencia        text,

  activo           boolean not null default true,  -- false = fue "reabierto", se conserva como historial
  created_at       timestamptz not null default now()
);

create index if not exists ssoma_levantamientos_racs_report_idx on ssoma_levantamientos (racs_report_id);
create unique index if not exists ssoma_levantamientos_un_activo_por_racs
  on ssoma_levantamientos (racs_report_id)
  where activo;

comment on table ssoma_levantamientos is 'Historial de acciones correctivas por cada RACS. Como mucho un levantamiento activo por reporte (índice único parcial).';

-- Mantiene ssoma_racs_reports.estado sincronizado con si existe
-- un levantamiento activo, sin depender de que la app lo haga bien.
create or replace function ssoma_sync_racs_estado()
returns trigger
language plpgsql
as $$
declare
  target_id bigint := coalesce(new.racs_report_id, old.racs_report_id);
  hay_activo boolean;
begin
  select exists (
    select 1 from ssoma_levantamientos
    where racs_report_id = target_id and activo
  ) into hay_activo;

  update ssoma_racs_reports
  set estado = case when hay_activo then 'Levantado' else 'Pendiente' end::ssoma_estado_racs
  where id = target_id;

  return null;
end;
$$;

drop trigger if exists ssoma_levantamientos_sync_estado on ssoma_levantamientos;
create trigger ssoma_levantamientos_sync_estado
after insert or update or delete on ssoma_levantamientos
for each row execute function ssoma_sync_racs_estado();
