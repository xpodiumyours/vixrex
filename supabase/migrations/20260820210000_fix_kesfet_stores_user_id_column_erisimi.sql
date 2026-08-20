-- ACİL DÜZELTME (2026-08-20, canlıda bulundu): Keşfet ekranı hiç açılmıyordu.
--
-- KÖK NEDEN: PR #274 (20260820040000_fix_owner_rls_user_id_privilege.sql),
-- 11 tabloda stores.user_id'yi DOLAYLI (başka bir tablonun RLS politikası
-- içinden) okuyan 24 politikayı düzeltti. Ama `stores` tablosunun kendi
-- istemci sorguları hâlâ stores.user_id'yi DOĞRUDAN istiyordu:
--
--   1. ExploreRepository.fetchPublishedStores() (Keşfet ekranı) —
--      StoreSafeSelect.columns select listesinde `user_id` fazlalıktı
--      (StoreData modelinde hiç karşılığı yok, hiç kullanılmıyordu).
--   2. StorePublishedInfoLookupService.lookup() — "benim yayınladığım
--      vitrin hangisi" araması `.eq('user_id', userId)` ile filtreliyordu.
--
-- Uygulama her ziyaretçiye (giriş yapmadan) otomatik anonim bir Supabase
-- Auth oturumu açtığı için (bkz. main.dart `_oturumuGuvenceyeAl`, PR #52)
-- HERKES Postgres'e göre `authenticated` rolünde sorgu atıyor. V-09
-- (20260818050000) stores.user_id'nin SELECT'ini authenticated'ten haklı
-- gerekçeyle revoke etmişti — ama bu iki sorgu o sütunu doğrudan istediği
-- için PostgreSQL sorgunun TAMAMINI "permission denied for table stores"
-- (42501) ile reddediyordu. Gerçek tarayıcıda (Playwright) birebir
-- reprodüklendi: giriş yapmamış yeni bir ziyaretçi bile Keşfet'i hiç
-- açamıyordu.
--
-- ÇÖZÜM:
--   1. Dart tarafında StoreSafeSelect.columns'tan gereksiz `user_id`
--      kaldırıldı (bu migration'ın parçası değil, ayrı commit).
--   2. Burada: "kendi yayınlanmış vitrinim" araması için user_id'yi asla
--      client'a döndürmeyen bir SECURITY DEFINER fonksiyon eklenir —
--      is_store_owner_by_id/_by_slug (PR #274) ile aynı desen.

create or replace function public.get_own_published_store()
returns jsonb
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select to_jsonb(t) from (
    select s.slug, s.name
    from public.stores s
    where s.user_id = auth.uid() and s.is_published = true
    limit 1
  ) t;
$$;

comment on function public.get_own_published_store() is
  'Çağıranın (auth.uid()) yayınlanmış vitrini varsa slug+name döner, yoksa
   null. SECURITY DEFINER — stores.user_id''nin kolon bazlı SELECT''i
   authenticated''ten kapalı (V-09) olsa da bu arama içeride yapılabilsin
   diye var. user_id''nin kendisini asla DÖNMEZ.';

revoke all on function public.get_own_published_store() from public;
grant execute on function public.get_own_published_store() to authenticated;

notify pgrst, 'reload schema';
