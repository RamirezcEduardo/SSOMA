-- Tareas semanales: un avance por día (lunes a sábado obligatorio, domingo
-- opcional) en vez de una sola fecha límite puntual. La tarea se cierra sola
-- al terminar la semana. También: comentario opcional al finalizar cualquier
-- tarea (semanal o normal).
alter table public.ssoma_tareas add column if not exists es_semanal boolean not null default false;
alter table public.ssoma_tareas add column if not exists semana_inicio date;
alter table public.ssoma_tareas add column if not exists comentario_cierre text;

create table if not exists public.ssoma_tareas_avances (
  id bigint generated always as identity primary key,
  tarea_id bigint not null references public.ssoma_tareas(id) on delete cascade,
  fecha date not null,
  nota text not null,
  archivo jsonb,
  creado_por_id bigint not null,
  created_at timestamptz not null default now(),
  unique (tarea_id, fecha)
);

create index if not exists ssoma_tareas_avances_tarea_id_idx on public.ssoma_tareas_avances (tarea_id);

alter table public.ssoma_tareas_avances enable row level security;

drop policy if exists ssoma_tareas_avances_select on public.ssoma_tareas_avances;
create policy ssoma_tareas_avances_select on public.ssoma_tareas_avances for select using (true);
drop policy if exists ssoma_tareas_avances_insert on public.ssoma_tareas_avances;
create policy ssoma_tareas_avances_insert on public.ssoma_tareas_avances for insert with check (true);
drop policy if exists ssoma_tareas_avances_update on public.ssoma_tareas_avances;
create policy ssoma_tareas_avances_update on public.ssoma_tareas_avances for update using (true);
drop policy if exists ssoma_tareas_avances_delete on public.ssoma_tareas_avances;
create policy ssoma_tareas_avances_delete on public.ssoma_tareas_avances for delete using (true);

grant select, insert, update, delete on public.ssoma_tareas_avances to anon, authenticated;
grant usage on sequence ssoma_tareas_avances_id_seq to anon, authenticated;

-- Cierre automático: la semana termina el domingo a las 23:59 (America/Lima);
-- desde el lunes siguiente a las 00:00 la tarea semanal se da por finalizada
-- con lo que se haya reportado, igual que el recordatorio de vencimiento.
create or replace function public.ssoma_cerrar_semanas()
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  update public.ssoma_tareas
  set finalizado_at = now()
  where es_semanal = true
    and finalizado_at is null
    and semana_inicio is not null
    and ((semana_inicio + 7) at time zone 'America/Lima') <= now();
end;
$$;

select cron.unschedule(jobid) from cron.job where jobname = 'ssoma-cerrar-semanas';
select cron.schedule('ssoma-cerrar-semanas', '*/15 * * * *', $$select public.ssoma_cerrar_semanas();$$);
