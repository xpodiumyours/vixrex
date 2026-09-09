-- Vixrex Assistant: command çekirdeğinde 46 alanın DEĞER güvenlik kapısı.
--
-- 20260909231500 yalnız kolon allowlist'i koyuyordu. Bu, izinli bir kolona
-- doğrudan RPC çağrısıyla yanlış tip/değer gönderilmesini tek başına engellemez.
-- Next.js ve Flutter istemci doğrulamaları UX katmanıdır; DB son güvenlik
-- sınırıdır. Bu migration ikinci bir yazma motoru oluşturmaz: mevcut
-- apply_*_working_draft_command wrapper'ları aynı command core'a gitmeden önce
-- bu tek doğrulayıcıyı çağırır.

create or replace function public.vixrex_validate_assistant_draft_changes(
  p_changes jsonb
)
returns void
language plpgsql
set search_path = pg_catalog, public
as $$
declare
  v_key text;
  v_value jsonb;
  v_text text;
  v_len integer;
  v_max_len integer;
  v_num numeric;
begin
  if p_changes is null or pg_catalog.jsonb_typeof(p_changes) <> 'object' then
    raise exception 'INVALID_CHANGES';
  end if;

  for v_key in select pg_catalog.jsonb_object_keys(p_changes)
  loop
    v_key := pg_catalog.btrim(coalesce(v_key, ''));
    if v_key = ''
       or not (v_key = any (public.vixrex_assistant_editable_draft_columns())) then
      raise exception 'FIELD_NOT_EDITABLE';
    end if;

    v_value := p_changes -> v_key;

    -- Zorunlu alanlar Assistant üzerinden temizlenemez.
    if v_value is null or pg_catalog.jsonb_typeof(v_value) = 'null' then
      if v_key = any (array[
        'name', 'kategori', 'whatsapp', 'address', 'province_name', 'district_name'
      ]::text[]) then
        raise exception 'INVALID_FIELD_VALUE';
      end if;
      continue;
    end if;

    -- Boolean alanlar gerçek JSON boolean olmalı.
    if v_key = any (array['show_storefront_rating', 'show_directions_link']::text[]) then
      if pg_catalog.jsonb_typeof(v_value) <> 'boolean' then
        raise exception 'INVALID_FIELD_VALUE';
      end if;
      continue;
    end if;

    -- Koordinatlar gerçek JSON number + kanonik aralık.
    if v_key = any (array['latitude', 'longitude']::text[]) then
      if pg_catalog.jsonb_typeof(v_value) <> 'number' then
        raise exception 'INVALID_FIELD_VALUE';
      end if;
      v_num := (v_value #>> '{}')::numeric;
      if (v_key = 'latitude' and (v_num < -90 or v_num > 90))
         or (v_key = 'longitude' and (v_num < -180 or v_num > 180)) then
        raise exception 'INVALID_FIELD_VALUE';
      end if;
      continue;
    end if;

    -- Geri kalan 42 alan metin tabanlıdır. Temizleme boş string ile değil null
    -- ile yapılır; böylece required/optional anlamı tek biçimde kalır.
    if pg_catalog.jsonb_typeof(v_value) <> 'string' then
      raise exception 'INVALID_FIELD_VALUE';
    end if;
    v_text := pg_catalog.btrim(v_value #>> '{}');
    v_len := pg_catalog.char_length(v_text);
    if v_len = 0 then
      raise exception 'INVALID_FIELD_VALUE';
    end if;

    v_max_len := case v_key
      when 'name' then 60
      when 'hero_badge' then 60
      when 'description' then 300
      when 'hero_location_text' then 60
      when 'kategori' then 40
      when 'business_type' then 40
      when 'email' then 120
      when 'address' then 200
      when 'province_name' then 60
      when 'district_name' then 60
      when 'neighborhood_name' then 60
      when 'map_label' then 120
      when 'working_hours' then 400
      when 'instagram' then 30
      when 'category_section_title' then 60
      when 'product_section_title' then 60
      when 'featured_banner_label' then 40
      when 'featured_banner_title' then 90
      when 'featured_banner_description' then 200
      when 'featured_banner_price_text' then 30
      when 'about_kicker' then 40
      when 'about_title' then 90
      when 'corporate_bio' then 1200
      when 'about_image_caption' then 120
      when 'gallery_section_kicker' then 40
      when 'gallery_section_title' then 90
      when 'gallery_action_label' then 40
      when 'blog_section_kicker' then 40
      when 'blog_section_title' then 90
      when 'faq_section_kicker' then 40
      when 'faq_section_title' then 90
      when 'faq_section_description' then 200
      else null
    end;

    if v_key = 'name' and v_len < 2 then
      raise exception 'INVALID_FIELD_VALUE';
    end if;
    if v_max_len is not null and v_len > v_max_len then
      raise exception 'INVALID_FIELD_VALUE';
    end if;

    if v_key = 'whatsapp' then
      if v_text !~ '^905[0-9]{9}$' then
        raise exception 'INVALID_FIELD_VALUE';
      end if;
    elsif v_key = 'phone' then
      if v_text !~ '^[0-9]{10,13}$' then
        raise exception 'INVALID_FIELD_VALUE';
      end if;
    elsif v_key = 'email' then
      if v_text !~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]{2,}$' then
        raise exception 'INVALID_FIELD_VALUE';
      end if;
    elsif v_key = 'kategori' then
      if not (v_text = any (array[
        'Giyim','Butik','Gıda','Fırın','Kozmetik','Dekorasyon','Elektronik',
        'Kırtasiye','Kafe / Lokanta','Kuaför','Teknik Servis','Danışmanlık',
        'Eğitim','Ev Temizlik','Spor / Fitness','Pet / Veteriner',
        'Sağlık / Yaşam','Oto / Araç','Diğer'
      ]::text[])) then
        raise exception 'INVALID_FIELD_VALUE';
      end if;
    elsif v_key = 'address' then
      if v_len < 10 then
        raise exception 'INVALID_FIELD_VALUE';
      end if;
      if v_text !~ '[0-9]'
         and pg_catalog.lower(v_text) !~ '(cad|sok|mah|bulv|blv|apt|blok|sit|plaza|çarşı|carsi|pasaj|sanayi|osb|küme|kume)' then
        raise exception 'INVALID_FIELD_VALUE';
      end if;
    elsif v_key = 'gallery_action_href' then
      if v_text !~ '^https?://.+' and v_text !~ '^#.+$' then
        raise exception 'INVALID_FIELD_VALUE';
      end if;
    elsif v_key = any (array[
      'website', 'google_business_link', 'references_link',
      'logo_url', 'shelf_image_url', 'featured_banner_image_url', 'about_image_url'
    ]::text[]) then
      if v_text !~ '^https?://.+' then
        raise exception 'INVALID_FIELD_VALUE';
      end if;
    end if;
  end loop;
end;
$$;

comment on function public.vixrex_validate_assistant_draft_changes(jsonb) is
  'Vixrex Assistant 46 alan command değerlerini DB sınırında fail-closed doğrular; istemci doğrulamasını güvenlik sınırı saymaz.';

revoke all on function public.vixrex_validate_assistant_draft_changes(jsonb)
  from public, anon, authenticated, service_role;

-- Next.js owner-session wrapper: yetki doğrulandıktan sonra DB value gate.
create or replace function public.apply_working_draft_command(
  p_session_token text,
  p_command_id uuid,
  p_changes jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_token_hash text;
  v_store_id uuid;
  v_session_id uuid;
  v_store_user_id uuid;
  v_is_demo boolean;
begin
  if p_session_token is null
     or pg_catalog.length(pg_catalog.btrim(p_session_token)) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;
  if p_command_id is null then
    raise exception 'INVALID_COMMAND_PRECONDITION';
  end if;

  v_token_hash := encode(sha256(pg_catalog.btrim(p_session_token)::bytea), 'hex');

  select os.store_id, os.id, st.user_id, st.is_demo
  into v_store_id, v_session_id, v_store_user_id, v_is_demo
  from public.owner_sessions os
  join public.stores st on st.id = os.store_id
  where os.session_token_hash = v_token_hash
    and os.consumed_at is not null
    and os.expires_at > now();

  if v_store_id is null then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;
  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE';
  end if;

  perform public.vixrex_validate_assistant_draft_changes(p_changes);

  return public.vixrex_apply_storefront_command_core(
    v_store_id,
    v_store_user_id,
    v_session_id::text,
    p_command_id,
    p_changes
  );
end;
$$;

revoke all on function public.apply_working_draft_command(text, uuid, jsonb)
  from public, anon, authenticated, service_role;
grant execute on function public.apply_working_draft_command(text, uuid, jsonb)
  to anon, authenticated;

-- Flutter kalıcı auth wrapper: aynı DB value gate, aynı command core.
create or replace function public.apply_owned_working_draft_command(
  p_command_id uuid,
  p_changes jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_store_id uuid;
  v_is_demo boolean;
begin
  if v_user_id is null or not public.is_permanent_user() then
    raise exception 'PERMANENT_ACCOUNT_REQUIRED';
  end if;
  if p_command_id is null then
    raise exception 'INVALID_COMMAND_PRECONDITION';
  end if;

  select st.id, st.is_demo
  into v_store_id, v_is_demo
  from public.stores st
  where st.user_id = v_user_id
  order by st.created_at asc
  limit 1;

  if v_store_id is null then
    raise exception 'OWNED_STORE_NOT_FOUND';
  end if;
  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE';
  end if;

  perform public.vixrex_validate_assistant_draft_changes(p_changes);

  insert into public.store_working_drafts (
    store_id,
    draft_data,
    draft_version,
    base_live_version,
    updated_at
  )
  select
    st.id,
    public.strip_draft_secrets(to_jsonb(st)),
    1,
    st.version,
    now()
  from public.stores st
  where st.id = v_store_id
    and not exists (
      select 1 from public.store_working_drafts wd where wd.store_id = st.id
    )
  on conflict (store_id) do nothing;

  return public.vixrex_apply_storefront_command_core(
    v_store_id,
    v_user_id,
    null,
    p_command_id,
    p_changes
  );
end;
$$;

revoke all on function public.apply_owned_working_draft_command(uuid, jsonb)
  from public, anon, authenticated, service_role;
grant execute on function public.apply_owned_working_draft_command(uuid, jsonb)
  to authenticated;

notify pgrst, 'reload schema';
