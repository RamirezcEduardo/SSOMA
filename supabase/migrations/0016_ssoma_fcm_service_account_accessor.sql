-- Accede a la clave de la cuenta de servicio de Firebase (FCM) guardada en
-- Supabase Vault (secreto 'fcm_service_account_json', creado aparte — nunca
-- se guarda en texto plano en el repo ni en un archivo de migración).
-- Solo el rol service_role puede ejecutarla; la usa la función edge
-- ssoma-fcm-send con la service role key.
create or replace function public.ssoma_get_fcm_service_account()
returns text
language sql
security definer
set search_path = vault, public
as $$
  select decrypted_secret from vault.decrypted_secrets where name = 'fcm_service_account_json' limit 1;
$$;

revoke all on function public.ssoma_get_fcm_service_account() from public;
revoke all on function public.ssoma_get_fcm_service_account() from anon, authenticated;
grant execute on function public.ssoma_get_fcm_service_account() to service_role;
