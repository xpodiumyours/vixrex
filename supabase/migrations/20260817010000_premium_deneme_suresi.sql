-- ============================================================================
-- Deneme süresi 14 gün + premium bitişinde "yayında kalır, 3 gün sonra
-- taslağa döner" (PR #2)
-- ============================================================================
-- NEDEN VAR (2026-08-17, Casper kararları)
-- Kiralık vitrin modeli: esnaf şablonu kiralayıp 14 gün ücretsiz dener,
-- sonra aylık 299 TL premium ile sahiplenir. Eski davranış iki yönden
-- uymuyor:
--   1) Deneme 30 SAATTİ — esnafın vitrin kurması için gerçekçi değil.
--      (20260814230000'de Casper 30 saat demişti; model değişti → 14 gün.)
--   2) Premium biten vitrin YAYINDA KALIR, 3 gün sonra TASLAĞA DÖNER
--      (is_published=false, veri KORUNUR). Eski temizlik yalnız
--      "yayınlanmamış deneme"yi SİLİYORDU — premium ödemiş esnafın verisini
--      asla silmemek gerekir.
--
-- KRİTİK GÜVENLİK AYRIMI
-- Temizlik artık yalnız "hiç premium almamış" (premium_expires_at IS NULL)
-- denemeleri siler. Ödeme geçmişi olan vitrinler HİÇBİR KOŞULDA SİLİNMEZ:
-- para ödemiş esnafın vitrini düşse bile verisi durur, tekrar ödeyince
-- yeniden yayınlanır (premium_expires_at dolu → silme koşuluna girmez).
--
-- NOT: Uygulanmış migration değiştirilmez (VIXREX_RULES §9) — 30 saatlik
-- cleanup fonksiyonu create or replace ile GÜNCELLENİR, yetkiler
-- (anon/authenticated'ten revoke) korunur; yeni davranış bu dosyada.
-- ============================================================================

-- ── 1) Deneme temizliği: 30 saat → 14 gün + premium geçmişi olanı asla silme ──
create or replace function public.cleanup_expired_trial_clones()
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
begin
  -- Yalnız: kiralık (cloned_from_slug dolu) + hâlâ yayınlanmamış +
  -- hiç premium almamış (premium_expires_at IS NULL) + 14 günden eski.
  -- premium_expires_at dolu satırlar bu koşula girmez → para ödemiş
  -- esnafın vitrini ne olursa olsun SİLİNMEZ.
  delete from public.stores
  where cloned_from_slug is not null
    and is_published = false
    and premium_expires_at is null
    and created_at < pg_catalog.now() - interval '14 days';
end;
$$;

comment on function public.cleanup_expired_trial_clones() is
  '"Bu vitrini kirala" ile açılıp 14 gündür yayınlanmamış ve HİÇ PREMIUM
   ALMAMIŞ denemeleri siler. Premium geçmişi olan (premium_expires_at dolu)
   hiçbir satıra dokunmaz — para ödemiş esnafın verisi asla silinmez.
   Yalnız pg_cron çağırır, dışarıya (anon/authenticated) açık değildir.';

-- ── 2) Premium biten vitrini taslağa döndür (3 gün sonra) ──────────────────
create or replace function public.demote_expired_premium_stores()
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
begin
  -- Premium süresi dolalı 3 gün olmuş, hâlâ yayında olan kiralık vitrinleri
  -- yayından düşür (is_published=false). Veri SİLİNMEZ — satır ve tüm
  -- içeriği durur; esnaf yeniden ödeyince tekrar yayınlanabilir.
  -- "Yayında kalır, 3 gün sonra taslağa döner" (Casper, 2026-08-17).
  -- Yayın durumunu değiştirmek stores üzerinde bump_store_version
  -- tetikleyicisini çalıştırır (version artar) — bu doğru davranıştır:
  -- canlı veri değişti, sürüm onu yansıtmalı.
  update public.stores
  set is_published = false
  where cloned_from_slug is not null
    and is_published = true
    and premium_expires_at is not null
    and premium_expires_at < pg_catalog.now() - interval '3 days';
end;
$$;

comment on function public.demote_expired_premium_stores() is
  'Premium süresi dolalı 3 gün olmuş yayındaki kiralık vitrinleri taslağa
   döndürür (is_published=false). Veri korunur — para ödemiş esnafın
   vitrini silinmez, yeniden ödeyince yayınlanır. Yalnız pg_cron çağırır.';

-- ── 3) Güvenlik: iki fonksiyon da dışarıya kapalı ──────────────────────────
-- create or replace yetkileri korur ama disiplin gereği (grant satırı yok
-- ≠ kapalı değildir) açıkça revoke edilir.
revoke execute on function public.cleanup_expired_trial_clones()
  from public, anon, authenticated;
revoke execute on function public.demote_expired_premium_stores()
  from public, anon, authenticated;

-- ── 4) pg_cron: her saat iki işi de çalıştır ───────────────────────────────
select cron.unschedule('cleanup-expired-trial-clones')
  where exists (select 1 from cron.job where jobname = 'cleanup-expired-trial-clones');

select cron.schedule(
  'cleanup-expired-trial-clones',
  '0 * * * *',
  $$select public.cleanup_expired_trial_clones();$$
);

select cron.unschedule('demote-expired-premium-stores')
  where exists (select 1 from cron.job where jobname = 'demote-expired-premium-stores');

select cron.schedule(
  'demote-expired-premium-stores',
  '0 * * * *',
  $$select public.demote_expired_premium_stores();$$
);
