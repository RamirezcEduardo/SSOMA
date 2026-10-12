-- Sin Ubicación: otras ubicaciones del almacén donde el MISMO Cod Alternat
-- tiene stock ahora mismo (export "ActiveInventory" del WMS), para que el
-- equipo sepa dónde más buscar o de dónde abastecerse mientras se resuelve
-- el pendiente. Array jsonb de {ubicacion, cantidad}, vinculado por Cod
-- Alternat (no por LPN ni Nro Grupo — este export no trae esos campos).
alter table public.ssoma_bpo_registros add column if not exists otras_ubicaciones jsonb;
