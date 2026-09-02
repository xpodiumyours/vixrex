-- 2026-09-02: add_optional_business_verification (20260902152820) uc kolon
-- ekledi ama GRANT eklemedi. stores tablosunda anon/authenticated SELECT
-- yetkisi KOLON BAZINDA veriliyor (bkz. 20260821195520_emergency_revoke_
-- stores_table_level_anon_privileges), bu yuzden yeni kolonlar okunamaz kaldi.
--
-- Postgres'te izinsiz tek bir kolon TUM sorguyu 42501 ile dusurur. page.tsx'teki
-- emniyet agi yalniz 42703 ("kolon yok") yakaliyordu; kolon artik VAR ama
-- okunamiyordu, o yuzden ag devreye girmedi ve /v/[slug] sayfalarinin hepsi
-- 500 verdi (18:36-22:08 arasi, canlida dogrulandi).
--
-- Uygulandi ve dogrulandi: vixrex.com/v/kiralik-teknik, kiralik-butik,
-- kiralik-kuafor, demo-teknofix -> 200.
grant select (business_verified_at, business_verification_method, google_business_location_name)
  on table public.stores to anon, authenticated;

notify pgrst, 'reload schema';
