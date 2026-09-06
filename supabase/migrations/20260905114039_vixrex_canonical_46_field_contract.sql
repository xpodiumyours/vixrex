-- Vixrex Akıllı Motor — canonical 46-field authoritative DB contract.
--
-- GENERATED SNAPSHOT: tool/server_field_contract_uret.ts
-- SOURCE: shared/vitrin_alanlari.json <- public_web/src/lib/vitrinFieldSchema.ts
-- 46 alan listesi burada elle tasarlanmaz; canonical şemanın migration snapshot'ıdır.

create or replace function public.vixrex_storefront_field_contract(p_field_key text)
returns jsonb
language sql
immutable
set search_path = pg_catalog, public
as $$
  select case pg_catalog.btrim(coalesce(p_field_key, ''))
    when 'isletmeAdi' then '{"fieldKey":"isletmeAdi","column":"name","type":"metin","required":true,"minLength":2,"maxLength":60,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'heroRozet' then '{"fieldKey":"heroRozet","column":"hero_badge","type":"metin","required":false,"minLength":null,"maxLength":60,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'kisaTanitim' then '{"fieldKey":"kisaTanitim","column":"description","type":"uzunMetin","required":false,"minLength":null,"maxLength":300,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'konumMetni' then '{"fieldKey":"konumMetni","column":"hero_location_text","type":"metin","required":false,"minLength":null,"maxLength":60,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'kategori' then '{"fieldKey":"kategori","column":"kategori","type":"secim","required":true,"minLength":null,"maxLength":40,"min":null,"max":null,"options":["Giyim","Butik","Gıda","Fırın","Kozmetik","Dekorasyon","Elektronik","Kırtasiye","Kafe / Lokanta","Kuaför","Teknik Servis","Danışmanlık","Eğitim","Ev Temizlik","Spor / Fitness","Pet / Veteriner","Sağlık / Yaşam","Oto / Araç","Diğer"],"validation":null,"emptyValues":["diger","diğer"]}'::jsonb
    when 'isletmeTuru' then '{"fieldKey":"isletmeTuru","column":"business_type","type":"metin","required":false,"minLength":null,"maxLength":40,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'logo' then '{"fieldKey":"logo","column":"logo_url","type":"gorsel","required":false,"minLength":null,"maxLength":null,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'kapakGorseli' then '{"fieldKey":"kapakGorseli","column":"shelf_image_url","type":"gorsel","required":false,"minLength":null,"maxLength":null,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'whatsapp' then '{"fieldKey":"whatsapp","column":"whatsapp","type":"telefon","required":true,"minLength":null,"maxLength":null,"min":null,"max":null,"options":null,"validation":"tr_mobil","emptyValues":null}'::jsonb
    when 'telefon' then '{"fieldKey":"telefon","column":"phone","type":"telefon","required":false,"minLength":null,"maxLength":null,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'eposta' then '{"fieldKey":"eposta","column":"email","type":"eposta","required":false,"minLength":null,"maxLength":120,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'adres' then '{"fieldKey":"adres","column":"address","type":"uzunMetin","required":true,"minLength":null,"maxLength":200,"min":null,"max":null,"options":null,"validation":"adres","emptyValues":null}'::jsonb
    when 'il' then '{"fieldKey":"il","column":"province_name","type":"metin","required":true,"minLength":null,"maxLength":60,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'ilce' then '{"fieldKey":"ilce","column":"district_name","type":"metin","required":true,"minLength":null,"maxLength":60,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'mahalle' then '{"fieldKey":"mahalle","column":"neighborhood_name","type":"metin","required":false,"minLength":null,"maxLength":60,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'haritaEtiketi' then '{"fieldKey":"haritaEtiketi","column":"map_label","type":"metin","required":false,"minLength":null,"maxLength":120,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'calismaSaatleri' then '{"fieldKey":"calismaSaatleri","column":"working_hours","type":"metin","required":false,"minLength":null,"maxLength":400,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'instagram' then '{"fieldKey":"instagram","column":"instagram","type":"metin","required":false,"minLength":null,"maxLength":30,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'website' then '{"fieldKey":"website","column":"website","type":"url","required":false,"minLength":null,"maxLength":null,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'haritaLinki' then '{"fieldKey":"haritaLinki","column":"google_business_link","type":"url","required":false,"minLength":null,"maxLength":null,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'enlem' then '{"fieldKey":"enlem","column":"latitude","type":"sayi","required":false,"minLength":null,"maxLength":null,"min":-90,"max":90,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'boylam' then '{"fieldKey":"boylam","column":"longitude","type":"sayi","required":false,"minLength":null,"maxLength":null,"min":-180,"max":180,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'kategoriBolumBaslik' then '{"fieldKey":"kategoriBolumBaslik","column":"category_section_title","type":"metin","required":false,"minLength":null,"maxLength":60,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'urunBolumBaslik' then '{"fieldKey":"urunBolumBaslik","column":"product_section_title","type":"metin","required":false,"minLength":null,"maxLength":60,"min":null,"maxLength":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'bantEtiket' then '{"fieldKey":"bantEtiket","column":"featured_banner_label","type":"metin","required":false,"minLength":null,"maxLength":40,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'bantBaslik' then '{"fieldKey":"bantBaslik","column":"featured_banner_title","type":"metin","required":false,"minLength":null,"maxLength":90,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'bantAciklama' then '{"fieldKey":"bantAciklama","column":"featured_banner_description","type":"uzunMetin","required":false,"minLength":null,"maxLength":200,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'bantGorsel' then '{"fieldKey":"bantGorsel","column":"featured_banner_image_url","type":"gorsel","required":false,"minLength":null,"maxLength":null,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'bantFiyat' then '{"fieldKey":"bantFiyat","column":"featured_banner_price_text","type":"metin","required":false,"minLength":null,"maxLength":30,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'hakkindaUstBaslik' then '{"fieldKey":"hakkindaUstBaslik","column":"about_kicker","type":"metin","required":false,"minLength":null,"maxLength":40,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'hakkindaBaslik' then '{"fieldKey":"hakkindaBaslik","column":"about_title","type":"metin","required":false,"minLength":null,"maxLength":90,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'hakkindaMetin' then '{"fieldKey":"hakkindaMetin","column":"corporate_bio","type":"uzunMetin","required":false,"minLength":null,"maxLength":1200,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'hakkindaGorsel' then '{"fieldKey":"hakkindaGorsel","column":"about_image_url","type":"gorsel","required":false,"minLength":null,"maxLength":null,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'hakkindaGorselAlt' then '{"fieldKey":"hakkindaGorselAlt","column":"about_image_caption","type":"metin","required":false,"minLength":null,"maxLength":120,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'galeriUstBaslik' then '{"fieldKey":"galeriUstBaslik","column":"gallery_section_kicker","type":"metin","required":false,"minLength":null,"maxLength":40,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'galeriBaslik' then '{"fieldKey":"galeriBaslik","column":"gallery_section_title","type":"metin","required":false,"minLength":null,"maxLength":90,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'galeriAksiyonMetni' then '{"fieldKey":"galeriAksiyonMetni","column":"gallery_action_label","type":"metin","required":false,"minLength":null,"maxLength":40,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'galeriAksiyonLinki' then '{"fieldKey":"galeriAksiyonLinki","column":"gallery_action_href","type":"url","required":false,"minLength":null,"maxLength":null,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'blogUstBaslik' then '{"fieldKey":"blogUstBaslik","column":"blog_section_kicker","type":"metin","required":false,"minLength":null,"maxLength":40,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'blogBaslik' then '{"fieldKey":"blogBaslik","column":"blog_section_title","type":"metin","required":false,"minLength":null,"maxLength":90,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'sssUstBaslik' then '{"fieldKey":"sssUstBaslik","column":"faq_section_kicker","type":"metin","required":false,"minLength":null,"maxLength":40,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'sssBaslik' then '{"fieldKey":"sssBaslik","column":"faq_section_title","type":"metin","required":false,"minLength":null,"maxLength":90,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'sssAciklama' then '{"fieldKey":"sssAciklama","column":"faq_section_description","type":"uzunMetin","required":false,"minLength":null,"maxLength":200,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'puanGoster' then '{"fieldKey":"puanGoster","column":"show_storefront_rating","type":"acikKapali","required":false,"minLength":null,"maxLength":null,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'yolTarifiGoster' then '{"fieldKey":"yolTarifiGoster","column":"show_directions_link","type":"acikKapali","required":false,"minLength":null,"maxLength":null,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    when 'referansLinki' then '{"fieldKey":"referansLinki","column":"references_link","type":"url","required":false,"minLength":null,"maxLength":null,"min":null,"max":null,"options":null,"validation":null,"emptyValues":null}'::jsonb
    else null
  end;
$$;

comment on function public.vixrex_storefront_field_contract(text) is
  'Generated Vixrex storefront 46-field metadata contract. Canonical source: vitrinFieldSchema.ts.';

-- DB sınırı yalnız canonical/normalize edilmiş action değerlerini kabul eder.
-- Yerel TS/Dart validator kullanıcı girdisini normalize eder; burada kötü/eskimiş
-- veya elle çağrılmış istemcinin canonical olmayan değer yazması engellenir.
create or replace function public.vixrex_validate_storefront_value(
  p_contract jsonb,
  p_value jsonb
)
returns boolean
language plpgsql
immutable
set search_path = pg_catalog, public
as $$
declare
  v_type text := p_contract ->> 'type';
  v_required boolean := coalesce((p_contract ->> 'required')::boolean, false);
  v_validation text := p_contract ->> 'validation';
  v_text text;
  v_len int;
  v_min_len int;
  v_max_len int;
  v_num numeric;
  v_min numeric;
  v_max numeric;
begin
  if p_contract is null then return false; end if;

  if p_value is null or jsonb_typeof(p_value) = 'null' then
    return not v_required;
  end if;

  if v_type = 'acikKapali' then
    return jsonb_typeof(p_value) = 'boolean';
  end if;

  if v_type = 'sayi' then
    if jsonb_typeof(p_value) <> 'number' then return false; end if;
    v_num := (p_value #>> '{}')::numeric;
    v_min := nullif(p_contract ->> 'min', '')::numeric;
    v_max := nullif(p_contract ->> 'max', '')::numeric;
    if v_min is not null and v_num < v_min then return false; end if;
    if v_max is not null and v_num > v_max then return false; end if;
    return true;
  end if;

  if jsonb_typeof(p_value) <> 'string' then return false; end if;
  v_text := pg_catalog.btrim(p_value #>> '{}');
  v_len := char_length(v_text);
  v_min_len := nullif(p_contract ->> 'minLength', '')::int;
  v_max_len := nullif(p_contract ->> 'maxLength', '')::int;

  -- Canonical optional empty = JSON null. İkinci bir boş temsil saklanmaz.
  if v_len = 0 then return false; end if;
  if v_min_len is not null and v_len < v_min_len then return false; end if;
  if v_max_len is not null and v_len > v_max_len then return false; end if;

  if v_validation = 'adres' then
    if v_len < 10 then return false; end if;
    if v_text !~ '[0-9]'
       and lower(v_text) !~ '(cad|sok|mah|bulv|blv|apt|blok|sit|plaza|çarşı|carsi|pasaj|sanayi|osb|küme|kume)' then
      return false;
    end if;
  end if;

  if v_type = 'telefon' then
    if v_validation = 'tr_mobil' then
      return v_text ~ '^905[0-9]{9}$';
    end if;
    return v_text ~ '^[0-9]{10,13}$';
  elsif v_type = 'eposta' then
    return v_text ~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]{2,}$';
  elsif v_type = 'url' then
    return v_text ~ '^https?://.+' or v_text ~ '^#.+$';
  elsif v_type = 'gorsel' then
    return v_text ~ '^https?://.+';
  elsif v_type = 'secim' then
    return jsonb_typeof(p_contract -> 'options') = 'array'
       and (p_contract -> 'options') @> jsonb_build_array(v_text);
  elsif v_type in ('metin', 'uzunMetin') then
    return true;
  end if;

  return false;
end;
$$;
