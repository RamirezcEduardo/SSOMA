-- ============================================================
-- BLOQUE 10: Acceso restringido a resultados de la encuesta
-- de charla de seguridad (mismo esquema que bloque 8: solo
-- jefatura y gestión humana, vía b2c_roles/b2c_permisos).
-- ============================================================

insert into b2c_permisos_catalogo (permiso, etiqueta, grupo, descripcion, orden) values
  ('view.encuesta-charla', 'Encuesta de Charla de Seguridad', 'SSOMA', 'Ver resultados anónimos de la encuesta de charlas de 5 minutos', 100)
on conflict (permiso) do nothing;

insert into b2c_permisos (rol, permiso)
select r, 'view.encuesta-charla' from unnest(array['admin','gerencia','rrhh']) as r
on conflict do nothing;

create or replace function public.ssoma_encuesta_charla_resultados(p_token text)
returns setof public.ssoma_encuesta_charla
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $function$
begin
  perform public.b2c_require_permiso(p_token, 'view.encuesta-charla');
  return query select * from public.ssoma_encuesta_charla order by created_at desc;
end;
$function$;

grant execute on function public.ssoma_encuesta_charla_resultados(text) to anon, authenticated;

comment on function public.ssoma_encuesta_charla_resultados is 'Devuelve todas las respuestas de la encuesta de charla de seguridad (anónimas) solo si el token pertenece a un rol con el permiso view.encuesta-charla (gerencia/rrhh/admin).';
