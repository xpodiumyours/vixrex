-- Vixrex Assistant: Flutter auth.uid() batch yazımını yalnız canonical 46
-- vitrin alanının kolonlarıyla sınırla.
--
-- `update_owned_working_draft_fields` authenticated istemciden doğrudan
-- çağrılabildiği için yalnız `owner_forbidden_draft_keys()` kullanmak yeterli
-- değildir: yasak olmayan fakat Assistant sözleşmesinde bulunmayan bir stores
-- kolonu da yazılabilirdi. Bu migration fail-closed bir allowlist ekler.
--
-- Liste `shared/vitrin_alanlari.json` / `VITRIN_FIELDS` sırasından üretilmiştir
-- ve public_web kontrat testi birebir eşitliği zorunlu tutar. Bu SQL liste ürün
-- kuralının ikinci kaynağı değildir; DB yetki sınırının derlenmiş kopyasıdır.

create or replace function public.vixrex_assistant_editable_draft_columns()
returns text[]
language sql
immutable
set search_path = pg_catalog, public
as $$
  select array[
    'name',
    'hero_badge',
    'description',
    'hero_location_text',
    'kategori',
    'business_type',
    'logo_url',
    'shelf_image_url',
    'whatsapp',
    'phone',
    'email',
    'address',
    'province_name',
    'district_name',
    'neighborhood_name',
    'map_label',
    'working_hours',
    'instagram',
    'website',
    'google_business_link',
    'latitude',
    'longitude',
    'category_section_title',
    'product_section_title',
    'featured_banner_label',
    'featured_banner_title',
    'featured_banner_description',
    'featured_banner_image_url',
    'featured_banner_price_text',
    'about_kicker',
    'about_title',
    'corporate_bio',
    'about_image_url',
    'about_image_caption',
    'gallery_section_kicker',
    'gallery_section_title',
    'gallery_action_label',
    'gallery_action_href',
    'blog_section_kicker',
    'blog_section_title',
    'faq_section_kicker',
    'faq_section_title',
    'faq_section_description',
    'show_storefront_rating',
    'show_directions_link',
    'references_link'
  ]::text[];
$$;

comment on function public.vixrex_assistant_editable_draft_columns() is
  'Vixrex Assistant 46 alan sözleşmesinin DB yazma allowlisti; generated contract test ile canonical şemaya kilitlidir.';

revoke all on function public.vixrex_assistant_editable_draft_columns()
  from public, anon, authenticated, service_role;

create or replace function public.update_owned_working_draft_fields(
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
  v_slug text;
  v_is_demo boolean;
  v_live_version bigint;
  v_draft_version bigint;
  v_draft_data jsonb;
  v_new_data jsonb;
  v_key text;
  v_value jsonb;
  v_change_count integer;
begin
  if v_user_id is null or not public.is_permanent_user() then
    raise exception 'PERMANENT_ACCOUNT_REQUIRED';
  end if;

  if p_changes is null or pg_catalog.jsonb_typeof(p_changes) <> 'object' then
    raise exception 'INVALID_CHANGES';
  end if;

  select count(*) into v_change_count
  from pg_catalog.jsonb_object_keys(p_changes);

  if v_change_count < 1 then
    raise exception 'INVALID_CHANGES';
  end if;
  if v_change_count > 20 then
    raise exception 'TOO_MANY_FIELDS';
  end if;

  select st.id, st.slug, st.is_demo, st.version
  into v_store_id, v_slug, v_is_demo, v_live_version
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

  -- Önce Assistant'ın pozitif izin listesi, sonra genel owner yasakları.
  -- Böylece yeni bir stores kolonu gelecekte tabloya eklense bile Assistant
  -- otomatik olarak o alanı yazma yetkisi kazanmaz.
  for v_key in select pg_catalog.jsonb_object_keys(p_changes)
  loop
    v_key := pg_catalog.btrim(coalesce(v_key, ''));
    if v_key = '' then
      raise exception 'INVALID_FIELD_KEY';
    end if;
    if not (v_key = any (public.vixrex_assistant_editable_draft_columns())) then
      raise exception 'FIELD_NOT_EDITABLE';
    end if;
    if v_key = any (public.owner_forbidden_draft_keys()) then
      raise exception 'FIELD_NOT_EDITABLE';
    end if;
    if not exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'stores'
        and column_name = v_key
        and is_generated = 'NEVER'
        and is_updatable = 'YES'
    ) then
      raise exception 'UNKNOWN_FIELD';
    end if;
  end loop;

  select draft_data, draft_version
  into v_draft_data, v_draft_version
  from public.store_working_drafts
  where store_id = v_store_id
  for update;

  if not found then
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
    on conflict (store_id) do nothing;

    select draft_data, draft_version
    into v_draft_data, v_draft_version
    from public.store_working_drafts
    where store_id = v_store_id
    for update;
  end if;

  v_new_data := v_draft_data;
  for v_key in select pg_catalog.jsonb_object_keys(p_changes)
  loop
    v_value := p_changes -> v_key;
    if v_value is null or pg_catalog.jsonb_typeof(v_value) = 'null' then
      v_new_data := v_new_data - v_key;
    else
      v_new_data := v_new_data || pg_catalog.jsonb_build_object(v_key, v_value);
    end if;
  end loop;

  update public.store_working_drafts
  set draft_data = v_new_data,
      draft_version = draft_version + 1,
      updated_at = now()
  where store_id = v_store_id
  returning draft_version into v_draft_version;

  return pg_catalog.jsonb_build_object(
    'store_id', v_store_id,
    'slug', v_slug,
    'changed_count', v_change_count,
    'draft_version', v_draft_version
  );
end;
$$;

comment on function public.update_owned_working_draft_fields(jsonb) is
  'Flutter Vixrex Assistant: kalıcı hesabın kendi vitrininin yalnız canonical 46 Assistant kolonunu tek transaction içinde günceller.';

revoke all on function public.update_owned_working_draft_fields(jsonb)
  from public, anon, service_role;
grant execute on function public.update_owned_working_draft_fields(jsonb)
  to authenticated;

notify pgrst, 'reload schema';
