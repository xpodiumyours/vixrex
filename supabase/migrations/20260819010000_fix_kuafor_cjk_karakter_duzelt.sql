-- ============================================================================
-- kiralik-kuafor: corporate_bio'ya karışan Çince karakteri düzelt
-- ============================================================================
-- NEDEN VAR
-- 20260818100000 migration'ı canlıya uygulandığında corporate_bio alanına
-- yanlışlıkla bir Çince karakter ("皆") karışmıştı. Kaynak migration dosyası
-- sonradan düzeltildi ama VIXREX_RULES §9 uygulanmış migration'ların
-- sonradan değiştirilmesini yasaklıyor — canlı veri bu ayrı migration ile
-- düzeltilir. Doğrulama: canlı sayfada ("Kullandığımız ürünler皆 ithal ve
-- profesyonel düzeydedir") kanıtlandı, 2026-08-19.
-- ============================================================================

alter table public.stores disable trigger protect_landing_demo_stores;

update public.stores
set corporate_bio = replace(corporate_bio, 'ürünler皆 ithal', 'ürünlerin tamamı ithal')
where slug = 'kiralik-kuafor'
  and corporate_bio like '%皆%';

alter table public.stores enable trigger protect_landing_demo_stores;
