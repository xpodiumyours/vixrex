-- ============================================================================
-- Kök sebep düzeltmesi: yeni fonksiyonlar artık varsayılan olarak açık DOĞMAZ
-- + log_audit_event'in gerçek sahtecilik açığı kapatılır
-- ============================================================================
-- NEDEN VAR
-- Casper (2026-08-15) — rent-demo taramasının devamında bulundu.
--
-- 1) KÖK SEBEP: temel şema dump'ı şunu içeriyordu:
--      ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
--        GRANT ALL ON FUNCTIONS TO anon;
--    Bu, `postgres` rolünün `public` şemasında yarattığı HER YENİ
--    fonksiyona (açıkça revoke edilmedikçe) otomatik olarak anon/
--    authenticated'e tam yetki verir. cleanup_expired_trial_clones'un
--    (bkz. 20260814230000) hiç `revoke` almadan yine de anon'a açık
--    olmasının sebebi tam olarak buydu — "revoke yok" "kapalı" demek
--    değildi, bu satır yüzünden gerçekte açıktı.
--    Düzeltme YALNIZ FUNCTIONS için — TABLES/SEQUENCES'e bilerek
--    dokunulmadı: Supabase'in standart mimarisinde tablo erişimi zaten
--    RLS ile sınırlanıyor (geniş GRANT + dar RLS politikası kasıtlı bir
--    desen), ama SECURITY DEFINER fonksiyonlar RLS'yi TAMAMEN atlıyor —
--    bu yüzden fonksiyonlarda geniş varsayılan gerçekten tehlikeli.
--
-- 2) log_audit_event: SECURITY DEFINER, search_path sabitlenmemiş, VE
--    anon/authenticated'e GRANT ALL verilmiş. Fonksiyon p_user_id'yi
--    doğrudan client'tan alıp hiç doğrulamadan audit_logs'a yazıyor —
--    yani anon biri "ben X kullanıcısıyım, şunu yaptım" diye SAHTE audit
--    kaydı üretebilir (impersonation) + sınırsız spam yazabilir.
--    Uygulama kodunda (Next.js, Flutter) bu fonksiyonu çağıran TEK YER
--    yok — kilitlemek sıfır davranış değişikliği, yalnız kullanılmayan
--    bir açığı kapatıyor.
--
-- 3) get_audit_logs (2 overload): SECURITY DEFINER DEĞİL (invoker) — RLS
--    ("Users can read own audit logs", auth.uid()=user_id) zaten devrede,
--    fonksiyonun kendi WHERE'i de al.user_id=auth.uid() filtreliyor. anon
--    çağırırsa auth.uid() null olduğu için hep boş döner — pratikte
--    tehlikeli değil, ama gereksiz geniş yetki temizlik için kapatılıyor
--    (yalnız anon'dan; authenticated kullanıcının kendi kaydını okuması
--    meşru kullanım, dokunulmadı).
-- ============================================================================

-- ── 1) Kök sebep: gelecekteki fonksiyonlar artık kapalı doğar ─────────────
alter default privileges for role postgres in schema public
  revoke all on functions from anon, authenticated;

comment on schema public is
  'Yeni fonksiyonlar artık PUBLIC/anon/authenticated''e KAPALI doğar (bkz.
   20260815210000). Bir RPC gerçekten client''a açık olmalıysa migration
   içinde AÇIKÇA grant edilir — bu artık istisna, varsayılan değil.';

-- ── 2) log_audit_event: kullanılmayan sahtecilik açığını kapat ────────────
create or replace function public.log_audit_event(
  p_user_id uuid,
  p_session_id text,
  p_action text,
  p_target_type text,
  p_target_id text default null::text,
  p_old_value jsonb default null::jsonb,
  p_new_value jsonb default null::jsonb,
  p_metadata jsonb default null::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_id uuid;
begin
  insert into public.audit_logs (
    user_id, session_id, action, target_type, target_id,
    old_value, new_value, metadata
  ) values (
    p_user_id, p_session_id, p_action, p_target_type, p_target_id,
    p_old_value, p_new_value, p_metadata
  ) returning id into v_id;
  return v_id;
end;
$$;

comment on function public.log_audit_event(uuid, text, text, text, text, jsonb, jsonb, jsonb) is
  'SECURITY DEFINER — RLS''i atlar. p_user_id client''tan geliyor ve
   doğrulanmıyor, bu yüzden anon/authenticated''e KAPALI tutulur (sahte
   kayıt/impersonation riski). Uygulama kodunda hiçbir çağıran yok —
   ileride gerçekten kullanılacaksa auth.uid() ile kendi kimliğini
   doğrulayan bir sarmalayıcı yazılmalı, client''ın user_id seçmesine
   izin verilmemeli.';

revoke execute on function public.log_audit_event(uuid, text, text, text, text, jsonb, jsonb, jsonb)
  from public, anon, authenticated;

-- ── 3) get_audit_logs: anon'dan kapat, authenticated meşru kullanım kalır ──
revoke execute on function public.get_audit_logs(integer, text, text)
  from anon;
revoke execute on function public.get_audit_logs(integer, uuid, text, text)
  from anon;
