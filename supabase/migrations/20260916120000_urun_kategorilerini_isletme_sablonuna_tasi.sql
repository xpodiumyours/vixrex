-- Mevcut urun kategorilerini isletme kategorisinin urun sablonuna tasi.
--
-- NEDEN (2026-09-16): shared/business_categories.json icindeki 19 isletme
-- kategorisine productTemplateKey eklendi ve yeni acilan urun kategorileri
-- artik magazanin isletme kategorisinden sablon devraliyor (PR #504).
-- Ancak canlidaki mevcut kayitlarin tamami hala 'generic' sablonundaydi ve
-- 'generic' sablonunun sifir alani var: esnafa kategorisine ozel hicbir urun
-- bilgisi sorulmuyordu.
--
-- GUVENLIK OLCUMU (2026-09-16, canli veri):
--   * Hizmet sablonuna gidecek 44 urunun (Kuafor 24, Teknik Servis 20)
--     hicbirinde marka, barkod, stok veya metadata verisi YOK -> veri kaybi
--     riski olculdu ve sifir cikti.
--   * Yalniz 'generic' olan satirlar guncelleniyor; esnafin ekrandan bilerek
--     sectigi sablon EZILMEZ.
--   * Eslesme bulunamayan magaza kategorileri 'generic' kaliyor (onceki
--     davranis korunur).
--   * Kategori adindan tahmin yapilmaz; esleme tablosu dogrudan
--     shared/business_categories.json'un label + aliases alanlarindan uretildi.

with esleme(kategori, sablon) as (
  values
    ('giyim', 'fashion'),
    ('giyim & butik', 'fashion'),
    ('butik', 'fashion'),
    ('gıda', 'food'),
    ('gıda & fırın', 'food'),
    ('gida', 'food'),
    ('fırın', 'food'),
    ('firin', 'food'),
    ('kozmetik', 'beauty'),
    ('dekorasyon', 'home'),
    ('elektronik', 'electronics'),
    ('kırtasiye', 'generic'),
    ('kirtasiye', 'generic'),
    ('kafe / lokanta', 'food'),
    ('kafe', 'food'),
    ('lokanta', 'food'),
    ('restoran', 'food'),
    ('kuaför', 'service'),
    ('guzellik', 'service'),
    ('güzellik', 'service'),
    ('kuafor', 'service'),
    ('teknik servis', 'service'),
    ('servis', 'service'),
    ('teknik', 'service'),
    ('danışmanlık', 'service'),
    ('hizmet & danışmanlık', 'service'),
    ('danismanlik', 'service'),
    ('hizmet', 'service'),
    ('eğitim', 'service'),
    ('eğitim & ders', 'service'),
    ('ders', 'service'),
    ('egitim', 'service'),
    ('ev & temizlik', 'service'),
    ('ev temizlik', 'service'),
    ('temizlik', 'service'),
    ('spor & fitness', 'service'),
    ('spor / fitness', 'service'),
    ('fitness', 'service'),
    ('spor', 'service'),
    ('pet / veteriner', 'generic'),
    ('pet shop & veteriner', 'generic'),
    ('evcil hayvan', 'generic'),
    ('pet', 'generic'),
    ('veteriner', 'generic'),
    ('sağlık & yaşam', 'service'),
    ('sağlık / yaşam', 'service'),
    ('saglik', 'service'),
    ('yaşam', 'service'),
    ('oto & araç hizmetleri', 'automotive'),
    ('oto / araç', 'automotive'),
    ('araba', 'automotive'),
    ('arac', 'automotive'),
    ('araç', 'automotive'),
    ('oto', 'automotive'),
    ('diğer', 'generic'),
    ('diger', 'generic')
),
hedef as (
  select pc.id, e.sablon
  from public.product_categories pc
  join public.stores s on s.id = pc.store_id
  join esleme e on e.kategori = lower(btrim(s.kategori))
  where pc.product_template_key = 'generic'
    and e.sablon <> 'generic'
)
update public.product_categories pc
set product_template_key = hedef.sablon
from hedef
where hedef.id = pc.id;
