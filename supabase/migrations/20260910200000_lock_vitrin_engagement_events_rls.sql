-- Vitrin engagement event tablosunu doğrudan Data API erişimine kapat.
--
-- Uygulama bu tabloya doğrudan SELECT/INSERT/UPDATE/DELETE yapmıyor:
-- yazma public.record_vitrin_engagement(...), okuma ise
-- public.get_haftalik_performans(...) SECURITY DEFINER fonksiyonları üzerinden.
-- Bu nedenle anon/authenticated tablo yetkileri gereksiz bir dış yüzeydir.
--
-- Hedef:
--   * exposed public şemadaki tablo için RLS'yi etkinleştir,
--   * anon/authenticated/PUBLIC doğrudan tablo erişimini kaldır,
--   * mevcut RPC davranışına dokunma.

alter table public.vitrin_engagement_events enable row level security;

revoke all on table public.vitrin_engagement_events
  from public, anon, authenticated;

-- Bilerek policy tanımlanmıyor: istemcilerin tabloya doğrudan erişimi yok.
-- SECURITY DEFINER RPC'ler postgres sahibiyle mevcut iş akışını sürdürür.

notify pgrst, 'reload schema';
