-- ============================================================================
-- #295-alt: stores tablosunda GRANT SELECT eksik tüm sütunları tamamla
-- ============================================================================
--
-- KÖK NEDEN: stores tablosu sütun bazlı GRANT SELECT kullanıyor (başlangıç
-- şemasında 80 sütun). Sonradan eklenen ~25 sütuna GRANT eklenmemiş.
-- StoreSafeSelect.columns bu sütunları SELECT sorgusuna dahil edince
-- PostgreSQL 42501 (permission denied) döndürüyor → Keşfet sorgusu düşüyor.
--
-- NOT: user_id kasıtlı olarak REVOKE edilmiş (V-09, 20260818050000) ve
-- StoreSafeSelect'te yer almıyor — bu sütuna GRANT eklenMEZ.
--
-- ============================================================================
-- 1. StoreSafeSelect tarafından kullanılan sütunlar (KRİTİK — Keşfet'i kırıyor)
-- 2. Şu an kullanılmayan ama gelecekte eklenebilecek sütunlar (teknik borç)
-- ============================================================================

DO $$
DECLARE
  -- Kriz: Keşfet'i doğrudan kıran sütunlar
  critical_cols text[] := array[
    'section_visibility',
    'hero_location_text',
    'category_section_title',
    'product_section_title',
    'gallery_action_label',
    'gallery_action_href',
    'blog_section_kicker',
    'blog_section_title',
    'faq_section_kicker',
    'faq_section_title',
    'faq_section_description',
    'map_label',
    'neighborhood_name'
  ];

  -- Teknik borç: şu an kullanılmayan ama gelecekte gerekebilecek sütunlar
  future_cols text[] := array[
    'cloned_from_slug',
    'premium_expires_at',
    'version',
    'business_verified_at',
    'business_verification_method',
    'google_business_location_name',
    'premium_reminder_sent_for',
    'atlanan_alanlar',
    'refund_status',
    'refunded_at'
  ];

  col text;
  v_granted_count integer := 0;
BEGIN
  -- Kriz sütunlarını grant et
  FOREACH col IN ARRAY critical_cols LOOP
    EXECUTE format(
      'GRANT SELECT ("%s") ON TABLE "public"."stores" TO "anon"', col
    );
    EXECUTE format(
      'GRANT SELECT ("%s") ON TABLE "public"."stores" TO "authenticated"', col
    );
    v_granted_count := v_granted_count + 1;
  END LOOP;

  -- Gelecek sütunlarını grant et (IF NOT EXISTS mantığıyla, zaten varsa hata vermez)
  FOREACH col IN ARRAY future_cols LOOP
    BEGIN
      EXECUTE format(
        'GRANT SELECT ("%s") ON TABLE "public"."stores" TO "anon"', col
      );
      EXECUTE format(
        'GRANT SELECT ("%s") ON TABLE "public"."stores" TO "authenticated"', col
      );
      v_granted_count := v_granted_count + 1;
    EXCEPTION WHEN undefined_column THEN
      -- Sütun henüz DB'de yoksa sessizce atla
      RAISE NOTICE 'Column % does not exist yet, skipping GRANT', col;
    END;
  END LOOP;

  RAISE NOTICE 'Granted SELECT on % columns for anon/authenticated', v_granted_count;
END;
$$;

-- PostgREST şema önbelleğini yenile
NOTIFY pgrst, 'reload schema';
