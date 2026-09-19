-- ============================================================
-- BLOQUE 58: Inbound → Programación de Contenedores
--
-- El equipo de COMEX (de Farmacias Peruanas, el CLIENTE — no tiene ni
-- va a tener acceso a SSOMA) manda todos los viernes un Excel rústico
-- con la programación de llegadas: una fila por embarque, y columnas
-- de fecha (una por día, saltando domingos) donde ponen cuántos
-- contenedores o pallets llegan ese día. El formato de la columna
-- "CTN-Pallet" es texto libre e inconsistente ("2X40HC", "3 pallets",
-- "1 PALLET", etc.) — en vez de parsear ese texto, se les da un
-- formulario público (programacion-comex.html, sin login, mismo
-- patrón que encuesta-clima.html/encuesta-charla-seguridad.html) para
-- que carguen la programación de la semana ellos mismos, con el tipo
-- de carga ya estructurado (contenedor vs. carga suelta) en vez de
-- texto libre.
--
-- Quien llena el formulario se identifica con DNI/correo/área (no es
-- una cuenta de SSOMA, solo trazabilidad de quién cargó cada fila).
--
-- Una fila = un día de entrega de un embarque (igual que una columna
-- del Excel) — un mismo BL/embarque que llega repartido en varios
-- días se carga como varias filas con la misma info y distinta
-- fecha_entrega/cantidad.
-- ============================================================

create table if not exists ssoma_inbound_programacion_contenedores (
  id                      bigint generated always as identity primary key,

  registrado_por_dni      text not null,
  registrado_por_correo   text not null,
  registrado_por_area     text not null,

  via                     text,
  bl                      text,
  oc_hija                 text,
  proveedor               text,
  linea                   text,
  eta                     date,
  sobrestadia             date,
  agencia                 text,
  lpns                    numeric,

  tipo_carga              text not null check (tipo_carga in ('contenedor', 'carga_suelta')),
  tipo_contenedor         text,
  cantidad                numeric not null,

  fecha_entrega           date not null,

  estado                  text not null default 'pendiente' check (estado in ('pendiente', 'recibido')),
  recibido_en             timestamptz,
  recibido_por_id         bigint,

  created_at              timestamptz not null default now()
);

comment on table ssoma_inbound_programacion_contenedores is 'Programación de llegadas de contenedores/carga suelta cargada por COMEX (cliente, sin acceso a SSOMA) vía formulario público programacion-comex.html. Una fila = un día de entrega de un embarque.';
comment on column ssoma_inbound_programacion_contenedores.tipo_carga is 'contenedor | carga_suelta — reemplaza el texto libre "CTN-Pallet" del Excel rústico de COMEX por un dato estructurado.';
comment on column ssoma_inbound_programacion_contenedores.cantidad is 'Cantidad de contenedores (si tipo_carga=contenedor) o de pallets (si tipo_carga=carga_suelta) que llegan en fecha_entrega.';

create index if not exists ssoma_inbound_prog_cont_fecha_idx on ssoma_inbound_programacion_contenedores (fecha_entrega);
create index if not exists ssoma_inbound_prog_cont_estado_idx on ssoma_inbound_programacion_contenedores (estado);

alter table ssoma_inbound_programacion_contenedores enable row level security;

create policy ssoma_inbound_prog_cont_select on ssoma_inbound_programacion_contenedores
  for select to anon, authenticated using (true);
create policy ssoma_inbound_prog_cont_insert on ssoma_inbound_programacion_contenedores
  for insert to anon, authenticated with check (true);
create policy ssoma_inbound_prog_cont_update on ssoma_inbound_programacion_contenedores
  for update to anon, authenticated using (true);
create policy ssoma_inbound_prog_cont_delete on ssoma_inbound_programacion_contenedores
  for delete to anon, authenticated using (true);
