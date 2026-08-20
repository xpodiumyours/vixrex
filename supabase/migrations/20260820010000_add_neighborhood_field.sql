-- #264: Yerel SEO alanları eksik — il/ilçe var, mahalle yok.
--
-- SORUN: province_name/district_name (il/ilçe) zaten zorunlu alanlar ama
-- daha yerel bir SEO sinyali (mahalle) yapılandırılmış alan olarak yoktu.
--
-- ÇÖZÜM: Tek nullable kolon eklenir. il/ilçe gibi zorunlu değildir —
-- yayın kapısını etkilemez, yalnız isteyen sahip doldurursa daha yerel
-- bir konum sinyali eklemiş olur.
--
-- Alan sözleşmesi: docs/vitrin-alan-semasi.md §5.2
-- Şema kaynağı: public_web/src/lib/vitrinFieldSchema.ts (anahtar: mahalle)

alter table public.stores
  add column if not exists neighborhood_name text;

comment on column public.stores.neighborhood_name is
  'Mahalle — il/ilçeden daha yerel SEO sinyali. Zorunlu değil, NULL olabilir.';

-- Not: RLS politikalarına dokunulmadı. Bu kolon mevcut stores satırının
-- parçasıdır ve mevcut okuma politikalarıyla birlikte gelir. Sahip yazma
-- yetkisi update_working_draft_field üzerinden zaten bağımsız kontrol
-- ediyor (owner_forbidden_draft_keys() + information_schema.columns
-- varlık kontrolü, bkz. 20260805100000_add_working_draft_field_update.sql)
-- — yeni kolon otomatik yazılabilir olur, ayrı bir izin satırı gerekmez.
-- Müşteri yanıtına girmesi için public_web tarafındaki PUBLIC_STORE_SELECT
-- listesine eklenmesi gerekir (bkz. public_web/src/app/v/[slug]/page.tsx).

notify pgrst, 'reload schema';
