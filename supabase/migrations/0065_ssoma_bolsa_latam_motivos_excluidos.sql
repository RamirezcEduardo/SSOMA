-- Bolsa LATAM: permite marcar ciertos "Motivo OP" como excluidos del cálculo
-- (ej. ajustes que el auditor no te cobra) — las transacciones con un motivo
-- excluido no cuentan en el Neto real ni en Top Críticos/Sobrantes, aunque
-- sigan guardadas en ssoma_bolsa_latam_lineas tal cual las trajo el import.
create table if not exists public.ssoma_bolsa_latam_motivos_excluidos (
  id bigint generated always as identity primary key,
  motivo text not null unique,
  creado_por_id bigint,
  created_at timestamptz not null default now()
);

alter table public.ssoma_bolsa_latam_motivos_excluidos enable row level security;
drop policy if exists ssoma_bolsa_latam_motivos_excluidos_select on public.ssoma_bolsa_latam_motivos_excluidos;
create policy ssoma_bolsa_latam_motivos_excluidos_select on public.ssoma_bolsa_latam_motivos_excluidos for select using (true);
drop policy if exists ssoma_bolsa_latam_motivos_excluidos_insert on public.ssoma_bolsa_latam_motivos_excluidos;
create policy ssoma_bolsa_latam_motivos_excluidos_insert on public.ssoma_bolsa_latam_motivos_excluidos for insert with check (true);
drop policy if exists ssoma_bolsa_latam_motivos_excluidos_delete on public.ssoma_bolsa_latam_motivos_excluidos;
create policy ssoma_bolsa_latam_motivos_excluidos_delete on public.ssoma_bolsa_latam_motivos_excluidos for delete using (true);

grant select, insert, delete on public.ssoma_bolsa_latam_motivos_excluidos to anon, authenticated;
grant usage on sequence ssoma_bolsa_latam_motivos_excluidos_id_seq to anon, authenticated;
