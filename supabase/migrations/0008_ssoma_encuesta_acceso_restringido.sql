-- ============================================================
-- BLOQUE 8: Acceso restringido a resultados de la encuesta
-- de clima laboral (solo jefatura y gestión humana)
--
-- Se suma al sistema de roles/permisos que ya existe (b2c_roles,
-- b2c_permisos_catalogo, b2c_permisos, b2c_require_permiso) en
-- vez de crear uno nuevo:
--   - Permiso nuevo: view.encuesta-clima
--   - Se otorga a "gerencia" (jefatura) y a un rol nuevo "rrhh"
--     (gestión humana) que SOLO tiene este permiso — así RRHH no
--     obtiene de paso acceso al dashboard operativo del WMS.
--   - "admin" también lo recibe, como el resto de permisos.
--
-- La tabla ssoma_encuesta_clima sigue sin policy de SELECT para
-- anon/authenticated (nadie puede leerla por la API directamente,
-- ver bloque 0006). El único camino de lectura es la función
-- ssoma_encuesta_resultados(token), que exige el permiso antes de
-- devolver cualquier fila. La encuesta se mantiene anónima (sin
-- nombre) para quien la conteste; esto solo controla QUIÉN puede
-- ver el resultado agregable (jefatura/RRHH), no agrega
-- identificación a las respuestas.
-- ============================================================

insert into b2c_roles (rol, descripcion, orden) values
  ('rrhh', 'Gestión Humana — solo resultados de la encuesta de clima laboral', 6)
on conflict (rol) do nothing;

insert into b2c_permisos_catalogo (permiso, etiqueta, grupo, descripcion, orden) values
  ('view.encuesta-clima', 'Encuesta de Clima Laboral', 'SSOMA', 'Ver resultados anónimos de la encuesta de clima laboral', 99)
on conflict (permiso) do nothing;

insert into b2c_permisos (rol, permiso)
select r, 'view.encuesta-clima' from unnest(array['admin','gerencia','rrhh']) as r
on conflict do nothing;

create or replace function public.ssoma_encuesta_resultados(p_token text)
returns setof public.ssoma_encuesta_clima
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $function$
begin
  perform public.b2c_require_permiso(p_token, 'view.encuesta-clima');
  return query select * from public.ssoma_encuesta_clima order by created_at desc;
end;
$function$;

grant execute on function public.ssoma_encuesta_resultados(text) to anon, authenticated;

comment on function public.ssoma_encuesta_resultados is 'Devuelve todas las respuestas de la encuesta de clima (anónimas, sin nombre) solo si el token de sesión pertenece a un rol con el permiso view.encuesta-clima (gerencia/rrhh/admin).';
