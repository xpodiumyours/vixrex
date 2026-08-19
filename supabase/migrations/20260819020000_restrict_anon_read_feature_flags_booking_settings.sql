-- =============================================================================
-- GÖREV 3: feature_flags ve booking_settings anon okumasını kısıtla
-- =============================================================================
--
-- SORUN:
--   - feature_flags: USING (true) ile anon + authenticated her satırı okuyor.
--     İç özellik durumları (flag_key, is_enabled, target_users) sızıyor.
--   - booking_settings: USING (true) ile herkes (anon dahil) her store'un
--     çalışma saatlerini, kapasite kurallarını ve mola bilgilerini okuyabilir.
--     Yayınlanmamış vitrinlerin ayarları bile görünüyor.
--
-- DÜZELTME:
--   1) feature_flags: anon erişimini kaldır — yalnızca authenticated okuyabilsin.
--      get_feature_flags() RPC'si Flutter'dan authenticated olarak çağrılıyor.
--   2) booking_settings: public okumayı yalnızca yayınlanmış vitrinlerle
--      sınırla — yayınlanmamış/draft vitrinlerin ayarları dışarı sızmasın.
--
-- ETKİLENEN ROLLER:
--   - anon:   feature_flags OKUMA ENGELLENDİ. booking_settings yalnızca
--             yayınlanmış store'lar için okunabilir.
--   - authenticated: feature_flags okunabilir. booking_settings için
--             sahip olduğu store'u okuyabilir (mevcut owner politikası)
--             VEYA yayınlanmış bir store'un ayarlarını okuyabilir.
--   - service_role: RLS dışında — etkilenmez.
--
-- NOT: Bu migration canlıya uygulanmaz, PR olarak bırakılır.
-- =============================================================================

BEGIN;

-- ── 1) feature_flags: mevcut herkese açık SELECT politikasını kaldır ──────
DROP POLICY IF EXISTS "Public can read feature flags" ON public.feature_flags;

-- Yeni politika: yalnızca authenticated kullanıcılar okuyabilsin.
-- anon kullanıcılar feature_flags tablosuna doğrudan erişemez.
CREATE POLICY "Authenticated can read feature flags"
  ON public.feature_flags
  FOR SELECT
  TO authenticated
  USING (true);

-- ── 2) booking_settings: mevcut herkese açık SELECT politikasını kaldır ──
DROP POLICY IF EXISTS "Public can read booking_settings" ON public.booking_settings;

-- Yeni politika: yalnızca yayınlanmış store'un ayarları okunabilir.
-- Bu, draft/yayınlanmamış vitrinlerin kapasite ve çalışma saatlerini
-- dışarıya karşı korur. Owner politikaları (INSERT/UPDATE) mevcut haliyle
-- kalır — zaten auth.uid() = user_id kontrolü yapıyor.
CREATE POLICY "Published stores readable for booking settings"
  ON public.booking_settings
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.stores AS s
      WHERE s.slug = booking_settings.store_slug
        AND s.is_published = true
    )
  );

COMMIT;
