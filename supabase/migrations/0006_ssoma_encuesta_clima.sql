-- ============================================================
-- BLOQUE 6: Encuesta de clima laboral (anónima)
--
-- A propósito NO tiene ninguna columna que identifique a quien
-- responde: sin usuario, sin sesión, sin observador_id, sin
-- nombre. Solo "turno" como dato demográfico amplio (3 valores,
-- muchas personas por turno) para poder ver tendencias sin
-- arriesgar identificar a alguien. No se pidió "área" a propósito:
-- cruzada con turno, en equipos chicos podría acotar demasiado
-- quién respondió.
--
-- RLS: anon solo puede INSERTAR, no puede leer NADA de vuelta.
-- Así, aunque alguien inspeccione la clave pública del sitio, no
-- puede consultar las respuestas de otros. Para ver resultados
-- hay que entrar por el SQL Editor / dashboard de Supabase con
-- una cuenta con acceso al proyecto (bypassa RLS).
-- ============================================================

create table if not exists ssoma_encuesta_clima (
  id             bigint generated always as identity primary key,
  turno          text,                     -- 'Mañana' | 'Tarde' | 'Noche' | null (opcional)
  respuestas     jsonb not null,           -- {"liderazgo_1": 4, "comunicacion_1": 5, ...} valores 1-5
  comentarios    text,
  created_at     timestamptz not null default now()
);

comment on table ssoma_encuesta_clima is 'Encuesta de clima laboral anónima. Sin ninguna columna identificable a propósito.';
comment on column ssoma_encuesta_clima.respuestas is 'jsonb {idPregunta: 1-5}, ver catálogo de preguntas en encuesta-clima.html (ENCUESTA_PREGUNTAS).';

alter table ssoma_encuesta_clima enable row level security;

create policy ssoma_encuesta_clima_insert on ssoma_encuesta_clima
  for insert to anon, authenticated
  with check (true);

-- Deliberadamente NO hay policy de select/update/delete para anon/authenticated:
-- eso bloquea por completo la lectura vía API pública, incluso para quien
-- tenga la clave publishable del sitio.
