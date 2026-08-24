-- ============================================================
-- BLOQUE 13: Rol "Jefe/Coordinador" + objetivo semanal de RACS
--
-- Habilita el dashboard "Desempeño comparativo de supervisores /
-- jefes y coordinadores" del PDF original.
--
-- Decisiones confirmadas con el usuario:
-- - Los 4 jefes/coordinadores YA están en ssoma_personal (son las
--   mismas personas que ya observan/supervisan, con un rol extra):
--   MARLON VILLACORTA, RICALDI GALARZA NILTON ALEX,
--   ROMERO FLORES JORGE LUIS, SOTO RENGIFO FABIANI (= "Pablo
--   Fabbiani Soto" en la forma en que lo escribió el usuario;
--   mismo caso de escritura inconsistente ya documentado en
--   0001_ssoma_catalogos.sql).
-- - El objetivo semanal es FIJO por rol (no varía por persona ni
--   área), tal como se ve en el PDF: supervisor operativo = 2
--   actos + 2 condiciones; jefe/coordinador = 1 acto + 1 condición.
--   Se guarda en una tabla chica (ssoma_racs_objetivos_rol) en vez
--   de hardcodearlo en SQL, para poder ajustar los números después
--   sin una migración nueva.
-- ============================================================

alter table ssoma_personal
  add column if not exists puede_ser_jefe_coordinador boolean not null default false;

comment on column ssoma_personal.puede_ser_jefe_coordinador is 'Rol adicional a observador/supervisor: aparece en el dashboard de desempeño de Jefes y Coordinadores en vez del de Supervisores Operativos.';

update ssoma_personal set puede_ser_jefe_coordinador = true
where nombre_completo in (
  'MARLON VILLACORTA',
  'RICALDI GALARZA NILTON ALEX',
  'ROMERO FLORES JORGE LUIS',
  'SOTO RENGIFO FABIANI'
);

create table if not exists ssoma_racs_objetivos_rol (
  rol                 text primary key,   -- 'supervisor' | 'jefe_coordinador'
  objetivo_actos      integer not null,
  objetivo_condiciones integer not null,
  periodo             text not null default 'semanal',
  updated_at          timestamptz not null default now()
);

comment on table ssoma_racs_objetivos_rol is 'Cuota fija por rol para medir % de cumplimiento RACS (realizado / objetivo). Editable a mano sin migración si cambia la meta.';

insert into ssoma_racs_objetivos_rol (rol, objetivo_actos, objetivo_condiciones) values
  ('supervisor', 2, 2),
  ('jefe_coordinador', 1, 1)
on conflict (rol) do nothing;

alter table ssoma_racs_objetivos_rol enable row level security;

create policy ssoma_racs_objetivos_rol_select on ssoma_racs_objetivos_rol
  for select to anon, authenticated using (true);
