-- ============================================================
-- BLOQUE 29: Detalle y disputas de la auditoría — Control de Bolsa
--
-- La tabla base ya existía (aplicada directamente contra la base
-- en una sesión anterior, sin dejar este archivo) pero el
-- frontend nunca llegó a usarla: el import de "Control de Bolsa"
-- solo guardaba el respaldo del WMS (bloque 28) y armaba las
-- líneas de la auditoría y sus disputas (Disputar/Descartar/
-- Aceptar) en un array de JavaScript en memoria — se perdía todo
-- al recargar la página. Este bloque documenta el esquema tal
-- cual está hoy en producción (incluida la constraint única que
-- se agregó ahora para poder reimportar sin duplicar) y conecta
-- el import + los cambios de estado al guardado real.
-- ============================================================

do $$ begin
  if not exists (select 1 from pg_type where typname = 'ssoma_bolsa_estado_disputa') then
    create type ssoma_bolsa_estado_disputa as enum ('sin_revisar', 'en_disputa', 'descartado', 'aceptado');
  end if;
end $$;

create table if not exists ssoma_bolsa_auditoria_lineas (
  id                bigint generated always as identity primary key,

  fecha             date not null,
  semana            text,
  mes               text,
  trimestre         text,
  cd_nombre         text,

  cod_producto      text not null,
  producto          text not null,
  familia           text,
  cantidad          numeric,
  costo_unit        numeric,
  cant_reversada    numeric,
  monto_reversado   numeric not null,
  ubicacion         text,
  area              text,
  origen            text,

  tipo              text not null,
  motivo_op         text not null,
  trans_ref         text,
  trans_user        text,

  considera         boolean not null,
  estado_disputa    ssoma_bolsa_estado_disputa not null default 'sin_revisar',
  sustento          text,
  evidencia         jsonb not null default '[]'::jsonb,

  archivo_origen    text,
  importado_en      timestamptz not null default now(),
  created_at        timestamptz not null default now(),

  constraint ssoma_bolsa_auditoria_disputa_sustento_check
    check (estado_disputa = 'sin_revisar' or sustento is not null),
  constraint ssoma_bolsa_auditoria_evidencia_array_check
    check (jsonb_typeof(evidencia) = 'array'),
  -- Permite reimportar el mismo reporte del auditor sin duplicar líneas
  -- (upsert con ignoreDuplicates en el cliente) — así una línea ya marcada
  -- en disputa/descartada/aceptada no se resetea a "sin revisar" al subir
  -- de nuevo el mismo archivo o uno que repite semanas ya cargadas.
  constraint ssoma_bolsa_auditoria_lineas_natural_key
    unique (fecha, cod_producto, tipo, motivo_op, monto_reversado, ubicacion)
);

comment on table ssoma_bolsa_auditoria_lineas is 'Detalle línea por línea del reporte de diferencias que manda el área auditora cada trimestre (ej. Dif Santa Anita).';

alter table ssoma_bolsa_auditoria_lineas enable row level security;

create policy ssoma_bolsa_auditoria_select on ssoma_bolsa_auditoria_lineas for select using (true);
create policy ssoma_bolsa_auditoria_insert on ssoma_bolsa_auditoria_lineas for insert with check (true);
create policy ssoma_bolsa_auditoria_update on ssoma_bolsa_auditoria_lineas for update using (true) with check (true);
