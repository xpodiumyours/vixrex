-- ============================================================================
-- vitrin_views kaynağı: trafik kaynağı değerlerinin genişletilmesi
-- (issue #327 ailesi — "esnaf nereden müşteri geliyor" sorusu)
--
-- NE YAPAR:
--   1) record_vitrin_view fonksiyonundaki p_source beyaz listesini genişletir.
--   2) vitrin_views_source_check kısıtını aynı listeyle değiştirir.
--
--   Eski değerler (KORUNUR): direct, qr, share, unknown
--   Yeni değerler          : google, instagram, facebook, whatsapp,
--                            twitter, tiktok, diger_site
--
-- NEDEN:
--   VitrinViewTracker ziyaretçinin document.referrer'ını çözecek şekilde
--   güncelleniyor; Google/Instagram/Facebook'tan gelen trafik artık
--   gerçek kaynağıyla yazılabilsin. Bugün referrer dolu olsa bile aşağıdaki
--   fonksiyon içi whitelist ve tablodaki CHECK kısıtı bilinmeyen her değeri
--   'unknown'a düşürüyor — iki nesnenin İKİSİ BİRDEN güncellenmeden ön yüz
--   değişikliği işe yaramaz (yalnız CHECK gevşetilirse fonksiyon yeni
--   değerleri sessizce 'unknown'a çevirmeye devam ederdi).
--
--   Değer gerekçeleri:
--     google/instagram/facebook/tiktok → sosyal arama ve sosyal medya
--       platformları; hostname sonekiyle eşleşir (google.com.tr dahil).
--     whatsapp/wa.me → WhatsApp durumları ve grup paylaşimları.
--     twitter → t.co kısaltması, twitter.com ve x.com.
--     diger_site → yukarıdakiler dışında gerçek bir dış site; "bilinmeyen"
--       ile karışmasın diye ayrı değer (unknown = çözümlenemeyenreferrer vb.).
--
-- GARANTİLER:
--   - Mevcut 4 değer geçerli kalır; eski kayıtlar bozulmaz, geri dönüş için
--     bu dosyanın tersinin uygulanması yeterlidir (değer kümesi küçültülerek).
--   - Fonksiyonun imzası, SECURITY DEFINER, SET search_path TO '' disiplini
--     ve mevcut yetkileri (PUBLIC revoke + anon/service_role grant) aynen
--     korunur; CREATE OR REPLACE ayrıcalıkları silmez.
--   - Kısıt yeniden eklenirken mevcut satırlar doğrulanır; tabloda bugün
--     yalnız eski 4 değer bulunabildiği için ihlal oluşamaz.
--
-- DİKKAT / DAĞITIM SIRASI:
--   Bu dosya YAZILDI, UYGULANMADI. Canlıya açık onayla `supabase db push`
--   ile uygulanmalı; ön yüz değişikliği ancak bu migration canlıya geçtikten
--   SONRA deploy edilmelidir. Aksi sıralamada fonksiyon yeni kaynakları
--   'unknown'a düşürür (veri kaybı değil, sınıflandırma kaybı).
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."record_vitrin_view"("p_store_slug" "text", "p_session_key" "text", "p_source" "text" DEFAULT 'unknown'::"text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_store_id uuid;
  v_store_slug text;
  v_session_key text;
  v_source text;
  v_viewed_date date;
begin
  v_session_key := pg_catalog.btrim(coalesce(p_session_key, ''));

  if length(v_session_key) < 16 then
    return;
  end if;

  select s.id, s.slug
    into v_store_id, v_store_slug
  from public.stores s
  where s.slug = pg_catalog.btrim(coalesce(p_store_slug, ''))
    and s.is_published = true
  limit 1;

  if v_store_id is null then
    return;
  end if;

  v_source := lower(pg_catalog.btrim(coalesce(p_source, 'unknown')));

  if v_source not in (
    'direct', 'qr', 'share', 'unknown',
    'google', 'instagram', 'facebook', 'whatsapp', 'twitter', 'tiktok',
    'diger_site'
  ) then
    v_source := 'unknown';
  end if;

  v_viewed_date := (now() at time zone 'Europe/Istanbul')::date;

  insert into public.vitrin_views (
    store_id,
    store_slug,
    session_key,
    source,
    viewed_date
  ) values (
    v_store_id,
    v_store_slug,
    v_session_key,
    v_source,
    v_viewed_date
  )
  on conflict (store_id, session_key, viewed_date) do nothing;
end;
$$;


ALTER TABLE "public"."vitrin_views" DROP CONSTRAINT IF EXISTS "vitrin_views_source_check";

ALTER TABLE "public"."vitrin_views"
  ADD CONSTRAINT "vitrin_views_source_check"
  CHECK (("source" = ANY (
    ARRAY[
      'direct'::"text",
      'qr'::"text",
      'share'::"text",
      'unknown'::"text",
      'google'::"text",
      'instagram'::"text",
      'facebook'::"text",
      'whatsapp'::"text",
      'twitter'::"text",
      'tiktok'::"text",
      'diger_site'::"text"
    ]
  )));
