begin;

do $$
declare
  v_valid jsonb := jsonb_build_object(
    'name', 'Hazır Vitrin',
    'kategori', 'Danışmanlık',
    'whatsapp', '0555 123 45 67',
    'address', 'Örnek Sokak No: 1',
    'province_name', 'İstanbul',
    'district_name', 'Kadıköy'
  );
  v_case record;
  v_phone text;
  v_rejected boolean;
begin
  perform public.assert_store_publish_ready(v_valid);

  for v_case in
    select * from (values
      ('name', 'STORE_NAME_REQUIRED'),
      ('kategori', 'STORE_CATEGORY_REQUIRED'),
      ('whatsapp', 'STORE_WHATSAPP_REQUIRED'),
      ('address', 'STORE_ADDRESS_REQUIRED'),
      ('province_name', 'STORE_PROVINCE_REQUIRED'),
      ('district_name', 'STORE_DISTRICT_REQUIRED')
    ) as cases(field_name, expected_error)
  loop
    v_rejected := false;
    begin
      perform public.assert_store_publish_ready(v_valid - v_case.field_name);
    exception when others then
      if sqlerrm like '%' || v_case.expected_error || '%' then
        v_rejected := true;
      else
        raise;
      end if;
    end;
    if not v_rejected then
      raise exception 'Eksik alan reddedilmedi: %', v_case.field_name;
    end if;
  end loop;

  foreach v_phone in array array[
    '0555 123 45 67', '5551234567', '+90 555 123 45 67', '905551234567'
  ] loop
    perform public.assert_store_publish_ready(
      jsonb_set(v_valid, '{whatsapp}', to_jsonb(v_phone))
    );
  end loop;

  foreach v_phone in array array[
    '02121234567', '12345', 'abc05551234567'
  ] loop
    v_rejected := false;
    begin
      perform public.assert_store_publish_ready(
        jsonb_set(v_valid, '{whatsapp}', to_jsonb(v_phone))
      );
    exception when others then
      if sqlerrm like '%STORE_WHATSAPP_INVALID%' then
        v_rejected := true;
      else
        raise;
      end if;
    end;
    if not v_rejected then
      raise exception 'Geçersiz telefon kabul edildi: %', v_phone;
    end if;
  end loop;

  foreach v_phone in array array['Diğer', 'diger'] loop
    v_rejected := false;
    begin
      perform public.assert_store_publish_ready(
        jsonb_set(v_valid, '{kategori}', to_jsonb(v_phone))
      );
    exception when others then
      if sqlerrm like '%STORE_CATEGORY_REQUIRED%' then
        v_rejected := true;
      else
        raise;
      end if;
    end;
    if not v_rejected then
      raise exception 'Boş kategori kabul edildi: %', v_phone;
    end if;
  end loop;
end;
$$;

do $$
declare
  v_ready_id uuid;
  v_premium_id uuid;
  v_legal_id uuid;
  v_token text := repeat('a', 64);
  v_premium_token text := repeat('b', 64);
  v_legal_token text := repeat('c', 64);
  v_version bigint;
  v_before jsonb;
  v_after jsonb;
  v_rejected boolean;
  v_has_legal_guard boolean := exists (
    select 1 from pg_trigger
    where tgrelid = 'public.stores'::regclass
      and tgname = 'trg_validate_store_legal_acceptance'
      and not tgisinternal
  );
  v_privacy_version text;
  v_privacy_hash text;
  v_terms_version text;
  v_terms_hash text;
  v_consent_version text;
  v_consent_hash text;
begin
  select version, content_hash into v_privacy_version, v_privacy_hash
  from public.legal_documents where document_type = 'privacy' and is_active limit 1;
  select version, content_hash into v_terms_version, v_terms_hash
  from public.legal_documents where document_type = 'terms' and is_active limit 1;
  select version, content_hash into v_consent_version, v_consent_hash
  from public.legal_documents where document_type = 'consent' and is_active limit 1;

  -- İlk yayın geçişi doğrudan tabloda da ortak tetikleyici tarafından korunur.
  insert into public.stores (slug) values ('zz237-trigger') returning id into v_ready_id;
  v_rejected := false;
  begin
    update public.stores set is_published = true where id = v_ready_id;
  exception when others then
    v_rejected := sqlerrm like '%STORE_NAME_REQUIRED%';
  end;
  if not v_rejected then raise exception 'İlk yayın tetikleyicisi eksik vitrini reddetmedi'; end if;
  delete from public.stores where id = v_ready_id;

  -- Hazır ve yasal onayları tam organik vitrin ilk kez yayınlanır.
  insert into public.stores (
    slug, name, kategori, whatsapp, address, province_name, district_name,
    privacy_notice_acknowledged, privacy_notice_version, privacy_notice_hash,
    terms_accepted, terms_version, terms_hash,
    publication_consent_accepted, publication_consent_version, publication_consent_hash
  ) values (
    'zz237-ready', 'Canlı Ad', 'Danışmanlık', '05551234567', 'Adres', 'İstanbul', 'Kadıköy',
    true, coalesce(v_privacy_version, ''), coalesce(v_privacy_hash, ''),
    true, coalesce(v_terms_version, ''), coalesce(v_terms_hash, ''),
    true, coalesce(v_consent_version, ''), coalesce(v_consent_hash, '')
  ) returning id, version into v_ready_id, v_version;
  insert into public.owner_sessions (
    store_id, code_hash, session_token_hash, expires_at, consumed_at
  ) values (
    v_ready_id, 'test', encode(sha256(v_token::bytea), 'hex'), now() + interval '1 hour', now()
  );
  insert into public.store_working_drafts (store_id, draft_data, base_live_version)
  values (v_ready_id, '{"description":"İlk yayın"}'::jsonb, v_version);
  perform public.publish_working_draft(v_token);
  if not (select is_published from public.stores where id = v_ready_id)
     or exists (select 1 from public.store_working_drafts where store_id = v_ready_id) then
    raise exception 'İlk yayın taslağı atomik biçimde tamamlanmadı';
  end if;

  -- Yeniden yayında hazırlık hatası canlı satırı ve taslağı aynen korur.
  select version into v_version from public.stores where id = v_ready_id;
  insert into public.store_working_drafts (store_id, draft_data, base_live_version)
  values (v_ready_id, '{"name":""}'::jsonb, v_version);
  select to_jsonb(s) into v_before from public.stores s where id = v_ready_id;
  v_rejected := false;
  begin
    perform public.publish_working_draft(v_token);
  exception when others then
    v_rejected := sqlerrm like '%STORE_NAME_REQUIRED%';
  end;
  select to_jsonb(s) into v_after from public.stores s where id = v_ready_id;
  if not v_rejected or v_after is distinct from v_before
     or not exists (select 1 from public.store_working_drafts where store_id = v_ready_id) then
    raise exception 'Yeniden yayın hatası canlı/taslak rollback sözleşmesini bozdu';
  end if;

  -- Kiralık vitrinde premium kapısı hazırlık kontrolünden önce çalışır.
  insert into public.stores (slug, cloned_from_slug)
  values ('zz237-premium', 'demo-teknofix') returning id, version into v_premium_id, v_version;
  insert into public.owner_sessions (store_id, code_hash, session_token_hash, expires_at, consumed_at)
  values (v_premium_id, 'test', encode(sha256(v_premium_token::bytea), 'hex'), now() + interval '1 hour', now());
  insert into public.store_working_drafts (store_id, draft_data, base_live_version)
  values (v_premium_id, '{}'::jsonb, v_version);
  v_rejected := false;
  begin
    perform public.publish_working_draft(v_premium_token);
  exception when others then
    v_rejected := sqlerrm like '%PREMIUM_REQUIRED%';
  end;
  if not v_rejected then raise exception 'Premium yayın kapısı korunmadı'; end if;

  -- Kurulu yasal tetikleyici varsa ortak hazırlıktan sonra gerçekten çalışır.
  if v_has_legal_guard then
    insert into public.stores (slug, name, kategori, whatsapp, address, province_name, district_name)
    values ('zz237-legal', 'Yasal Test', 'Danışmanlık', '05551234567', 'Adres', 'İstanbul', 'Kadıköy')
    returning id, version into v_legal_id, v_version;
    insert into public.owner_sessions (store_id, code_hash, session_token_hash, expires_at, consumed_at)
    values (v_legal_id, 'test', encode(sha256(v_legal_token::bytea), 'hex'), now() + interval '1 hour', now());
    insert into public.store_working_drafts (store_id, draft_data, base_live_version)
    values (v_legal_id, '{}'::jsonb, v_version);
    v_rejected := false;
    begin
      perform public.publish_working_draft(v_legal_token);
    exception when others then
      v_rejected := sqlerrm like '%PRIVACY_NOTICE_REQUIRED%';
    end;
    if not v_rejected then raise exception 'Yasal yayın kapısı korunmadı'; end if;
  end if;
end;
$$;

rollback;
