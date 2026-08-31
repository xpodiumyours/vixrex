-- ============================================================================
-- #257: Abonelik yenileme hatırlatması — takip alanı + iki küçük RPC
-- ============================================================================
-- NEDEN VAR
-- Esnaf premium süresinin dolmak üzere olduğunu fark etmezse ödeme
-- yapmadan süre dolar, vitrin 3 gün sonra taslağa döner
-- (demote_expired_premium_stores). Bu, önlenebilir bir churn kaynağı.
--
-- NE YAPAR
-- 1) stores.premium_reminder_sent_for: hatırlatmanın GÖNDERİLDİĞİ ANKİ
--    premium_expires_at değerini tutar (boolean "gönderildi" bayrağı değil).
--    Esnaf yeniden ödeyip premium_expires_at ileri taşındığında bu değer
--    artık eşleşmez — otomatik olarak yeni bir hatırlatma hakkı doğar,
--    ayrı bir "sıfırla" tetikleyicisi gerekmez.
-- 2) list_premium_expiry_reminder_candidates(p_within_days): süresi
--    p_within_days içinde dolacak VE bu son tarih için daha önce
--    hatırlatılmamış vitrinleri SALT OKUNUR döner — hiçbir şeyi işaretlemez.
-- 3) mark_premium_expiry_reminder_sent(p_store_id, p_premium_expires_at):
--    yalnız GERÇEKTEN gönderilen tek bir push başarılı olduktan SONRA
--    çağrılır. Bilerek "önce işaretle, sonra gönder" DEĞİL — push
--    başarısız olursa (OneSignal kesintisi, ağ hatası) satır işaretsiz
--    kalır, bir sonraki cron çalışmasında tekrar denenir. Ender bir
--    çift bildirim, sessizce kaçırılan bir hatırlatmadan daha iyi bir
--    hatadır. p_premium_expires_at eşleşmesi, seçim ile işaretleme
--    arasında esnafın süresini uzatmış olma ihtimaline karşı korur —
--    öyle bir durumda işaretleme sessizce hiçbir şey yapmaz.
--
-- GÜVENLİK
-- İkisi de yalnız service_role çağırabilir (public_web'in cron rotası,
-- SUPABASE_SERVICE_ROLE_KEY ile) — anon/authenticated'e KAPALI. Fonksiyonlar
-- push GÖNDERMEZ; gerçek OneSignal çağrısı Next.js tarafında (mevcut sınır:
-- dış HTTP çağrıları Postgres'ten değil, Next.js/Edge Function'dan yapılır,
-- bu proje pg_net kullanmıyor).
-- ============================================================================

alter table public.stores
  add column if not exists premium_reminder_sent_for timestamptz;

comment on column public.stores.premium_reminder_sent_for is
  'Abonelik yenileme hatırlatmasının GÖNDERİLDİĞİ ANDAKİ premium_expires_at
   değeri. premium_expires_at bundan farklıysa (hiç gönderilmemiş VEYA
   esnaf yeniden ödeyip süre uzamış) yeniden hatırlatma hakkı doğar.';

create or replace function public.list_premium_expiry_reminder_candidates(
  p_within_days integer default 3
)
returns table (
  store_id uuid,
  user_id uuid,
  store_slug text,
  store_name text,
  premium_expires_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
begin
  return query
  select s.id, s.user_id, s.slug, s.name, s.premium_expires_at
  from public.stores as s
  where s.premium_expires_at is not null
    and s.user_id is not null
    and s.premium_expires_at > pg_catalog.now()
    and s.premium_expires_at
      <= pg_catalog.now() + make_interval(days => greatest(coalesce(p_within_days, 3), 0))
    and (
      s.premium_reminder_sent_for is null
      or s.premium_reminder_sent_for <> s.premium_expires_at
    );
end;
$$;

comment on function public.list_premium_expiry_reminder_candidates(integer) is
  'Süresi p_within_days (varsayılan 3) içinde dolacak ve bu son tarih için
   daha önce hatırlatılmamış vitrinleri SALT OKUNUR döner, hiçbir şey
   işaretlemez. Yalnız service_role çağırabilir.';

create or replace function public.mark_premium_expiry_reminder_sent(
  p_store_id uuid,
  p_premium_expires_at timestamptz
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
begin
  update public.stores
  set premium_reminder_sent_for = p_premium_expires_at
  where id = p_store_id
    and premium_expires_at = p_premium_expires_at;
end;
$$;

comment on function public.mark_premium_expiry_reminder_sent(uuid, timestamptz) is
  'Yalnız GERÇEKTEN gönderilmiş tek bir push başarılı olduktan SONRA
   çağrılır — önceden değil (push başarısız olursa satır işaretsiz kalır,
   bir sonraki cron''da tekrar denenir). p_premium_expires_at eşleşmesi,
   seçimle işaretleme arasında esnafın süresini uzatmış olma ihtimaline
   karşı korur. Yalnız service_role çağırabilir.';

revoke execute on function public.list_premium_expiry_reminder_candidates(integer)
  from public, anon, authenticated;
revoke execute on function public.mark_premium_expiry_reminder_sent(uuid, timestamptz)
  from public, anon, authenticated;
grant execute on function public.list_premium_expiry_reminder_candidates(integer)
  to service_role;
grant execute on function public.mark_premium_expiry_reminder_sent(uuid, timestamptz)
  to service_role;
