-- ============================================================
-- BLOQUE 31: Nro Grupo en Short Pick — el join real con "Estado de pedidos"
--
-- El "Nro Orden" de la hoja "Data Short pick" del WMS viene SIEMPRE vacío
-- (confirmado contra la plantilla real SP_DIARIO_PLANTILLA: 0 de 1604 filas
-- lo traían) — Proceso/Sub Proceso y el cruce con "Estado de pedidos"
-- dependían de esa columna y por eso nunca funcionaron (Proceso salía
-- siempre "—", Estado de pedidos nunca aplicaba). El "Nro Grupo" sí viene
-- siempre poblado y es el que de verdad correlaciona cada línea de Data
-- Short pick con su pedido real en la hoja Filtro (Estado de pedidos) — se
-- guarda para poder resolver Nro Orden a través de él en vez de leerlo
-- directo (que nunca trae nada).
-- ============================================================

alter table ssoma_sp_registros add column if not exists nro_grupo text;
create index if not exists ssoma_sp_registros_nro_grupo_idx on ssoma_sp_registros (nro_grupo);
