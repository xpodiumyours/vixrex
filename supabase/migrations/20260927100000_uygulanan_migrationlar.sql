-- ============================================================================
-- UYGULANAN MIGRATIONLAR — canliya uygulanan dosyalarin kaydi
-- 2026-09-27
--
-- AMAC
--   `migration-uygula` isinin toplu modu hangi dosyanin uygulandigini buradan
--   okur, basarili uygulamadan sonra buraya yazar. Yarida kalan bir toplu kosu
--   ayni etiketle tekrar calistirildiginda kaldigi yerden devam eder; kayitli
--   dosya ikinci kez uygulanmaz.
--
-- KORUMALAR
--   - Disariya kapali: anon/authenticated/public yetkileri geri alinir, RLS acilir.
--   - sha256 sutunu, kayitli dosyanin sonradan degistirilmesini gorunur kilar.
--   - Idempotent: ikinci kosuda hicbir sey degismez.
-- ============================================================================

begin;

create table if not exists public.uygulanan_migrationlar (
  ad text primary key,
  sha256 text not null,
  uygulama_zamani timestamptz not null default now(),
  uygulayan text,
  calisma_id text
);

alter table public.uygulanan_migrationlar enable row level security;

revoke all on table public.uygulanan_migrationlar from public;
revoke all on table public.uygulanan_migrationlar from anon;
revoke all on table public.uygulanan_migrationlar from authenticated;
grant all on table public.uygulanan_migrationlar to service_role;

comment on table public.uygulanan_migrationlar is
  'migration-uygula isinin kaydi: canliya uygulanan migration dosyalari ve sha256 ozetleri (2026-09-27)';

commit;
