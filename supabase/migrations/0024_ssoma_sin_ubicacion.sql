-- ============================================================
-- BLOQUE 24: Inventario — Auditoría Sin Ubicación
--
-- Mismo patrón que ssoma_sp_registros/ssoma_sp_verificaciones
-- (migración 0019_ssoma_shortpick_registros_y_verificaciones) y
-- ssoma_bp_registros/ssoma_bp_verificaciones (0023, BLOQUE 23):
-- registros importados aparte de las verificaciones;
-- sin fila en verificaciones = "Por buscar", con fila = "Ubicado".
--
-- Fuente: hoja "DATA" del archivo semanal de Sin Ubicación —
-- mercadería en la ubicación especial "SIN-UBICACION-..." del WMS.
--
-- La verificación acá SÍ pide la ubicación real encontrada
-- (equivalente al "Ubic Activo" de la hoja BITACORA que ya llevan
-- a mano) — es el dato clave que prueba que el producto sí está
-- ubicado, a diferencia de Bultos Perdidos donde alcanza con el
-- sustento en texto.
-- ============================================================

create table if not exists ssoma_su_registros (
  id                bigint generated always as identity primary key,

  fecha_crea        timestamptz not null,
  nro_lpn           text not null,
  cod_alternat      text not null,
  codigo_barras     text,                 -- columna "Producto" del export (EAN), igual que en Shortpick/Bultos Perdidos
  descripcion       text not null,
  ubicacion         text not null,        -- la ubicación especial "SIN-UBICACION-..." donde quedó
  cantidad          integer not null,

  area              text,
  semana            text,
  mes               text,
  motivo            text,                 -- "POR BUSCAR" u otro, tal como viene del WMS

  valorizado        numeric,

  creado_por_id     bigint,
  created_at        timestamptz not null default now()
);

comment on table ssoma_su_registros is 'Mercadería en ubicación especial "SIN-UBICACION-..." importada de la hoja DATA del archivo semanal de Sin Ubicación.';
comment on column ssoma_su_registros.codigo_barras is 'Columna "Producto" del export — es el código de barras/EAN, no el nombre del producto.';

create table if not exists ssoma_su_verificaciones (
  id                    bigint generated always as identity primary key,
  registro_id           bigint not null references ssoma_su_registros (id) on delete cascade,

  ubicacion_encontrada  text not null,     -- el "Ubic Activo" real hallado en Historial Inventario
  sustento              text not null,     -- observación (ej. "quiebre reabasto"), igual que la columna OBSERVACION de tu Bitácora
  foto                  jsonb,             -- {nombre, tipo, contenido(base64)} — opcional

  verificado_por_id     bigint,
  fecha                 timestamptz not null default now(),

  unique (registro_id)
);

comment on table ssoma_su_verificaciones is 'Conciliación de cada caso — reemplaza tu hoja BITACORA en Excel. Es la bitácora que usa Control de Bolsa para disputar AJUSTE SIN UBICACION.';

alter table ssoma_su_registros enable row level security;
alter table ssoma_su_verificaciones enable row level security;

create policy ssoma_su_registros_select on ssoma_su_registros
  for select to anon, authenticated using (true);
create policy ssoma_su_registros_insert on ssoma_su_registros
  for insert to anon, authenticated with check (true);
create policy ssoma_su_registros_update on ssoma_su_registros
  for update to anon, authenticated using (true);
create policy ssoma_su_registros_delete on ssoma_su_registros
  for delete to anon, authenticated using (true);

create policy ssoma_su_verificaciones_select on ssoma_su_verificaciones
  for select to anon, authenticated using (true);
create policy ssoma_su_verificaciones_insert on ssoma_su_verificaciones
  for insert to anon, authenticated with check (true);
create policy ssoma_su_verificaciones_update on ssoma_su_verificaciones
  for update to anon, authenticated using (true);
create policy ssoma_su_verificaciones_delete on ssoma_su_verificaciones
  for delete to anon, authenticated using (true);
