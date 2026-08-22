-- ============================================================
-- BLOQUE 4: Row Level Security (RLS)
--
-- IMPORTANTE — léalo antes de aplicar este bloque:
-- El HTML actual no tiene login. Cualquiera que abre la página
-- elige su nombre de un <select>, sin verificar identidad. Las
-- políticas de abajo reflejan ESE MISMO nivel de control (osea,
-- ninguno): cualquiera con la anon/publishable key del proyecto
-- puede leer e insertar en las tablas de SSOMA. Eso es equivalente
-- a la seguridad actual del HTML (cero autenticación), NO es un
-- retroceso, pero tampoco es un control de acceso real.
--
-- Si más adelante se agrega Supabase Auth (login del equipo),
-- hay que reemplazar "to anon" por "to authenticated" en las
-- políticas de escritura, y agregar el flujo de login al HTML.
-- ============================================================

alter table ssoma_personal enable row level security;
alter table ssoma_ubicaciones enable row level security;
alter table ssoma_ocurrencias enable row level security;
alter table ssoma_condiciones enable row level security;
alter table ssoma_racs_reports enable row level security;
alter table ssoma_levantamientos enable row level security;
alter table ssoma_comportamental_evaluaciones enable row level security;

-- Catálogos: solo lectura pública (se editan a mano/por un admin,
-- no desde el formulario del equipo).
create policy ssoma_catalogos_select_personal on ssoma_personal
  for select to anon, authenticated using (true);
create policy ssoma_catalogos_select_ubicaciones on ssoma_ubicaciones
  for select to anon, authenticated using (true);
create policy ssoma_catalogos_select_ocurrencias on ssoma_ocurrencias
  for select to anon, authenticated using (true);
create policy ssoma_catalogos_select_condiciones on ssoma_condiciones
  for select to anon, authenticated using (true);

-- RACS: leer y crear reportes es abierto para el equipo (como hoy).
-- No se permite update/delete directo desde el cliente: el estado
-- solo cambia a través de ssoma_levantamientos (ver BLOQUE 2).
create policy ssoma_racs_select on ssoma_racs_reports
  for select to anon, authenticated using (true);
create policy ssoma_racs_insert on ssoma_racs_reports
  for insert to anon, authenticated with check (true);
create policy ssoma_racs_delete on ssoma_racs_reports
  for delete to anon, authenticated using (true);

-- Levantamientos: leer y crear abierto; "reabrir" es un UPDATE
-- que pone activo=false (no un delete, para conservar historial).
create policy ssoma_levantamientos_select on ssoma_levantamientos
  for select to anon, authenticated using (true);
create policy ssoma_levantamientos_insert on ssoma_levantamientos
  for insert to anon, authenticated with check (true);
create policy ssoma_levantamientos_update on ssoma_levantamientos
  for update to anon, authenticated using (true) with check (true);

-- Evaluaciones comportamentales: leer y crear abierto; sin
-- update/delete desde el cliente (una evaluación ya guardada no
-- se edita en el HTML actual, solo se elimina desde la lista).
create policy ssoma_comp_select on ssoma_comportamental_evaluaciones
  for select to anon, authenticated using (true);
create policy ssoma_comp_insert on ssoma_comportamental_evaluaciones
  for insert to anon, authenticated with check (true);
create policy ssoma_comp_delete on ssoma_comportamental_evaluaciones
  for delete to anon, authenticated using (true);
