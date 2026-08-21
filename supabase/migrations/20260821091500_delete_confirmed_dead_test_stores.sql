-- ============================================================================
-- Ölü kayıt taramasında (2026-08-21) tespit edilen 9 test/artık vitrini
-- kalıcı olarak siler
-- ============================================================================
-- BAĞLAM
-- 20260820213529_unpublish_test_stores.sql (#276) bu satırların 8'ini
-- (+ demo-teknofix-8a4e0020) Keşfet'ten yayından indirmişti ama SİLMEMİŞTİ.
-- Bu 9 satırın hiçbiri `cloned_from_slug` taşımıyor, yani
-- cleanup_expired_trial_clones() cron'una hiç girmiyorlar — otomatik
-- silinme yolları yok, kalıcı olarak duracaklardı. `kiralik-butik-9c3e4794`
-- ise #276'nın hedef listesinde hiç yoktu (aynı kategoriden, gözden kaçmış
-- bir kayıt) — bu taramada bulundu.
--
-- KAPSAM DIŞI BIRAKILAN: demo-teknofix-8a4e0020. #276'da `cloned_from_slug`
-- BİLİNÇLİ olarak temizlenip "kalıcı silinmesin" diye korunmuştu — bu
-- kararı bu migration bozmuyor, kullanıcı onayıyla dışarıda tutuldu.
--
-- GÜVENLİK — #276 ile aynı disiplin: isim/desen araması yok, yalnız
-- elle onaylı 9 slug'lık sabit liste. Canlı durum bu listeyle birebir
-- uyuşmuyorsa (sayı, yayın durumu, demo/premium işareti) migration hata
-- verir ve hiçbir satır silinmez. Zaten temizse (0 eşleşme — bu migration
-- ikinci kez uygulanırsa ya da satırlar başka bir yoldan zaten silindiyse)
-- no-op'tur.
--
-- CASCADE: stores silinince ürün/kategori/taslak/oturum/makale gibi bağlı
-- satırlar mevcut ON DELETE CASCADE kısıtlarıyla otomatik temizlenir
-- (casper-test-vitrini'nin 1 store_articles satırı dahil). slug, silmeden
-- hemen önce trg_stores_tombstone_slug tetikleyicisiyle otomatik olarak
-- deleted_store_slugs'a yazılır (20260820030000) — burada ayrıca elle
-- yazılmıyor.
-- ============================================================================

do $$
declare
  v_target_slugs text[] := array[
    'aymira-giyim',
    'casper-test-vitrini',
    'cccc',
    'debugtest-1786543537-2',
    'deneme',
    'demo-teknofix-ba834c19',
    'dogrulama-3c7176',
    'kiralik-butik-9c3e4794',
    'xxxxx'
  ];
  v_existing_count bigint;
  v_safe_count bigint;
  v_deleted_count bigint;
begin
  -- Ön kontroller ile silme arasına eşzamanlı yazma giremez.
  lock table public.stores in share row exclusive mode;

  select pg_catalog.count(*)
  into v_existing_count
  from public.stores
  where slug = any (v_target_slugs);

  -- Zaten temizse (ör. bu migration ikinci kez çalıştırılırsa) no-op.
  if v_existing_count = 0 then
    return;
  end if;

  if v_existing_count <> pg_catalog.array_length(v_target_slugs, 1) then
    raise exception
      'DEAD_STORE_PREFLIGHT_FAILED: expected either 0 or % target rows, found %',
      pg_catalog.array_length(v_target_slugs, 1),
      v_existing_count;
  end if;

  -- Hedeflerin tamamı: demo şablonu değil, hâlâ yayınlanmamış, hiç premium
  -- almamış olmalı. Biri bile uymuyorsa gerçek/ödemeli bir vitrine
  -- dokunuyoruz demektir — dur.
  select pg_catalog.count(*)
  into v_safe_count
  from public.stores
  where slug = any (v_target_slugs)
    and is_demo = false
    and is_published = false
    and premium_expires_at is null;

  if v_safe_count <> pg_catalog.array_length(v_target_slugs, 1) then
    raise exception
      'DEAD_STORE_SAFETY_CHECK_FAILED: expected % safe-to-delete rows, found %',
      pg_catalog.array_length(v_target_slugs, 1),
      v_safe_count;
  end if;

  delete from public.stores
  where slug = any (v_target_slugs)
    and is_demo = false
    and is_published = false
    and premium_expires_at is null;

  get diagnostics v_deleted_count = row_count;

  if v_deleted_count <> pg_catalog.array_length(v_target_slugs, 1) then
    raise exception
      'DEAD_STORE_DELETE_FAILED: expected % deleted rows, deleted %',
      pg_catalog.array_length(v_target_slugs, 1),
      v_deleted_count;
  end if;
end;
$$;
