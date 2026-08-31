-- ACİL DÜZELTME (2026-08-21, canlıda bulundu): iki ayrı sütun-bazlı GRANT
-- hatası aynı anda tespit edildi.
--
-- 1) SIZINTI (kritik): edit_token, user_id, cloned_from_slug,
--    premium_expires_at, premium_reminder_sent_for, version sütunlarının
--    SELECT'i `authenticated`'ten revoke edilmişti (V-09 ve sonrası) ama
--    `anon`'dan HİÇ revoke edilmemişti. Uygulama her ziyaretçiye otomatik
--    anonim oturum açtığı için pratikte authenticated rolü kullanılıyordu,
--    ama saf anon anahtarla (herhangi bir JS paketinde herkese açık)
--    doğrudan REST çağrısı yapan biri hâlâ edit_token/user_id
--    okuyabiliyordu. Canlıda doğrulandı: `?select=slug,edit_token,user_id`
--    anon anahtarla 200 döndü, gerçek edit_token değerlerini içeriyordu.
--    Şu an 0 gerçek (is_demo=false) yayınlı mağaza var, yalnız 9 demo
--    etkilendi — ama açık gerçek ve mağaza yayınlandığı an istismar edilebilirdi.
--
-- 2) EKSİK (fonksiyonel): 13 sıradan vitrin alanı (bölüm başlıkları,
--    mahalle adı vb.) sonradan eklenen migration'larda `anon`'a
--    grant edilmiş ama `authenticated`'e unutulmuş. Uygulama anonim oturum
--    açtığı için TÜM ziyaretçiler authenticated rolünde sorgu atıyor —
--    StoreSafeSelect.columns bu 13 alanı da istediği için TÜM Keşfet
--    sorgusu 42501 ile düşüyordu ("Vitrinler yüklenemedi").
--
-- KÖK SEBEP: sütun-bazlı GRANT modeli — her yeni/hassas sütun için iki rolde
-- ayrı ayrı hatırlanması gerekiyor, insan hafızasına bağımlı ve tekrar eden
-- bir hata sınıfı üretiyor (2026-08-05'ten bu yana en az 3 ayrı olayda).
-- Bu migration yalnız acil deliği kapatır; kalıcı mimari düzeltme
-- (varsayılan açık + küçük hassas liste kapalı) ayrı bir işte ele alınacak.

revoke select ("edit_token") on table public.stores from anon, authenticated;
revoke select ("user_id") on table public.stores from anon, authenticated;
revoke select ("cloned_from_slug") on table public.stores from anon, authenticated;
revoke select ("premium_expires_at") on table public.stores from anon, authenticated;
revoke select ("premium_reminder_sent_for") on table public.stores from anon, authenticated;
revoke select ("version") on table public.stores from anon, authenticated;

grant select (
  "blog_section_kicker", "blog_section_title", "category_section_title",
  "faq_section_description", "faq_section_kicker", "faq_section_title",
  "gallery_action_href", "gallery_action_label", "hero_location_text",
  "map_label", "neighborhood_name", "product_section_title", "section_visibility"
) on table public.stores to authenticated;

notify pgrst, 'reload schema';
