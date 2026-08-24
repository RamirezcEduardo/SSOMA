-- ============================================================
-- BLOQUE 11: Encuesta de charla de seguridad — escala 1 a 10
--
-- Cambia el formato de respuesta de 6 de las 8 preguntas (las que
-- miden intensidad: gusto, entendio, ayuda, interes, comodidad,
-- calificacion) de opciones de texto a una escala numérica 1-10,
-- para poder calcular promedios reales por pregunta y por
-- supervisor en vez de solo distribución por texto.
--
-- "duracion" y "multimedia" se quedan como texto de opción fija:
-- miden una dirección/preferencia, no una intensidad, así que un
-- promedio 1-10 no aporta información (se seguirían resumiendo
-- como % por opción, igual que antes).
--
-- Tabla vacía (0 respuestas reales al momento de este cambio), así
-- que no hace falta migrar datos existentes.
-- ============================================================

create or replace function ssoma_charla_respuestas_valores_ok(respuestas jsonb)
returns boolean
language sql
immutable
as $$
  select
    respuestas ?& array['gusto','entendio','ayuda','interes','duracion','multimedia','comodidad','calificacion']
    and jsonb_typeof(respuestas->'gusto') = 'number' and (respuestas->>'gusto')::numeric between 1 and 10
    and jsonb_typeof(respuestas->'entendio') = 'number' and (respuestas->>'entendio')::numeric between 1 and 10
    and jsonb_typeof(respuestas->'ayuda') = 'number' and (respuestas->>'ayuda')::numeric between 1 and 10
    and jsonb_typeof(respuestas->'interes') = 'number' and (respuestas->>'interes')::numeric between 1 and 10
    and jsonb_typeof(respuestas->'comodidad') = 'number' and (respuestas->>'comodidad')::numeric between 1 and 10
    and jsonb_typeof(respuestas->'calificacion') = 'number' and (respuestas->>'calificacion')::numeric between 1 and 10
    and respuestas->>'duracion' in ('Están bien','Muy largas','Muy cortas')
    and respuestas->>'multimedia' in ('Sí','No');
$$;

comment on column ssoma_encuesta_charla.respuestas is 'jsonb con las 8 preguntas fijas: gusto/entendio/ayuda/interes/comodidad/calificacion son enteros 1-10, duracion/multimedia son texto de opción fija. Ver ssoma_charla_respuestas_valores_ok.';
