-- Vixrex yayın güvenliği: yasal onay DB kapısını geri getir.
--
-- 2026-09-10 production salt-okuma denetiminde:
--   - public.stores üzerinde stores_publish_readiness_guard VAR,
--   - fakat onun çağırdığı public.assert_store_publish_ready yalnız işletme
--     adı/kategori/WhatsApp/adres/il/ilçe kontrol ediyor,
--   - eski trg_validate_store_legal_acceptance ve bağlı private fonksiyon
--     production'da YOK.
--
-- Sonuç: UI yasal onayı kapatsa da geçerli owner session ile
-- publish_working_draft RPC doğrudan çağrıldığında DB'nin kendisi yasal onayı
-- yeniden doğrulamıyordu. Bu migration yeni yayın yolu açmaz; mevcut tek
-- assert_store_publish_ready fonksiyonuna eski yasal güvenlik semantiğini
-- ekler. publish_working_draft ve stores_publish_readiness_guard zaten bu
-- fonksiyonu çağırdığı için iki yol aynı kapıda birleşir.
--
-- Canlıya otomatik uygulanmaz. Draft PR doğrulama alanıdır.

create or replace function public.assert_store_publish_ready(p_store jsonb)
returns void
language plpgsql
set search_path = pg_catalog, public
as $$
declare
  v_category text := pg_catalog.btrim(coalesce(p_store ->> 'kategori', ''));
  v_phone_raw text := pg_catalog.btrim(coalesce(p_store ->> 'whatsapp', ''));
  v_phone_digits text;
  v_phone_canonical text;
begin
  if pg_catalog.btrim(coalesce(p_store ->> 'name', '')) = '' then
    raise exception 'STORE_NAME_REQUIRED';
  end if;

  if v_category = '' or pg_catalog.lower(v_category) in ('diğer', 'diger') then
    raise exception 'STORE_CATEGORY_REQUIRED';
  end if;

  if v_phone_raw = '' then
    raise exception 'STORE_WHATSAPP_REQUIRED';
  end if;
  if v_phone_raw ~ '[[:alpha:]]' then
    raise exception 'STORE_WHATSAPP_INVALID';
  end if;

  v_phone_digits := pg_catalog.regexp_replace(v_phone_raw, '[^0-9]', '', 'g');
  v_phone_canonical := case
    when v_phone_digits ~ '^05[0-9]{9}$' then '90' || pg_catalog.substr(v_phone_digits, 2)
    when v_phone_digits ~ '^5[0-9]{9}$' then '90' || v_phone_digits
    when v_phone_digits ~ '^905[0-9]{9}$' then v_phone_digits
    else null
  end;
  if v_phone_canonical is null then
    raise exception 'STORE_WHATSAPP_INVALID';
  end if;

  if pg_catalog.btrim(coalesce(p_store ->> 'address', '')) = '' then
    raise exception 'STORE_ADDRESS_REQUIRED';
  end if;
  if pg_catalog.btrim(coalesce(p_store ->> 'province_name', '')) = '' then
    raise exception 'STORE_PROVINCE_REQUIRED';
  end if;
  if pg_catalog.btrim(coalesce(p_store ->> 'district_name', '')) = '' then
    raise exception 'STORE_DISTRICT_REQUIRED';
  end if;

  -- Yasal onay yalnız UI kararı değildir. Yayın kapısında DB yeniden doğrular.
  if coalesce((p_store ->> 'privacy_notice_acknowledged')::boolean, false) is not true then
    raise exception 'PRIVACY_NOTICE_REQUIRED';
  end if;
  if coalesce((p_store ->> 'terms_accepted')::boolean, false) is not true then
    raise exception 'TERMS_ACCEPTANCE_REQUIRED';
  end if;
  if coalesce((p_store ->> 'publication_consent_accepted')::boolean, false) is not true then
    raise exception 'PUBLICATION_CONSENT_REQUIRED';
  end if;

  -- Eski bir onay yeni belge sürümüne taşınamaz. Sürüm + hash aktif belgeyle
  -- birebir eşleşmeli; istemcinin yalnız true göndermesi yeterli değildir.
  if not exists (
    select 1
    from public.legal_documents d
    where d.document_type = 'privacy'
      and d.is_active = true
      and d.version = p_store ->> 'privacy_notice_version'
      and d.content_hash = p_store ->> 'privacy_notice_hash'
  ) then
    raise exception 'PRIVACY_NOTICE_VERSION_INVALID';
  end if;

  if not exists (
    select 1
    from public.legal_documents d
    where d.document_type = 'terms'
      and d.is_active = true
      and d.version = p_store ->> 'terms_version'
      and d.content_hash = p_store ->> 'terms_hash'
  ) then
    raise exception 'TERMS_VERSION_INVALID';
  end if;

  if not exists (
    select 1
    from public.legal_documents d
    where d.document_type = 'consent'
      and d.is_active = true
      and d.version = p_store ->> 'publication_consent_version'
      and d.content_hash = p_store ->> 'publication_consent_hash'
  ) then
    raise exception 'PUBLICATION_CONSENT_VERSION_INVALID';
  end if;
end;
$$;

comment on function public.assert_store_publish_ready(jsonb) is
  'Yayın öncesi zorunlu vitrin alanlarını ve aktif yasal belge sürüm/hash onaylarını tek DB kapısında doğrular.';

notify pgrst, 'reload schema';
