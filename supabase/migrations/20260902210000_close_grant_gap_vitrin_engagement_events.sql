-- GRANT güvenlik bekçisi kırmızısı (2026-09-02, ikinci tur).
--
-- 20260902150710_close_ddl_adjacent_grant_gap_tek_kaynak_tables üç tabloyu
-- kapattı (owner_flow_states, assistant_conversations, assistant_messages)
-- ve bundan sonrası için varsayılan yetkileri daralttı. Ama
-- vitrin_engagement_events o migration'dan ÖNCE oluşturulmuştu
-- (20260902112954_faz_f_vitrin_engagement_events), dolayısıyla listeye
-- girmemiş ve dört yetkiyle kalmıştı.
--
-- Bekçi bunu ilk kez burada yakaladı: bu işler yalnız supabase/ altı
-- değişince koşuyor, arada koşmadığı için sapma görünmüyordu.
--
-- Kapatılan dördü PostgREST tarafından hiç kullanılmaz; TRUNCATE ayrıca
-- RLS'ten muaftır. Uygulama davranışı değişmez.
revoke truncate, maintain, references, trigger
  on table public.vitrin_engagement_events
  from anon, authenticated;

notify pgrst, 'reload schema';
