-- Faz 12 hazırlığı — karşılama ekranındaki üç demo vitrini yayına al.
--
-- NEDEN
-- Bu üç vitrin yayınlanmamış taslaktı ve karşılama ekranı onları gizli
-- `preview_token` bağlantısıyla açıyordu. Düzenleme anahtarları Flutter
-- kaynağına GÖMÜLÜYDÜ (landing-demo-aymira-giyim-2026 vb.), yani tarayıcıya
-- inen kodda açıkta duruyorlardı.
--
-- Bunlar gerçek bir esnafın vitrini değil, VixRex'in kendi tanıtım
-- içeriğidir. Herkesin görmesi ZATEN amaçtır; gizli bağlantıya ihtiyaçları
-- yoktur. Yayına alınınca karşılama ekranı düz `/v/:slug` adresine
-- bağlanabilir ve `preview_token` yolunun son kullanıcısı ortadan kalkar
-- (implementation_plan.md Commit 12).
--
-- is_demo = true İKİ İŞ YAPAR:
--   1. Bunların örnek içerik olduğunu işaretler.
--   2. Sahip düzenlemesini kapatır — update_working_draft_field ve
--      publish_working_draft, is_demo görünce DEMO_STORE_IMMUTABLE fırlatır.
--      Böylece koda gömülmüş o anahtarlar zararsız hale gelir.
--
-- Yasal onaylar VixRex adına kaydediliyor: içerik VixRex'e ait, gerçek bir
-- işletmenin verisi değil. Onaysız yayın denemesi zaten tetikleyici
-- tarafından reddedilirdi.

-- KORUMA TETİKLEYİCİSİ GEÇİCİ OLARAK KAPATILIR.
-- 20260803190512_..._protect_landing_demos.sql, is_demo işaretli satırlarda
-- HER güncellemeyi reddeden bir tetikleyici kurar. Bu migration da tam o
-- satırları güncelliyor; zincir sıfırdan çalıştığında koruma önce kurulduğu
-- için burada DEMO_STORE_IMMUTABLE hatası alınıyordu.
--
-- Tetikleyici yalnız bu işlem boyunca kapatılır ve sonunda geri açılır.
-- Amaç korumayı zayıflatmak değil; koruma yerinde kalır, yalnız kendi
-- kurulum adımımız istisna tutulur.
alter table public.stores disable trigger protect_landing_demo_stores;

do $$
declare
  v_privacy record;
  v_terms record;
  v_consent record;
  v_slug text;
begin
  select version, content_hash into v_privacy
  from public.legal_documents where document_type = 'privacy' and is_active limit 1;

  select version, content_hash into v_terms
  from public.legal_documents where document_type = 'terms' and is_active limit 1;

  select version, content_hash into v_consent
  from public.legal_documents where document_type = 'consent' and is_active limit 1;

  if v_privacy is null or v_terms is null or v_consent is null then
    raise exception 'Etkin yasal belge bulunamadi; demo vitrinler yayina alinamaz.';
  end if;

  -- Dördü de karşılama ekranında listeleniyor (landing_screen.dart).
  -- Biri yayında olmazsa o kartın bağlantısı kırık kalır.
  foreach v_slug in array array[
    'demo-aymira-giyim',
    'demo-lezzet-duragi',
    'demo-nova-kuafor',
    'demo-teknofix'
  ]
  loop
    update public.stores set
      is_demo = true,

      privacy_notice_acknowledged = true,
      privacy_notice_acknowledged_at = coalesce(privacy_notice_acknowledged_at, now()),
      privacy_notice_version = v_privacy.version,
      privacy_notice_hash = v_privacy.content_hash,

      terms_accepted = true,
      terms_accepted_at = coalesce(terms_accepted_at, now()),
      terms_version = v_terms.version,
      terms_hash = v_terms.content_hash,

      publication_consent_accepted = true,
      publication_consent_accepted_at = coalesce(publication_consent_accepted_at, now()),
      publication_consent_version = v_consent.version,
      publication_consent_hash = v_consent.content_hash,
      publication_consent_withdrawn_at = null,

      is_published = true
    where slug = v_slug;

    if not found then
      raise notice 'Demo vitrin bulunamadi, atlandi: %', v_slug;
    end if;
  end loop;
end;
$$;

-- Koruma geri açılır. Bundan sonra demo vitrinler yine değiştirilemez.
alter table public.stores enable trigger protect_landing_demo_stores;
