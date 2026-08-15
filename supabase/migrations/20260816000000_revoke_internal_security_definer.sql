-- ============================================================================
-- Internal SECURITY DEFINER fonksiyonlarının dışarıya açık olmasını kapat
-- ============================================================================
-- NEDEN VAR
-- Temel şema migration'ı çok sayıda trigger/auth/internal helper
-- fonksiyonuna anon/authenticated GRANT veriyor. Bu fonksiyonlar
-- dışarıdan RPC olarak çağrılmamalı; sadece tetikleyiciler, servis
-- katmanı veya yetkili RPC'ler içinden çağrılmalı.
--
-- KAPANANLAR: auth trigger'ları, trigger helper'ları, sanitize/strip
-- yardımcıları ve validate_product_category.
--
-- DOKUNMAYANLAR: public API olarak bilinçli açılmış RPC'ler
-- (örn. get_store_preview, create_store_with_token, save_store_draft_with_token).
-- ============================================================================

-- Auth trigger'ları: yalnız auth changes üzerinden çalışır.
revoke execute on function public.handle_new_user()
  from public, anon, authenticated;
revoke execute on function public.handle_updated_user()
  from public, anon, authenticated;

-- Trigger helper'ları: BEFORE/AFTER trigger içinden çalışır.
revoke execute on function public.prevent_demo_store_mutation()
  from public, anon, authenticated;
revoke execute on function public.set_published_at()
  from public, anon, authenticated;
revoke execute on function public.set_published_at_on_insert()
  from public, anon, authenticated;
revoke execute on function public.set_updated_at()
  from public, anon, authenticated;
revoke execute on function public.set_store_instagram_updated_at()
  from public, anon, authenticated;

-- İçerik sanitize/strip yardımcıları: servis katmanından çağrılır.
revoke execute on function public.strip_draft_secrets(jsonb)
  from public, anon, authenticated;
revoke execute on function public.sanitize_assistant_handoff(jsonb)
  from public, anon, authenticated;

-- validate_product_category: zaten service_role kullanıyor,
-- anon/authenticated grant'i gereksiz.
revoke execute on function public.validate_product_category()
  from public, anon, authenticated;

-- Yeniden kapatılan audit fonksiyonları: temel şema hala grant veriyor.
revoke execute on function public.log_audit_event(uuid, text, text, text, text, jsonb, jsonb, jsonb)
  from public, anon, authenticated;
revoke execute on function public.get_audit_logs(integer, text, text)
  from public, anon;
revoke execute on function public.get_audit_logs(integer, uuid, text, text)
  from public, anon;
