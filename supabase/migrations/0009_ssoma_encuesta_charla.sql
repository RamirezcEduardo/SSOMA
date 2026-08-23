-- ============================================================
-- BLOQUE 9: Encuesta de charla de seguridad (5 minutos SST)
--
-- Mismo patrón que ssoma_encuesta_clima (bloque 6/7): anónima
-- (sin usuario, sin nombre), pero sí liga a un supervisor porque
-- el formulario original de Google pedía "Nombre del supervisor
-- evaluado". RLS: anon solo puede INSERTAR.
--
-- Preguntas fijas (numeradas igual que el Google Form original):
--   1 gusto        Sí | Más o menos | No
--   2 entendio      Sí | Más o menos | No
--   3 ayuda         Sí, mucho | Un poco | No
--   4 interes       Sí | Mas o menos | No
--   5 duracion      Están bien | Muy largas | Muy cortas
--   6 multimedia    SI | NO
--   7 comodidad     Sí | A veces | No
--   8 calificacion  Muy buenas | Buenas | Regulares | Malas
-- ============================================================

create table if not exists ssoma_encuesta_charla (
  id             bigint generated always as identity primary key,
  supervisor_id  bigint not null references ssoma_personal (id),
  respuestas     jsonb not null,
  created_at     timestamptz not null default now()
);

comment on table ssoma_encuesta_charla is 'Encuesta anónima sobre las charlas de 5 minutos de SST, ligada al supervisor evaluado.';
comment on column ssoma_encuesta_charla.respuestas is 'jsonb con las 8 preguntas fijas del Google Form original, ver ssoma_charla_respuestas_valores_ok.';

create or replace function ssoma_charla_respuestas_valores_ok(respuestas jsonb)
returns boolean
language sql
immutable
as $$
  select
    respuestas ?& array['gusto','entendio','ayuda','interes','duracion','multimedia','comodidad','calificacion']
    and respuestas->>'gusto' in ('Sí','Más o menos','No')
    and respuestas->>'entendio' in ('Sí','Más o menos','No')
    and respuestas->>'ayuda' in ('Sí, mucho','Un poco','No')
    and respuestas->>'interes' in ('Sí','Mas o menos','No')
    and respuestas->>'duracion' in ('Están bien','Muy largas','Muy cortas')
    and respuestas->>'multimedia' in ('SI','NO')
    and respuestas->>'comodidad' in ('Sí','A veces','No')
    and respuestas->>'calificacion' in ('Muy buenas','Buenas','Regulares','Malas');
$$;

alter table ssoma_encuesta_charla
  add constraint ssoma_charla_respuestas_check check (ssoma_charla_respuestas_valores_ok(respuestas));

create index if not exists ssoma_encuesta_charla_supervisor_idx on ssoma_encuesta_charla (supervisor_id);
create index if not exists ssoma_encuesta_charla_fecha_idx on ssoma_encuesta_charla (created_at desc);

alter table ssoma_encuesta_charla enable row level security;

create policy ssoma_encuesta_charla_insert on ssoma_encuesta_charla
  for insert to anon, authenticated
  with check (true);

-- Deliberadamente NO hay policy de select/update/delete para anon/authenticated,
-- igual que ssoma_encuesta_clima: solo se puede leer vía RPC con permiso (bloque 10).
