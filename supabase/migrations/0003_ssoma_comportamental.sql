-- ============================================================
-- BLOQUE 3: Evaluaciones comportamentales (SST)
--
-- El checklist de 11 preguntas (COMP_PREGUNTAS en el HTML) casi
-- no cambia, así que se queda como constante en la app en vez de
-- una tabla catálogo -- pero se valida en la base de datos que
-- las respuestas jsonb solo usen esos 11 ids y valores SI/NO,
-- para que un bug en el front no meta datos corruptos.
--
-- Igual que en ssoma_racs_reports, el id es identity (nunca se
-- repite) y evc_code es la columna generada para mostrar
-- "EVC-0001" en la interfaz, corrigiendo el mismo bug de
-- nextCompId() que usaba compReports.length + 1.
-- ============================================================

create type ssoma_turno as enum ('Mañana', 'Tarde', 'Noche');

-- Postgres no permite subconsultas dentro de un CHECK constraint
-- directamente ("cannot use subquery in check constraint"), así
-- que la validación de "todos los valores son SI/NO" se mueve a
-- esta función y el constraint solo la invoca.
create or replace function ssoma_comp_respuestas_valores_ok(respuestas jsonb)
returns boolean
language sql
immutable
as $$
  select bool_and(v in ('SI', 'NO'))
  from jsonb_each_text(respuestas) as kv(k, v);
$$;

create table if not exists ssoma_comportamental_evaluaciones (
  id             bigint generated always as identity primary key,
  evc_code       text generated always as ('EVC-' || lpad(id::text, 4, '0')) stored,

  fecha          date not null,
  supervisor_id  bigint not null references ssoma_personal (id),
  colaborador    text not null,
  area           text not null,
  turno          ssoma_turno not null,
  sede           text not null,
  observaciones  text not null,

  -- claves fijas esperadas, en el mismo orden que COMP_PREGUNTAS del HTML:
  -- epp, espalda, ayudaPaletas, transpaleta, señales, orden,
  -- atencionCamino, reportaProactivo, conoceRiesgos, atencionTarea, feedback
  respuestas     jsonb not null,

  created_at     timestamptz not null default now(),

  constraint ssoma_comp_respuestas_keys_check check (
    respuestas ?& array[
      'epp','espalda','ayudaPaletas','transpaleta','señales','orden',
      'atencionCamino','reportaProactivo','conoceRiesgos','atencionTarea','feedback'
    ]
  ),
  constraint ssoma_comp_respuestas_values_check check (
    ssoma_comp_respuestas_valores_ok(respuestas)
  )
);

create index if not exists ssoma_comp_eval_turno_idx on ssoma_comportamental_evaluaciones (turno);
create index if not exists ssoma_comp_eval_fecha_idx on ssoma_comportamental_evaluaciones (fecha desc);
create index if not exists ssoma_comp_eval_supervisor_idx on ssoma_comportamental_evaluaciones (supervisor_id);

comment on table ssoma_comportamental_evaluaciones is 'Evaluaciones comportamentales SST (guía de observación + checklist de 11 preguntas SI/NO).';
comment on column ssoma_comportamental_evaluaciones.respuestas is 'jsonb {idPregunta: "SI"|"NO"} — las 11 claves son obligatorias, valores solo SI/NO.';

-- % de cumplimiento y aprobado/no aprobado (>=85%, igual que el HTML)
-- como función reutilizable, en vez de recalcularlo en cada query.
create or replace function ssoma_comp_pct_cumplimiento(respuestas jsonb)
returns numeric
language sql
immutable
as $$
  select round(
    100.0 * (
      select count(*) from jsonb_each_text(respuestas) as kv(k, v) where v = 'SI'
    ) / 11.0,
    0
  );
$$;
