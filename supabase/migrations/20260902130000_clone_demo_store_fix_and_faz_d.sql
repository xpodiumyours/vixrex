-- ============================================================================
-- KRİTİK REGRESYON DÜZELTMESİ + Faz D2 (Tek Asistan planı, 2026-09-02)
-- ============================================================================
-- BULUNAN SORUN (canlı fonksiyon tanımı okunarak doğrulandı):
--   20260901060000_extend_demo_trial_token_14_days.sql, clone_demo_store_
--   as_draft'ı 14 günlük token için CREATE OR REPLACE ederken gövdeyi
--   20260815000000/20260826000000'ın ürün+kategori kopyalama düzeltmesi
--   ÖNCESİNDEKİ bir sürümden almış — cloned_from_slug kolonu ve
--   _kategori_esleme temp table + products/product_categories INSERT'leri
--   TAMAMEN YOK. Bu, 20260826000000'ın kendi başlığında anlattığı AYNI
--   regresyonun ÜÇÜNCÜ tekrarı (V-15 → 20260826000000 düzeltti → bu
--   migration'la sessizce tekrar düştü).
--
--   Ölçüm (2026-09-02, canlı DB): 21 mevcut klonun HEPSİ 6 ürün/3 kategori
--   ve cloned_from_slug taşıyor — çünkü hepsi ESKİ (düzeltilmiş) fonksiyon
--   canlıyken oluşturuldu (son klon 2026-09-01 17:14). Şu an canlı olan
--   BOZUK sürüm henüz hiç gerçek kiralamaya maruz kalmadı — ama bir
--   sonraki "Kirala" tıklaması (Faz C3 dahil) ÜRÜNSÜZ, KATEGORİSİZ bir
--   vitrin doğurur. Bu migration hem regresyonu düzeltir hem 14 günlük
--   token'ı korur.
--
-- FAZ D2 EKLENTİSİ (aynı fonksiyona, aynı transaction'da):
--   Kural seti onaylandı: GERÇEK işletme kimliği (ad, whatsapp, adres,
--   telefon, e-posta, çalışma saatleri, logo, il/ilçe, GPS, Google
--   İşletme linki) klonda ARTIK KOPYALANMAZ — boş/null başlar. Önceden
--   şablonun (ör. "kiralik-kuafor" demosu, gerçek "905351234569" WhatsApp
--   numarasıyla) kimliği yeni kiracıya sessizce geçiyordu; owner panelinin
--   "hazır" sayması ve esnafın fark etmeden yayınlaması mümkündü — bu artık
--   olamaz (mevcut zorunlu-alan/hazırlık motoru boş gördüğü an sorar).
--   Kampanya bandı (bant*) de aynı nedenle null: gerçek kampanya yoksa
--   VitrinProfileView zaten boşsa bölümü gizliyor (featuredLabel ||
--   featuredTitle kontrolü) — ekstra bir section_visibility yazmaya
--   gerek yok.
--   Kategoriye-özel "otomatik" metinler (hero_badge, description, bölüm
--   başlıkları vb.) BU migration'da hâlâ şablondan kopyalanıyor — Next.js
--   tarafındaki otomatikVitrinIcerik.ts kataloğuyla üzerine yazmak ayrı,
--   sonraki bir adım (D3), burada kapsam dışı.
-- ============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.clone_demo_store_as_draft(
  p_source_slug text,
  p_new_slug text,
  p_edit_token text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, extensions
AS $$
declare
  v_source_id uuid;
  v_new_id uuid;
begin
  if p_new_slug is null or pg_catalog.length(pg_catalog.btrim(p_new_slug)) = 0 then
    raise exception 'INVALID_SLUG';
  end if;
  if p_edit_token is null or pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 then
    raise exception 'INVALID_EDIT_TOKEN';
  end if;

  select id into v_source_id
  from public.stores
  where slug = pg_catalog.btrim(p_source_slug)
    and is_demo = true;

  if v_source_id is null then
    raise exception 'SOURCE_NOT_FOUND';
  end if;

  insert into public.stores (
    slug, edit_token, user_id, cloned_from_slug,
    -- ── GERÇEK işletme kimliği: BİLEREK kopyalanmıyor (Faz D) ──────────
    name, business_type, description, corporate_bio,
    whatsapp, phone, email, hero_badge, instagram, website, address,
    theme, theme_preset, status,
    marketplace_links, gallery_items, products, product_categories, offerings,
    catalog_link, references_link, vcard_link, shelf_image_url, logo_url,
    working_hours, is_published, is_store, kategori,
    latitude, longitude, location_accuracy_meters, location_source,
    province_code, province_name, district_code, district_name,
    google_business_link,
    featured_banner_label, featured_banner_title, featured_banner_description,
    featured_banner_image_url, featured_banner_price_text,
    faq_items, about_kicker, about_title, about_image_url, about_image_caption,
    about_values, gallery_section_kicker, gallery_section_title,
    show_storefront_rating, show_directions_link,
    edit_token_expires_at
  )
  select
    pg_catalog.btrim(p_new_slug), pg_catalog.btrim(p_edit_token), null,
    pg_catalog.btrim(p_source_slug),
    -- name/whatsapp/address NOT NULL — boş string, gerçek değer bekler.
    '', business_type, description, corporate_bio,
    '', null, null, hero_badge, instagram, website, '',
    theme, theme_preset, 'draft',
    marketplace_links, gallery_items, products, product_categories, offerings,
    catalog_link, references_link, vcard_link, shelf_image_url, null,
    null, false, is_store, kategori,
    null, null, null, null,
    null, null, null, null,
    null,
    -- Kampanya bandı: gerçek kampanya değilse null — sahte fiyat/indirim
    -- iddiası yeni kiracının müşterisini yanıltmasın.
    null, null, null, null, null,
    faq_items, about_kicker, about_title, about_image_url, about_image_caption,
    about_values, gallery_section_kicker, gallery_section_title,
    show_storefront_rating, show_directions_link,
    now() + interval '14 days'
  from public.stores
  where id = v_source_id
  returning id into v_new_id;

  -- Aynı transaction'da ikinci klon: geçici tablo hâlâ duruyor olabilir.
  drop table if exists _kategori_esleme;
  create temporary table _kategori_esleme (
    eski_id uuid primary key,
    yeni_id uuid not null
  ) on commit drop;

  insert into _kategori_esleme (eski_id, yeni_id)
  select id, gen_random_uuid()
  from public.product_categories
  where store_id = v_source_id;

  insert into public.product_categories (
    id, store_id, name, slug, sort_order, is_active
  )
  select e.yeni_id, v_new_id, k.name, k.slug, k.sort_order, k.is_active
  from public.product_categories k
  join _kategori_esleme e on e.eski_id = k.id
  where k.store_id = v_source_id;

  -- category_id varsa yeni kategori id'sine eşlenir, yoksa null kalır.
  insert into public.products (
    id, store_id, category_id, source_type, external_product_id,
    name, slug, description, price_amount, price_text, currency,
    stock_quantity, stock_status, image_urls, metadata,
    seo_title, seo_description, is_visible, is_active, sort_order,
    brand, barcode, vat_rate, variants, old_price_amount, badge_tag,
    fulfillment_region
  )
  select
    gen_random_uuid(), v_new_id, e.yeni_id, p.source_type,
    p.external_product_id,
    p.name, p.slug, p.description, p.price_amount, p.price_text, p.currency,
    p.stock_quantity, p.stock_status, p.image_urls, p.metadata,
    p.seo_title, p.seo_description, p.is_visible, p.is_active, p.sort_order,
    p.brand, p.barcode, p.vat_rate, p.variants, p.old_price_amount,
    p.badge_tag, p.fulfillment_region
  from public.products p
  left join _kategori_esleme e on e.eski_id = p.category_id
  where p.store_id = v_source_id;
end;
$$;

COMMENT ON FUNCTION public.clone_demo_store_as_draft(text, text, text) IS
  'Demo vitrini taslak klon olarak kopyalar — kategoriler ve ürünler dahil,
   edit_token 14 gün (deneme süresi). GERÇEK işletme kimliği (ad, iletişim,
   adres, saatler, logo, GPS, kampanya bandı) BİLEREK kopyalanmaz — Faz D
   kural seti: şablon sahibinin verisi yeni kiracıya sızmasın, mevcut
   zorunlu-alan motoru boş gördüğü anda gerçek bilgi ister. Kalıcı
   hesaplarda rent_demo_for_account token''ı 1 yıla çeker.';

COMMIT;

NOTIFY pgrst, 'reload schema';
