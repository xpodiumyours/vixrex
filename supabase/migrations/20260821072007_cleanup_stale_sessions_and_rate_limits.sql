-- ============================================================================
-- Süresi dolmuş owner_sessions ve eskimiş assistant_rate_limits pencerelerinin
-- otomatik temizliği
-- ============================================================================
-- NEDEN VAR
-- Ölü kayıt taraması (2026-08-21): owner_sessions'taki 12 satırın TAMAMI
-- süresi dolmuş tek kullanımlık giriş kodlarıydı (kullanılıp atılan, kimse
-- silmiyor); assistant_rate_limits'teki 7 satırın TAMAMI 1 günden eski
-- pencerelerdi. İkisi için de temizlik cron'u yoktu — tablolar süresiz
-- büyüyecekti. Bu iki tablo `cleanup_expired_trial_clones()`'un aksine
-- kullanıcı içeriği taşımıyor (oturum kodu / rate-limit sayacı), bu yüzden
-- onay gerektiren bir "hangi kayıt" kararı yok — süresi geçmiş satır her
-- zaman güvenle silinebilir.
--
-- NE YAPAR
-- 1) cleanup_expired_owner_sessions(): expires_at geçmiş owner_sessions
--    satırlarını siler (consumed_at'e bakmaz — süresi dolan bir kod zaten
--    bir daha kullanılamaz, consumed olsun olmasın çöptür).
-- 2) cleanup_stale_assistant_rate_limits(): window_started_at 1 günden eski
--    assistant_rate_limits satırlarını siler (o pencere zaten kapanmış,
--    consume_assistant_request yeni pencere açıyor).
-- 3) İkisi de pg_cron ile saatte bir, mevcut cleanup-expired-trial-clones /
--    demote-expired-premium-stores işleriyle aynı desende çalıştırılır.
--    anon/authenticated'e YETKİ VERİLMEZ — yalnız cron/postgres çağırır
--    (temel şemadaki kapalı varsayılan default privileges nedeniyle ayrı
--    bir revoke satırına gerek yok, bkz. cleanup_expired_trial_clones ile
--    aynı grant taraması).
-- ============================================================================

create or replace function public.cleanup_expired_owner_sessions()
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
begin
  delete from public.owner_sessions
  where expires_at < pg_catalog.now();
end;
$$;

comment on function public.cleanup_expired_owner_sessions() is
  'Süresi dolmuş tek kullanımlık owner_sessions giriş kodlarını siler
   (consumed olsun olmasın — süresi geçen kod zaten kullanılamaz). Yalnız
   pg_cron çağırır, anon/authenticated''e açık değildir.';

create or replace function public.cleanup_stale_assistant_rate_limits()
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
begin
  delete from public.assistant_rate_limits
  where window_started_at < pg_catalog.now() - interval '1 day';
end;
$$;

comment on function public.cleanup_stale_assistant_rate_limits() is
  '1 günden eski, artık kapanmış assistant_rate_limits pencerelerini siler.
   Yalnız pg_cron çağırır, anon/authenticated''e açık değildir.';

select cron.schedule(
  'cleanup-expired-owner-sessions',
  '0 * * * *',
  $$select public.cleanup_expired_owner_sessions();$$
);

select cron.schedule(
  'cleanup-stale-assistant-rate-limits',
  '0 * * * *',
  $$select public.cleanup_stale_assistant_rate_limits();$$
);
