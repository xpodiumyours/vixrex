-- Vitrin bölüm başlıkları ve görünürlüğü sahibe açılıyor.
--
-- SORUN: Bölüm başlıkları bugün public_web/src/lib/vitrinCopy.ts içinde
-- kategoriye göre SABİT yazılı. Her kuaför vitrini aynı "Hakkımızda"
-- başlığını, her kafe aynı tanıtım cümlesini gösteriyor. İşletme sahibi
-- bunları değiştiremiyor. 100 vitrin yayına çıktığında hepsi aynı
-- başlıklarla dizilir ve şablon oldukları anlaşılır.
--
-- Ayrıca bölümler yalnız verisi boşsa gizleniyor. Sahibin "ben blog
-- istemiyorum" deme hakkı yok.
--
-- ÇÖZÜM: Bu 12 kolon eklenir. Hepsi NULL olabilir.
--
-- ÖNEMLİ — GERİYE DÖNÜK UYUMLULUK:
-- vitrinCopy.ts KALDIRILMAZ. Kolon NULL ise kategorinin hazır metni
-- kullanılmaya devam eder; sahip bir değer yazdıysa onunki gösterilir.
-- Böylece mevcut yayındaki vitrinler hiç etkilenmez, yeni açılanlar boş
-- görünmez, isteyen kendi cümlesini yazar.
--
-- Alan sözleşmesi: docs/vitrin-alan-semasi.md
-- Plan: implementation_plan.md Commit 10 bu kolonları düzenlenebilir yapar.

-- ── Hero ────────────────────────────────────────────────────────────────────
alter table public.stores
  add column if not exists hero_location_text text;

comment on column public.stores.hero_location_text is
  'Hero altındaki kısa konum metni, örn. "Kadıköy, İstanbul". NULL ise il/ilçe alanlarından türetilir.';

-- ── Katalog bölüm başlıkları ────────────────────────────────────────────────
alter table public.stores
  add column if not exists category_section_title text,
  add column if not exists product_section_title  text;

comment on column public.stores.category_section_title is
  'Kategori bölümünün başlığı, örn. "Servis Alanlarımız". NULL ise vitrinCopy varsayılanı.';
comment on column public.stores.product_section_title is
  'Ürün/hizmet bölümünün başlığı, örn. "Servis Fiyat Listesi". NULL ise vitrinCopy varsayılanı.';

-- ── Galeri aksiyon butonu ───────────────────────────────────────────────────
alter table public.stores
  add column if not exists gallery_action_label text,
  add column if not exists gallery_action_href  text;

comment on column public.stores.gallery_action_label is
  'Galeri bölümündeki aksiyon butonunun metni. NULL ise buton gizlenir.';
comment on column public.stores.gallery_action_href is
  'Galeri aksiyon butonunun hedefi. Yalnız http/https veya sayfa içi #çapa kabul edilir.';

-- ── Blog bölüm başlıkları ───────────────────────────────────────────────────
alter table public.stores
  add column if not exists blog_section_kicker text,
  add column if not exists blog_section_title  text;

comment on column public.stores.blog_section_kicker is
  'Blog bölümü üst başlığı, örn. "Teknik rehber". NULL ise vitrinCopy varsayılanı.';
comment on column public.stores.blog_section_title is
  'Blog bölümü başlığı. NULL ise vitrinCopy varsayılanı.';

-- ── SSS bölüm başlıkları ────────────────────────────────────────────────────
alter table public.stores
  add column if not exists faq_section_kicker      text,
  add column if not exists faq_section_title       text,
  add column if not exists faq_section_description text;

comment on column public.stores.faq_section_kicker is
  'SSS bölümü üst başlığı. NULL ise vitrinCopy varsayılanı.';
comment on column public.stores.faq_section_title is
  'SSS bölümü başlığı. NULL ise vitrinCopy varsayılanı.';
comment on column public.stores.faq_section_description is
  'SSS bölümü açıklama metni. NULL ise gösterilmez.';

-- ── İletişim ────────────────────────────────────────────────────────────────
alter table public.stores
  add column if not exists map_label text;

comment on column public.stores.map_label is
  'Harita kartında gösterilen adres etiketi. NULL ise address alanı kullanılır.';

-- ── Bölüm görünürlüğü ───────────────────────────────────────────────────────
-- Sahip bir bölümü kapatabilsin. Boş nesne = mevcut davranış (bölüm yalnız
-- verisi boşsa gizlenir). Anahtar yazılmışsa sahibin kararı üstün gelir.
-- Beklenen anahtarlar: categories, products, about, gallery, blog, faq, contact
-- Örnek: {"blog": false, "gallery": true}
alter table public.stores
  add column if not exists section_visibility jsonb not null default '{}'::jsonb;

comment on column public.stores.section_visibility is
  'Bölüm açık/kapalı kararı. Boş nesne = veri doluluğuna göre otomatik. Anahtar varsa sahibin kararı üstündür. Anahtarlar: categories, products, about, gallery, blog, faq, contact.';

-- Not: RLS politikalarına dokunulmadı. Bu kolonlar mevcut stores satırının
-- parçasıdır ve mevcut okuma politikalarıyla birlikte gelir. Müşteri
-- yanıtına girmeleri istendiğinde public_web tarafındaki PUBLIC_STORE_SELECT
-- listesine eklenmeleri gerekir (Commit 10).
