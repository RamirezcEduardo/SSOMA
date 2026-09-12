-- Se retira el módulo "Auditoría Bultos Perdidos" (mismo tratamiento que Sin Ubicación,
-- migración 0039) — Eduardo va a rediseñar el flujo desde cero. Incluye 448 casos reales
-- y 420 verificaciones ya cargados, confirmado con Eduardo antes de borrar.
drop table if exists ssoma_bp_verificaciones;
drop table if exists ssoma_bp_registros;
