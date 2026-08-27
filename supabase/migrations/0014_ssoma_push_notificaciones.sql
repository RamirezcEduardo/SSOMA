-- Notificaciones push para la app móvil (Designación de Tareas).
-- Un token de dispositivo pertenece a un solo usuario a la vez; si el mismo
-- dispositivo se reinstala o cambia de usuario, el upsert por token lo reasigna.
create table if not exists public.ssoma_push_tokens (
  id bigint generated always as identity primary key,
  usuario_id bigint not null,
  token text not null unique,
  plataforma text not null default 'android',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists ssoma_push_tokens_usuario_id_idx on public.ssoma_push_tokens (usuario_id);

alter table public.ssoma_push_tokens enable row level security;

-- Mismo modelo de acceso permisivo que el resto de ssoma_tareas: esta app no usa
-- Supabase Auth, la sesión es un token propio (b2c_sessions), así que el control
-- de acceso real ocurre en la capa de la aplicación, no en RLS.
drop policy if exists ssoma_push_tokens_select on public.ssoma_push_tokens;
create policy ssoma_push_tokens_select on public.ssoma_push_tokens for select using (true);
drop policy if exists ssoma_push_tokens_insert on public.ssoma_push_tokens;
create policy ssoma_push_tokens_insert on public.ssoma_push_tokens for insert with check (true);
drop policy if exists ssoma_push_tokens_update on public.ssoma_push_tokens;
create policy ssoma_push_tokens_update on public.ssoma_push_tokens for update using (true);
drop policy if exists ssoma_push_tokens_delete on public.ssoma_push_tokens;
create policy ssoma_push_tokens_delete on public.ssoma_push_tokens for delete using (true);

grant select, insert, update, delete on public.ssoma_push_tokens to anon, authenticated;
grant usage on sequence ssoma_push_tokens_id_seq to anon, authenticated;

-- Evita reenviar el recordatorio "por vencer" cada vez que corre el cron.
alter table public.ssoma_tareas add column if not exists notificado_vencimiento boolean not null default false;
