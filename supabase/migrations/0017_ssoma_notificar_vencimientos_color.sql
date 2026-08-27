-- Agrega el color ámbar (mismo lenguaje de color que "asignada"=rojo,
-- "finalizada"=verde) al recordatorio de vencimiento.
create or replace function public.ssoma_notificar_vencimientos()
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  t record;
  destinatarios bigint[];
begin
  for t in
    select id, titulo, destinatario_id, delegado_a_id
    from public.ssoma_tareas
    where finalizado_at is null
      and notificado_vencimiento = false
      and hora_limite is not null
      and ((fecha_limite + hora_limite) at time zone 'America/Lima') between now() and (now() + interval '20 minutes')
  loop
    destinatarios := array_remove(array[t.destinatario_id, t.delegado_a_id], null);
    if array_length(destinatarios, 1) > 0 then
      perform net.http_post(
        url := 'https://zlukrktpjffiycarpduc.supabase.co/functions/v1/ssoma-fcm-send',
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := jsonb_build_object(
          'usuario_ids', to_jsonb(destinatarios),
          'titulo', 'Tarea por vencer',
          'cuerpo', t.titulo || ' vence en 20 minutos',
          'datos', jsonb_build_object('tipo', 'tarea_por_vencer', 'tarea_id', t.id),
          'color', '#C4820F'
        )
      );
    end if;
    update public.ssoma_tareas set notificado_vencimiento = true where id = t.id;
  end loop;
end;
$$;
