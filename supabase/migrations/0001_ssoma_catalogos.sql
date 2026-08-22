-- ============================================================
-- BLOQUE 1: Catálogos (listas desplegables del formulario)
--
-- Verificado contra los PDF originales de los Google Forms
-- ("REPORTE DE SEGURIDAD... RACS.pdf" y
-- "EVALUACION COMPORTAMENTAL.pdf"): todas las listas coinciden
-- exactamente con lo que ya había en el HTML.
--
-- CONSOLIDACIÓN DE PERSONAL (confirmada por el usuario 2026-08-22):
-- Las listas de "observadores" (Form RACS) y "supervisores" (Form
-- comportamental) tenían 14 personas escritas de forma distinta
-- entre una lista y otra (mismo individuo, distinto orden o nivel
-- de detalle en el nombre). Se unificaron en un solo directorio
-- (ssoma_personal) con roles, quedándose con el nombre más
-- completo de cada par. De paso se corrigieron 2 typos:
-- "CARILLO" -> "CARRILLO", "ISSAC" -> "ISAAC".
--
-- Pares fusionados (nombre descartado -> nombre canónico):
--   ACOSTA SANDOVAL JOSE            -> ACOSTA SANDOVAL JOSE RAMOS
--   SAAVEDRA KEVIN                  -> KEVIN SAAVEDRA CORDOVA
--   HUERE CAJAHUANCA CLINTON        -> HUERE CAJAHUANCA CLINTON LALO
--   SALINAS VELASQUEZ ELIZABETH     -> SALINAS VELASQUEZ ELIZABETH GREISSY
--   ORIHUELA PAUCAR EDGAR           -> ORIHUELA PAUCAR EDGAR EDWIN
--   OLAYA MONTALBAN DIANA           -> OLAYA MONTALBAN DIANA LISETH
--   ROJAS ALANYA JHOEL              -> ROJAS ALANYA JHOEL FELIPE
--   PACAYA IPUSHIMA YENELI          -> PACAYA IPUSHIMA YENELI LADIS
--   ROBERT ASTOCONDOR               -> ASTOCONDOR CHUAN ROBERT
--   SORALUZ SANTISTEBAN JOSE        -> SORALUZ SANTISTEBAN JOSE HERNAN
--   SALAS VARGAS ANDRES             -> SALAS VARGAS ANDRES ALBERTO
--   LLAULLIPOMA CARHUANCHO ISSAC    -> LLAULLIPOMA CARHUANCHO ISAAC HIMISAEL
--   CARILLO TRINIDAD JOSE           -> CARRILLO TRINIDAD JOSE
--   OMAR SAAVEDRA                   -> SAAVEDRA OMAR            (empate, sin criterio objetivo)
--   CARLOS TELLEZ                   -> TELLEZ CARLOS            (empate, sin criterio objetivo)
--
-- Si alguna de estas 15 fusiones resulta incorrecta, corríjala
-- directamente en ssoma_personal (UPDATE nombre_completo ...)
-- antes de que haya reportes reales apuntando a ese id.
-- ============================================================

create table if not exists ssoma_personal (
  id                bigint generated always as identity primary key,
  nombre_completo   text not null unique,
  puede_observar    boolean not null default false,   -- puede aparecer en el form RACS
  puede_supervisar  boolean not null default false,    -- puede aparecer en el form comportamental
  activo            boolean not null default true,
  created_at        timestamptz not null default now()
);

comment on table ssoma_personal is 'Directorio único de personal SSOMA. Antes eran dos catálogos separados (observadores/supervisores) con nombres inconsistentes entre sí; ver historial de fusión arriba.';

create table if not exists ssoma_ubicaciones (
  id           bigint generated always as identity primary key,
  nombre       text not null unique,
  activo       boolean not null default true,
  created_at   timestamptz not null default now()
);

create table if not exists ssoma_ocurrencias (
  id           bigint generated always as identity primary key,
  descripcion  text not null unique,
  activo       boolean not null default true,
  created_at   timestamptz not null default now()
);

create table if not exists ssoma_condiciones (
  id           bigint generated always as identity primary key,
  descripcion  text not null unique,
  activo       boolean not null default true,
  created_at   timestamptz not null default now()
);

comment on table ssoma_ubicaciones is 'Zonas/áreas del centro de distribución donde puede ocurrir un hallazgo.';
comment on table ssoma_ocurrencias is 'Catálogo de "Acto sub estándar" (incluye la opción Otros (Especificar)).';
comment on table ssoma_condiciones is 'Catálogo de "Condición sub estándar" (incluye la opción Otros (Especificar)).';

-- ============================================================
-- Semilla: 31 personas únicas resultantes de fusionar las 28
-- entradas de "observadores" + 29 de "supervisores".
-- ============================================================

insert into ssoma_personal (nombre_completo, puede_observar, puede_supervisar) values
  ('ACOSTA SANDOVAL JOSE RAMOS', true, true),
  ('ALFARO YANQUI MIGUEL ANGEL', true, true),
  ('ASTOCONDOR CHUAN ROBERT', true, true),
  ('GASPAR ROJAS ALEXIS', true, true),
  ('HUERE CAJAHUANCA CLINTON LALO', true, true),
  ('LAVADO CASTRO JOSE LUIS', true, true),
  ('LLAULLIPOMA CARHUANCHO ISAAC HIMISAEL', true, true),
  ('OLAYA MONTALBAN DIANA LISETH', true, true),
  ('ORIHUELA PAUCAR EDGAR EDWIN', true, true),
  ('PACAYA IPUSHIMA YENELI LADIS', true, true),
  ('RICALDI GALARZA NILTON ALEX', true, true),
  ('ROJAS ALANYA JHOEL FELIPE', true, true),
  ('RUIZ MISARI CRISTIAN', true, true),
  ('KEVIN SAAVEDRA CORDOVA', true, true),
  ('SAAVEDRA OMAR', true, true),
  ('SALAS VARGAS ANDRES ALBERTO', true, true),
  ('SALINAS VELASQUEZ ELIZABETH GREISSY', true, true),
  ('SORALUZ SANTISTEBAN JOSE HERNAN', true, true),
  ('ZELADA MEJIA LUIS HOMERO', true, true),
  ('BRUCE LOPEZ TOLEDANO', true, true),
  ('PEDRO CHARCA CHOQUEMAMANI', true, true),
  ('CARRILLO TRINIDAD JOSE', true, true),
  ('TELLEZ CARLOS', true, true),
  ('RODRÍGUEZ VIDAURRE ELKY ALDAIR', true, true),
  ('CARLOS LEO YALLE', true, true),
  -- solo observador (no aparecían en la lista de supervisores)
  ('LOPEZ TODELANO BRUCE WALTER', true, false),
  ('ROMERO FLORES JORGE LUIS', true, false),
  ('SALCEDO TOMAYCONZA ANDERSON', true, false),
  -- solo supervisor (no aparecían en la lista de observadores)
  ('VENTOCILLA CALDERON JOSE MIGUEL', false, true),
  ('MARLON VILLACORTA', false, true),
  ('SOTO RENGIFO FABIANI', false, true)
on conflict (nombre_completo) do nothing;

insert into ssoma_ubicaciones (nombre) values
  ('KNAPP P1'),
  ('KNAPP P2'),
  ('KNAPP ZONA DE BANDEJAS 45-50'),
  ('KANAP P 2 - OFICINAS'),
  ('ALMACEN DA (TRILATERALES) PASILLO 1- 11'),
  ('ALMACEN BA 3PL (TRILATERALES) PASILLO 1- 10'),
  ('ALMACEN CA (PAMPON - CT ESTE) / MZ 1- MZ 2'),
  ('MEZZANINE 1- PISO 1'),
  ('MEZZANINE 1- PISO 2'),
  ('MEZZANINE 1 - PISO 3'),
  ('MEZZANINE 1- PISO 4'),
  ('MEZZANINE 2 - PISO 1'),
  ('MEZZANINE 2 - PISO 2'),
  ('MEZZANINE 2 - PISO 3'),
  ('MEZZANINE 2 - PISO 4'),
  ('ESTANTERIA PISO 1 (VIDRIOS FARMA Y CONTROLADOS)'),
  ('ESTANTERIA PISO 2 (CONSUMO Y ALIMENTOS)'),
  ('DESPACHO B2B PUERTAS 29-35'),
  ('DESPACHO B2C PUERTAS 13-28'),
  ('LOGISTICA INVERSA (PUERTA 9- 10)'),
  ('3PL INBOUND PUERTAS 1 - 9'),
  ('3PL OUTBOUND - NAVE DE SALDOS PISO 1 - PISO 2'),
  ('RECEPCIÓN PUERTAS 36-44'),
  ('MANTENIMIENTO (ESPALDA DEL COMEDOR)'),
  ('ZONA DE ESTACIONAMIENTO'),
  ('PATIO DE MANIOBRAS'),
  ('ZONA DE CARGA DE BATERIAS'),
  ('CAMARA FRÍA'),
  ('PUERTA 36'),
  ('PUERTA 09'),
  ('SS.HH VARONES - (ESPECIFICAR)'),
  ('SSHH DAMAS - (ESPECIFICAR)'),
  ('ESTACIONAMIENTO')
on conflict (nombre) do nothing;

insert into ssoma_ocurrencias (descripcion) values
  ('Manejo de equipos /vehículos sin autorización'),
  ('Manejo de equipos móviles a velocidad inadecuada'),
  ('Uso de equipos / herramientas defectuosos'),
  ('Desactivar / retirar dispositivos / guardas de seguridad'),
  ('Usar inadecuadamente / no uso de EPP'),
  ('Manipulacion/almacenamiento de carga inadecuada'),
  ('Dar servicio / Intervenir equipos en funcionamiento'),
  ('Juguetear o bromear en el trabajo'),
  ('Trabajar bajo la influencia de alcohol y drogas.'),
  ('No señalizar / delimitar el lugar de trabajo'),
  ('Inasistencia de Charla de 5 minutos.'),
  ('Descanso inadecuado en área de riesgo'),
  ('Caminar usando el celular'),
  ('Uso inadecuado del sendero peatonal'),
  ('Otros (Especificar)')
on conflict (descripcion) do nothing;

insert into ssoma_condiciones (descripcion) values
  ('Guardas o barreras de seguridad inadecuadas'),
  ('Equipos / máquinas / herramientas defectuosos'),
  ('Señalización / Sistema de advertencia inadecuado'),
  ('Falta de orden y limpieza / desorden'),
  ('Niveles de ruido excesivo'),
  ('Presencia de material particulado en el ambiente'),
  ('Bloqueo de accesos / Bloqueo de equipos de emergencia'),
  ('Filtraciones / aniego'),
  ('Riesgos eléctricos / Cables Expuestos'),
  ('Pisos desnivelados / huecos / aberturas'),
  ('Mercadería que sobresalen'),
  ('Extintores vencidos / no se cuenta extintor'),
  ('Paletas con presencia de clavos / mal estado'),
  ('Paletas mal apilada / mal ubicada / exceden 10 unid.'),
  ('Otros (Especificar)')
on conflict (descripcion) do nothing;
