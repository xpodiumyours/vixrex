-- ============================================================================
-- VIXREX CORE — kalıcı hesap sahipliği sözleşmesi
-- ============================================================================
-- NEDEN VAR (2026-08-26, canlı veriyle doğrulandı)
--
-- Ölçüm: stores tablosunda 29 satır var, user_id DOLU olan satır sayısı 0.
-- auth.users'ta 175 kullanıcı var, 172'si anonim. Yani bugüne kadar HİÇBİR
-- vitrin bir hesaba bağlanmadı. Zincirin her halkası ayrı ayrı kırıktı:
--
--   1) AuthService.getStoreForCurrentUser() `stores` üzerinde doğrudan
--      `.eq('user_id', ...)` filtreliyor. V-09 (20260818050000) o kolonun
--      SELECT'ini authenticated'ten revoke etti; PostgreSQL WHERE'de geçen
--      kolon için de SELECT yetkisi arar — sorgunun TAMAMI 42501 ile
--      düşüyor. 20260820210000 aynı hatayı Keşfet ve
--      StorePublishedInfoLookupService için düzeltmişti, bu çağrı atlanmış.
--
--   2) link_store_to_user tek-vitrin kuralını hiç uygulamıyordu. Aynı
--      kullanıcı birden çok vitrin bağlayabilirdi; getStoreForCurrentUser
--      `.maybeSingle()` kullandığı için ikinci vitrin kullanıcıyı tamamen
--      kilitlerdi (PGRST116).
--
--   3) Uygulama açılışta HERKESE anonim oturum açıyor (main.dart
--      _oturumuGuvenceyeAl). Anonim kullanıcı da Postgres'e göre
--      `authenticated` ve auth.uid()'i var — eski link_store_to_user bu
--      kimliğe vitrin bağlayabilirdi. O andan sonra kullanıcı gerçek Google
--      hesabıyla girse bile vitrin ARTIK SAHİPLİ olduğu için hiçbir zaman
--      geri alınamazdı. Kalıcı hesap kuralı bunu açıkça yasaklar.
--
--   4) "Bu vitrini kirala" ile üretilen klonun edit_token'ı 24 saatlik
--      (V-15, 20260824050000). Kiralanan vitrin bir hesaba bağlansa bile
--      ertesi gün düzenlenemez hale geliyordu. Sahiplik kalıcıysa token da
--      kalıcı olmalı — claim anında 1 yıla uzatılır (create_store_with_token
--      ile aynı süre).
--
--   5) Yeni cihazda oturum açan sahip vitrinin slug'ını bulabiliyor
--      (get_own_published_store) ama edit_token'ı YALNIZ cihaz belleğinden
--      okunuyordu (StorePublishedInfoLookupService.lookup). Yeni cihazda o
--      bellek boş → canEditRemote false → OwnerPreviewService taslak
--      dalına düşüp YENİ bir vitrin satırı açıyordu. Web'de yazılan çalışma
--      taslağı (store_working_drafts) da hiç okunmuyordu.
--
-- NE YAPAR
--   A) stores(user_id) üzerinde kısmi UNIQUE index — tek-vitrin kuralının
--      tek gerçek garantisi. Uygulama katmanındaki kontrol yarış koşulunda
--      kaybeder, index kaybetmez. (Canlıda çoklu sahiplik yok, ölçüldü:
--      coklu_vitrinli_kullanici = 0 — index güvenle eklenebilir.)
--   B) is_permanent_user(): anonim oturumu kalıcı hesaptan ayırır.
--   C) claim_store_for_user(): sahiplenme. Atomik, tek-vitrin kurallı,
--      anonim oturuma kapalı, token süresini kalıcıya çeker.
--   D) bootstrap_owner_state(): "yeni cihazda açılış" tek çağrısı. Vitrin +
--      edit_token + çalışma taslağı tek yerden döner.
--   E) link_store_to_user(): eski APK'lar için boolean saran ince kabuk —
--      imzası ve dönüş tipi korunur, içeride C'yi çağırır.
-- ============================================================================

BEGIN;

-- ── A) Tek-vitrin kuralı: veritabanı garantisi ──────────────────────────────
-- Kısmi index: user_id NULL olan (sahipsiz taslak/kiralık) satırlar sınırsız
-- kalabilir, yalnız sahiplenilmiş satırlar kullanıcı başına tek olabilir.
CREATE UNIQUE INDEX IF NOT EXISTS "stores_tek_vitrin_per_user"
  ON "public"."stores" ("user_id")
  WHERE "user_id" IS NOT NULL;

COMMENT ON INDEX "public"."stores_tek_vitrin_per_user" IS
  'VIXREX CORE tek-vitrin kuralı: bir kalıcı hesap en fazla bir vitrine
   sahip olabilir. Sahipsiz (user_id IS NULL) satırlar kapsam dışı.';

-- ── B) Anonim oturum ≠ kalıcı hesap ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION "public"."is_permanent_user"()
RETURNS boolean
LANGUAGE "sql"
STABLE
SET "search_path" TO 'pg_catalog', 'public'
AS $$
  select auth.uid() is not null
     and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false;
$$;

COMMENT ON FUNCTION "public"."is_permanent_user"() IS
  'Çağıran kalıcı bir hesapla mı giriş yaptı? Uygulama açılışta herkese
   anonim oturum açtığı için (main.dart) auth.uid() tek başına "hesap var"
   demek DEĞİL — sahiplik kararlarında bu fonksiyon kullanılır.';

REVOKE ALL ON FUNCTION "public"."is_permanent_user"() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."is_permanent_user"() TO "authenticated";

-- ── C) Sahiplenme sözleşmesi ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION "public"."claim_store_for_user"("p_edit_token" "text")
RETURNS "jsonb"
LANGUAGE "plpgsql"
SECURITY DEFINER
SET "search_path" TO 'pg_catalog', 'public', 'extensions'
AS $$
declare
  v_user_id uuid := auth.uid();
  v_token text := pg_catalog.btrim(coalesce(p_edit_token, ''));
  v_mevcut_slug text;
  v_mevcut_token text;
  v_slug text;
begin
  if v_user_id is null then
    raise exception 'UNAUTHORIZED' using errcode = 'P0001';
  end if;

  -- Anonim oturum vitrin sahiplenemez: sahiplendiği an vitrin kalıcı olarak
  -- o geçici kimliğe kilitlenir ve gerçek hesap bir daha alamaz.
  if not public.is_permanent_user() then
    return jsonb_build_object('ok', false, 'reason', 'ANONYMOUS_SESSION');
  end if;

  if pg_catalog.length(v_token) < 24 then
    return jsonb_build_object('ok', false, 'reason', 'INVALID_TOKEN');
  end if;

  -- Tek-vitrin kuralı: kullanıcının zaten bir vitrini var mı?
  select slug, edit_token into v_mevcut_slug, v_mevcut_token
  from public.stores
  where user_id = v_user_id
  limit 1;

  if v_mevcut_slug is not null then
    -- Aynı vitrin ikinci kez sahiplenilmeye çalışılıyorsa bu hata değil:
    -- tekrar giriş yapan kullanıcının normal akışı. Sessizce başarı döner.
    if v_mevcut_token = v_token then
      return jsonb_build_object('ok', true, 'slug', v_mevcut_slug, 'reason', 'ALREADY_MINE');
    end if;
    return jsonb_build_object(
      'ok', false, 'reason', 'ALREADY_OWNS_STORE', 'slug', v_mevcut_slug
    );
  end if;

  -- Kontrol + atama TEK statement: eşzamanlı iki istekte yalnız biri
  -- user_id IS NULL koşulunu sağlar. Sahiplik kalıcı olduğu için token
  -- süresi de kalıcıya çekilir (kiralık klonun 24 saatlik TTL'i, V-15).
  update public.stores
  set user_id = v_user_id,
      edit_token_expires_at = now() + interval '1 year'
  where edit_token = v_token
    and user_id is null
    and is_demo = false
    and (edit_token_expires_at is null or edit_token_expires_at > now())
  returning slug into v_slug;

  if v_slug is null then
    return jsonb_build_object('ok', false, 'reason', 'NOT_CLAIMABLE');
  end if;

  return jsonb_build_object('ok', true, 'slug', v_slug, 'reason', 'CLAIMED');
exception
  -- Kısmi unique index ihlali: aynı anda ikinci bir claim kazandı.
  when unique_violation then
    return jsonb_build_object('ok', false, 'reason', 'ALREADY_OWNS_STORE');
end;
$$;

COMMENT ON FUNCTION "public"."claim_store_for_user"("text") IS
  'Sahipsiz, demo olmayan, token''ı geçerli bir vitrini kalıcı hesaba atomik
   olarak bağlar. Tek-vitrin kuralı + anonim oturum yasağı + token süresini
   1 yıla uzatma tek çağrıda. jsonb döner: {ok, slug, reason}.';

REVOKE ALL ON FUNCTION "public"."claim_store_for_user"("text") FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."claim_store_for_user"("text") TO "authenticated";

-- ── D) Yeni cihazda açılış: tek çağrıda tam durum ──────────────────────────
CREATE OR REPLACE FUNCTION "public"."bootstrap_owner_state"()
RETURNS "jsonb"
LANGUAGE "plpgsql"
SECURITY DEFINER
SET "search_path" TO 'pg_catalog', 'public', 'extensions'
AS $$
declare
  v_user_id uuid := auth.uid();
  v_store public.stores;
  v_draft_data jsonb;
  v_draft_version bigint;
  v_base_live_version bigint;
  v_draft_updated_at timestamptz;
  v_token text;
begin
  if v_user_id is null or not public.is_permanent_user() then
    return jsonb_build_object('has_store', false, 'reason', 'ANONYMOUS_SESSION');
  end if;

  select * into v_store
  from public.stores
  where user_id = v_user_id
  order by created_at asc
  limit 1;

  if v_store.id is null then
    return jsonb_build_object('has_store', false, 'reason', 'NO_STORE');
  end if;

  -- Sahip kimliğini JWT ile kanıtladı; token'ı süresi dolmuşsa veya hiç
  -- yoksa burada tazelenir — aksi halde kendi vitrinini düzenleyemez.
  v_token := pg_catalog.btrim(coalesce(v_store.edit_token, ''));
  if v_token = ''
     or (v_store.edit_token_expires_at is not null
         and v_store.edit_token_expires_at <= now()) then
    v_token := encode(gen_random_bytes(32), 'hex');
    update public.stores
    set edit_token = v_token,
        edit_token_expires_at = now() + interval '1 year'
    where id = v_store.id;
    -- version trigger'ı satırı ilerletti; canlı sürümü yeniden oku.
    select * into v_store from public.stores where id = v_store.id;
  end if;

  select draft_data, draft_version, base_live_version, updated_at
  into v_draft_data, v_draft_version, v_base_live_version, v_draft_updated_at
  from public.store_working_drafts
  where store_id = v_store.id;

  return jsonb_build_object(
    'has_store', true,
    'reason', 'OK',
    'slug', v_store.slug,
    'name', v_store.name,
    'edit_token', v_token,
    'is_published', v_store.is_published,
    'is_store', v_store.is_store,
    'live_version', v_store.version,
    'store_data', public.strip_draft_secrets(to_jsonb(v_store)),
    'has_draft', v_draft_data is not null,
    'draft_data', public.strip_draft_secrets(coalesce(v_draft_data, '{}'::jsonb)),
    'draft_version', v_draft_version,
    'base_live_version', v_base_live_version,
    'draft_stale', (v_draft_data is not null and v_base_live_version <> v_store.version),
    -- Cihazdaki taslağın sunucudakinden yeni olup olmadığını karşılaştırmak
    -- için (bkz. OwnerBootstrapService.cihazaUygula): jsonb içine gömmek
    -- yerine üst seviyede, açıkça.
    'live_updated_at', v_store.updated_at,
    'draft_updated_at', v_draft_updated_at
  );
end;
$$;

COMMENT ON FUNCTION "public"."bootstrap_owner_state"() IS
  'Kalıcı hesapla giriş yapan sahibin tam durumu: vitrin verisi + kendi
   edit_token''ı + varsa web''de bırakılmış çalışma taslağı. Yeni cihazda
   açılışın TEK kaynağı. edit_token yalnız vitrinin kendi sahibine döner;
   store_data/draft_data strip_draft_secrets''ten geçer.';

REVOKE ALL ON FUNCTION "public"."bootstrap_owner_state"() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."bootstrap_owner_state"() TO "authenticated";

-- ── D2) Hesaplı kiralama: vitrin sahipli doğsun ────────────────────────────
-- "Bu vitrini kirala" bugüne kadar YALNIZ misafir yoluyla çalışıyordu:
-- /api/rent-demo servis rolüyle sahipsiz bir klon açıyor, tarayıcıya 15
-- dakikalık bir sahip oturumu çerezi bırakıyor, uygulama ise slug'ı da
-- token'ı da hiç öğrenmiyordu (AppRouter.navigateToRentDemo yalnız link
-- açıyor). Sonuç: kiralanan vitrin hiçbir hesaba bağlanamıyor ve 24 saatlik
-- token süresi dolunca (V-15) bir daha düzenlenemiyordu.
--
-- Bu fonksiyon giriş yapmış kullanıcı için klonu SAHİPLİ doğurur: user_id
-- baştan atanır, token 1 yıllık olur, tek-vitrin kuralı uygulanır.
-- MİSAFİR YOLU DOKUNULMADI: start_demo_trial ve /api/rent-demo aynen durur.
--
-- Kötüye kullanım: 20260815180000 clone_demo_store_as_draft'ı anon/
-- authenticated'ten kapatmıştı; bu fonksiyon SECURITY DEFINER olduğu için
-- klonlamayı içeriden yapar, çağıran rol hâlâ klon fonksiyonuna erişemez.
-- Asıl sınır ise oran limitinden güçlü: kalıcı hesap zorunlu + hesap başına
-- tek vitrin ⇒ bir hesap en fazla bir klon üretebilir. Saatlik limit yine de
-- ikinci kemer olarak duruyor (başarısız denemeler için).
CREATE OR REPLACE FUNCTION "public"."rent_demo_for_account"("p_source_slug" "text")
RETURNS "jsonb"
LANGUAGE "plpgsql"
SECURITY DEFINER
SET "search_path" TO 'pg_catalog', 'public', 'extensions'
AS $$
declare
  v_user_id uuid := auth.uid();
  v_source text := pg_catalog.btrim(coalesce(p_source_slug, ''));
  v_mevcut_slug text;
  v_new_slug text;
  v_edit_token text;
  v_attempt integer := 0;
  v_cloned boolean := false;
  v_allowed boolean;
  v_retry integer;
begin
  if v_user_id is null or not public.is_permanent_user() then
    return jsonb_build_object('ok', false, 'reason', 'ANONYMOUS_SESSION');
  end if;

  if v_source = '' then
    return jsonb_build_object('ok', false, 'reason', 'INVALID_SLUG');
  end if;

  select slug into v_mevcut_slug
  from public.stores where user_id = v_user_id limit 1;
  if v_mevcut_slug is not null then
    return jsonb_build_object(
      'ok', false, 'reason', 'ALREADY_OWNS_STORE', 'slug', v_mevcut_slug
    );
  end if;

  select allowed, retry_after_seconds into v_allowed, v_retry
  from public.consume_assistant_request(
    'rent_account:' || v_user_id::text, 5, 3600
  );
  if not v_allowed then
    return jsonb_build_object(
      'ok', false, 'reason', 'RATE_LIMITED', 'retry_after', v_retry
    );
  end if;

  if not exists (
    select 1 from public.stores
    where slug = v_source and is_demo = true and is_published = true
  ) then
    return jsonb_build_object('ok', false, 'reason', 'SOURCE_NOT_FOUND');
  end if;

  while not v_cloned and v_attempt < 3 loop
    v_attempt := v_attempt + 1;
    v_new_slug := v_source || '-' || encode(gen_random_bytes(4), 'hex');
    v_edit_token := encode(gen_random_bytes(32), 'hex');
    begin
      perform public.clone_demo_store_as_draft(v_source, v_new_slug, v_edit_token);
      v_cloned := true;
    exception
      when unique_violation then
        if v_attempt >= 3 then
          return jsonb_build_object('ok', false, 'reason', 'SLUG_GENERATION_FAILED');
        end if;
    end;
  end loop;

  -- Klon sahipsiz ve 24 saatlik token'la doğar (clone_demo_store_as_draft);
  -- aynı transaction'da sahiplendirilir ve kalıcı süreye çekilir.
  update public.stores
  set user_id = v_user_id,
      edit_token_expires_at = now() + interval '1 year'
  where slug = v_new_slug;

  return jsonb_build_object(
    'ok', true, 'reason', 'RENTED', 'slug', v_new_slug, 'edit_token', v_edit_token
  );
exception
  when unique_violation then
    -- Tek-vitrin index'i: aynı anda ikinci bir kiralama kazandı. Bu blok
    -- geri alınır, yarım klon kalmaz.
    return jsonb_build_object('ok', false, 'reason', 'ALREADY_OWNS_STORE');
end;
$$;

COMMENT ON FUNCTION "public"."rent_demo_for_account"("text") IS
  'Giriş yapmış kullanıcı için "bu vitrini kirala": klon SAHİPLİ doğar,
   token 1 yıllık olur, tek-vitrin kuralı uygulanır. Misafir yolu
   (start_demo_trial + /api/rent-demo) değişmedi.';

REVOKE ALL ON FUNCTION "public"."rent_demo_for_account"("text") FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."rent_demo_for_account"("text") TO "authenticated";

-- ── E) Eski istemciler için geriye dönük kabuk ─────────────────────────────
-- Yayındaki APK'lar link_store_to_user'ı boolean bekleyerek çağırıyor.
-- İmza ve dönüş tipi aynen korunur; kural motoru artık tek yerde.
CREATE OR REPLACE FUNCTION "public"."link_store_to_user"("p_edit_token" "text")
RETURNS boolean
LANGUAGE "sql"
SECURITY INVOKER
SET "search_path" TO 'pg_catalog', 'public'
AS $$
  select coalesce((public.claim_store_for_user(p_edit_token) ->> 'ok')::boolean, false);
$$;

COMMENT ON FUNCTION "public"."link_store_to_user"("text") IS
  'GERİYE DÖNÜK KABUK — yeni kod claim_store_for_user kullanır. Eski APK''lar
   boolean beklediği için imza korunuyor; kural motoru claim_store_for_user.';

REVOKE ALL ON FUNCTION "public"."link_store_to_user"("text") FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."link_store_to_user"("text") TO "authenticated";

-- ── F) REGRESYON ONARIMI: kiralanan vitrin ürünsüz geliyordu ───────────────
-- ÖLÇÜM (2026-08-26, canlıda): kaynak demo vitrinde 6 ürün var, kiralama
-- sonrası klonda 0 ürün, 0 kategori. Hem misafir yolunda (start_demo_trial)
-- hem hesaplı yolda aynı sonuç.
--
-- KÖK NEDEN: 20260815000000_clone_demo_store_products.sql
-- clone_demo_store_as_draft'a kategori+ürün kopyalamayı eklemişti. Sonra
-- 20260824050000 (V-15 token TTL, PR #340) aynı fonksiyonu yalnız
-- `edit_token_expires_at` eklemek için CREATE OR REPLACE etti — ama gövdeyi
-- ürün kopyalama ÖNCESİ sürümden aldı. Kategori/ürün kopyalama ve
-- `cloned_from_slug` sessizce düştü. Migration defteri "uygulandı" diyor,
-- fonksiyon eski. 24 Ağustos'tan beri kiralanan her vitrin boş doğuyor.
--
-- ÇÖZÜM: iki sürümün birleşimi — ürün/kategori kopyalama geri, V-15'in 24
-- saatlik token süresi korunarak. Ayrıca fonksiyon aynı transaction'da
-- ikinci kez çağrılabilir hale getirildi (geçici tablo çakışıyordu).
CREATE OR REPLACE FUNCTION "public"."clone_demo_store_as_draft"(
  "p_source_slug" "text",
  "p_new_slug" "text",
  "p_edit_token" "text"
)
RETURNS void
LANGUAGE "plpgsql"
SECURITY DEFINER
SET "search_path" TO 'pg_catalog', 'public', 'extensions'
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
    and is_demo = true
    and is_published = true;

  if v_source_id is null then
    raise exception 'SOURCE_NOT_FOUND';
  end if;

  insert into public.stores (
    slug, edit_token, user_id, cloned_from_slug,
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
    edit_token_expires_at  -- V-15: 24 saat (hesaba bağlanınca 1 yıla çıkar)
  )
  select
    pg_catalog.btrim(p_new_slug), pg_catalog.btrim(p_edit_token), null,
    pg_catalog.btrim(p_source_slug),
    name, business_type, description, corporate_bio,
    whatsapp, phone, email, hero_badge, instagram, website, address,
    theme, theme_preset, 'draft',
    marketplace_links, gallery_items, products, product_categories, offerings,
    catalog_link, references_link, vcard_link, shelf_image_url, logo_url,
    working_hours, false, is_store, kategori,
    latitude, longitude, location_accuracy_meters, location_source,
    province_code, province_name, district_code, district_name,
    google_business_link,
    featured_banner_label, featured_banner_title, featured_banner_description,
    featured_banner_image_url, featured_banner_price_text,
    faq_items, about_kicker, about_title, about_image_url, about_image_caption,
    about_values, gallery_section_kicker, gallery_section_title,
    show_storefront_rating, show_directions_link,
    now() + interval '24 hours'
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

COMMENT ON FUNCTION "public"."clone_demo_store_as_draft"("text", "text", "text") IS
  'Demo vitrini taslak klon olarak kopyalar — kategoriler ve ürünler dahil
   (20260815000000''in gövdesi), token süresi 24 saat (V-15). 20260824050000
   ürün kopyalamayı kazara düşürmüştü, 20260826000000 geri getirdi.';

-- 20260815180000 bu fonksiyonu anon/authenticated/PUBLIC''e kapatmıştı;
-- CREATE OR REPLACE yetkileri korur, yine de açıkça tekrarlıyoruz.
REVOKE EXECUTE ON FUNCTION "public"."clone_demo_store_as_draft"("text", "text", "text")
  FROM PUBLIC, "anon", "authenticated";

COMMIT;

NOTIFY pgrst, 'reload schema';
