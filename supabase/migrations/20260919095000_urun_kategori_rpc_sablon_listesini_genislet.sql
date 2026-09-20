create or replace function public.upsert_store_category_v2(
  p_store_id uuid,
  p_edit_token text,
  p_name text,
  p_template_key text default 'generic',
  p_slug text default null,
  p_sort_order integer default 0
)
returns jsonb
language plpgsql
security definer
set search_path = 'pg_catalog', 'public', 'auth'
as $$
declare
  v_slug text;
  v_id uuid;
  v_template_key text := coalesce(nullif(pg_catalog.btrim(p_template_key), ''), 'generic');
begin
  if not public._check_store_authorization(p_store_id, p_edit_token) then
    raise exception 'UNAUTHORIZED';
  end if;

  if p_name is null or pg_catalog.length(pg_catalog.btrim(p_name)) = 0 then
    raise exception 'CATEGORY_NAME_REQUIRED';
  end if;

  if v_template_key not in (
    'generic', 'fashion', 'electronics', 'beauty', 'food', 'cafe_restaurant',
    'home', 'automotive', 'service', 'technical_service'
  ) then
    raise exception 'INVALID_PRODUCT_TEMPLATE_KEY';
  end if;

  v_slug := nullif(pg_catalog.btrim(coalesce(p_slug, '')), '');
  if v_slug is null then
    v_slug := lower(replace(replace(replace(pg_catalog.btrim(p_name), ' ', '-'), '.', ''), ',', ''));
  end if;
  if v_slug is null or v_slug = '' then
    v_slug := 'kategori';
  end if;

  insert into public.product_categories (
    store_id,
    name,
    slug,
    sort_order,
    is_active,
    product_template_key
  ) values (
    p_store_id,
    pg_catalog.btrim(p_name),
    v_slug,
    coalesce(p_sort_order, 0),
    true,
    v_template_key
  )
  on conflict (store_id, slug) do update
    set name = excluded.name,
        sort_order = excluded.sort_order,
        is_active = true,
        product_template_key = excluded.product_template_key,
        updated_at = now()
  returning id into v_id;

  return jsonb_build_object(
    'id', v_id,
    'slug', v_slug,
    'product_template_key', v_template_key,
    'success', true
  );
end;
$$;

alter function public.upsert_store_category_v2(uuid, text, text, text, text, integer) owner to postgres;
revoke execute on function public.upsert_store_category_v2(uuid, text, text, text, text, integer) from public;
grant execute on function public.upsert_store_category_v2(uuid, text, text, text, text, integer) to anon, authenticated, service_role;

create or replace function public.update_store_category_v2(
  p_category_id uuid,
  p_edit_token text,
  p_name text default null,
  p_template_key text default null,
  p_sort_order integer default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_store_id uuid;
  v_template_key text;
begin
  select pc.store_id
  into v_store_id
  from public.product_categories as pc
  where pc.id = p_category_id;

  if v_store_id is null then
    raise exception 'CATEGORY_NOT_FOUND';
  end if;

  if not public._check_store_authorization(v_store_id, p_edit_token) then
    raise exception 'UNAUTHORIZED';
  end if;

  if p_name is not null and pg_catalog.length(pg_catalog.btrim(p_name)) = 0 then
    raise exception 'CATEGORY_NAME_REQUIRED';
  end if;

  v_template_key := nullif(pg_catalog.btrim(coalesce(p_template_key, '')), '');
  if v_template_key is not null and v_template_key not in (
    'generic', 'fashion', 'electronics', 'beauty', 'food', 'cafe_restaurant',
    'home', 'automotive', 'service', 'technical_service'
  ) then
    raise exception 'INVALID_PRODUCT_TEMPLATE_KEY';
  end if;

  update public.product_categories as pc
  set
    name = case
      when p_name is not null then pg_catalog.btrim(p_name)
      else pc.name
    end,
    product_template_key = coalesce(v_template_key, pc.product_template_key),
    sort_order = coalesce(p_sort_order, pc.sort_order),
    updated_at = now()
  where pc.id = p_category_id;

  return pg_catalog.jsonb_build_object(
    'id', p_category_id,
    'success', true
  );
end;
$$;

alter function public.update_store_category_v2(uuid, text, text, text, integer) owner to postgres;
revoke execute on function public.update_store_category_v2(uuid, text, text, text, integer) from public;
grant execute on function public.update_store_category_v2(uuid, text, text, text, integer) to anon, authenticated, service_role;
