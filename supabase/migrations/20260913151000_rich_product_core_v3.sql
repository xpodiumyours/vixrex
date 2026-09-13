-- Rich Product CORE v3 — additive, backward-compatible database contract.
-- Existing create_store_product_v2 / update_store_product stay callable.
-- New rich clients use v3/v2 below and write into the same products table.

alter table public.product_categories
  drop constraint if exists product_categories_template_key_check;

alter table public.product_categories
  add constraint product_categories_template_key_check
  check (
    product_template_key = any (
      array[
        'generic'::text,
        'fashion'::text,
        'electronics'::text,
        'beauty'::text,
        'food'::text,
        'home'::text,
        'automotive'::text,
        'service'::text
      ]
    )
  );

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
    'generic', 'fashion', 'electronics', 'beauty', 'food', 'home', 'automotive', 'service'
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
    'generic', 'fashion', 'electronics', 'beauty', 'food', 'home', 'automotive', 'service'
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

create or replace function public.create_store_product_v3(
  p_store_id uuid,
  p_edit_token text,
  p_name text,
  p_description text default '',
  p_price_text text default '',
  p_price_amount numeric default null,
  p_image_urls jsonb default '[]'::jsonb,
  p_category_id uuid default null,
  p_source_type text default 'manual',
  p_external_product_id text default null,
  p_is_visible boolean default true,
  p_sort_order integer default 0,
  p_old_price_amount numeric default null,
  p_badge_tag text default null,
  p_fulfillment_region text default null,
  p_brand text default null,
  p_barcode text default null,
  p_stock_quantity integer default null,
  p_stock_status text default null,
  p_metadata jsonb default '{}'::jsonb,
  p_variants jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_new_product uuid;
  v_new_slug text;
  v_template_key text;
  v_metadata_template_key text;
  v_source_type text := coalesce(
    nullif(pg_catalog.btrim(p_source_type), ''),
    'manual'
  );
  v_external_product_id text := nullif(
    pg_catalog.btrim(coalesce(p_external_product_id, '')),
    ''
  );
begin
  if not public._check_store_authorization(p_store_id, p_edit_token) then
    raise exception 'UNAUTHORIZED';
  end if;

  if p_name is null or pg_catalog.length(pg_catalog.btrim(p_name)) = 0 then
    raise exception 'PRODUCT_NAME_REQUIRED';
  end if;

  if jsonb_typeof(coalesce(p_metadata, '{}'::jsonb)) <> 'object' then
    raise exception 'PRODUCT_METADATA_INVALID';
  end if;

  if jsonb_typeof(coalesce(p_variants, '[]'::jsonb)) <> 'array' then
    raise exception 'PRODUCT_VARIANTS_INVALID';
  end if;

  if p_stock_quantity is not null and p_stock_quantity < 0 then
    raise exception 'PRODUCT_STOCK_INVALID';
  end if;

  if p_category_id is not null then
    select pc.product_template_key
    into v_template_key
    from public.product_categories as pc
    where pc.id = p_category_id
      and pc.store_id = p_store_id;

    if v_template_key is null then
      raise exception 'CATEGORY_NOT_IN_SAME_STORE';
    end if;

    v_metadata_template_key := nullif(
      pg_catalog.btrim(coalesce(p_metadata->>'templateKey', '')),
      ''
    );
    if v_metadata_template_key is not null and v_metadata_template_key <> v_template_key then
      raise exception 'PRODUCT_TEMPLATE_MISMATCH';
    end if;
  end if;

  if v_external_product_id is not null then
    select p.id, p.slug
    into v_new_product, v_new_slug
    from public.products as p
    where p.store_id = p_store_id
      and p.source_type = v_source_type
      and p.external_product_id = v_external_product_id
    limit 1;

    if v_new_product is not null then
      return pg_catalog.jsonb_build_object(
        'id', v_new_product,
        'slug', v_new_slug,
        'success', true,
        'created', false
      );
    end if;
  end if;

  begin
    insert into public.products (
      store_id,
      name,
      slug,
      description,
      price_text,
      price_amount,
      image_urls,
      category_id,
      source_type,
      external_product_id,
      is_visible,
      sort_order,
      old_price_amount,
      badge_tag,
      fulfillment_region,
      brand,
      barcode,
      stock_quantity,
      stock_status,
      metadata,
      variants
    ) values (
      p_store_id,
      pg_catalog.btrim(p_name),
      '',
      p_description,
      p_price_text,
      p_price_amount,
      p_image_urls,
      p_category_id,
      v_source_type,
      v_external_product_id,
      p_is_visible,
      p_sort_order,
      p_old_price_amount,
      nullif(pg_catalog.btrim(coalesce(p_badge_tag, '')), ''),
      nullif(pg_catalog.btrim(coalesce(p_fulfillment_region, '')), ''),
      nullif(pg_catalog.btrim(coalesce(p_brand, '')), ''),
      nullif(pg_catalog.btrim(coalesce(p_barcode, '')), ''),
      p_stock_quantity,
      nullif(pg_catalog.btrim(coalesce(p_stock_status, '')), ''),
      coalesce(p_metadata, '{}'::jsonb),
      coalesce(p_variants, '[]'::jsonb)
    )
    returning id, slug into v_new_product, v_new_slug;
  exception
    when unique_violation then
      if v_external_product_id is null then
        raise;
      end if;

      select p.id, p.slug
      into v_new_product, v_new_slug
      from public.products as p
      where p.store_id = p_store_id
        and p.source_type = v_source_type
        and p.external_product_id = v_external_product_id
      limit 1;

      if v_new_product is null then
        raise;
      end if;

      return pg_catalog.jsonb_build_object(
        'id', v_new_product,
        'slug', v_new_slug,
        'success', true,
        'created', false
      );
  end;

  return pg_catalog.jsonb_build_object(
    'id', v_new_product,
    'slug', v_new_slug,
    'success', true,
    'created', true
  );
end;
$$;

alter function public.create_store_product_v3(
  uuid, text, text, text, text, numeric, jsonb, uuid, text, text,
  boolean, integer, numeric, text, text, text, text, integer, text,
  jsonb, jsonb
) owner to postgres;
revoke execute on function public.create_store_product_v3(
  uuid, text, text, text, text, numeric, jsonb, uuid, text, text,
  boolean, integer, numeric, text, text, text, text, integer, text,
  jsonb, jsonb
) from public;
grant execute on function public.create_store_product_v3(
  uuid, text, text, text, text, numeric, jsonb, uuid, text, text,
  boolean, integer, numeric, text, text, text, text, integer, text,
  jsonb, jsonb
) to anon, authenticated, service_role;

create or replace function public.update_store_product_v2(
  p_product_id uuid,
  p_edit_token text default null,
  p_name text default null,
  p_description text default null,
  p_price_text text default null,
  p_price_amount numeric default null,
  p_image_urls jsonb default null,
  p_category_id uuid default null,
  p_is_visible boolean default null,
  p_sort_order integer default null,
  p_stock_quantity integer default null,
  p_stock_status text default null,
  p_old_price_amount numeric default null,
  p_badge_tag text default null,
  p_fulfillment_region text default null,
  p_brand text default null,
  p_barcode text default null,
  p_metadata jsonb default null,
  p_variants jsonb default null,
  p_clear_category boolean default false,
  p_clear_price_amount boolean default false,
  p_clear_stock_quantity boolean default false,
  p_clear_stock_status boolean default false,
  p_clear_old_price_amount boolean default false,
  p_clear_badge_tag boolean default false,
  p_clear_fulfillment_region boolean default false,
  p_clear_brand boolean default false,
  p_clear_barcode boolean default false,
  p_clear_metadata boolean default false,
  p_clear_variants boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_store_id uuid;
  v_current_category_id uuid;
  v_effective_category_id uuid;
  v_template_key text;
  v_metadata_template_key text;
begin
  select p.store_id, p.category_id
  into v_store_id, v_current_category_id
  from public.products as p
  where p.id = p_product_id;

  if v_store_id is null then
    raise exception 'PRODUCT_NOT_FOUND';
  end if;

  if not public._check_store_authorization(v_store_id, p_edit_token) then
    raise exception 'UNAUTHORIZED';
  end if;

  if p_category_id is not null and not p_clear_category and not exists (
    select 1
    from public.product_categories as pc
    where pc.id = p_category_id
      and pc.store_id = v_store_id
  ) then
    raise exception 'CATEGORY_NOT_IN_SAME_STORE';
  end if;

  if p_metadata is not null and jsonb_typeof(p_metadata) <> 'object' then
    raise exception 'PRODUCT_METADATA_INVALID';
  end if;

  if p_variants is not null and jsonb_typeof(p_variants) <> 'array' then
    raise exception 'PRODUCT_VARIANTS_INVALID';
  end if;

  if p_stock_quantity is not null and p_stock_quantity < 0 then
    raise exception 'PRODUCT_STOCK_INVALID';
  end if;

  v_effective_category_id := case
    when p_clear_category then null
    when p_category_id is not null then p_category_id
    else v_current_category_id
  end;

  if p_metadata is not null and v_effective_category_id is not null then
    select pc.product_template_key
    into v_template_key
    from public.product_categories as pc
    where pc.id = v_effective_category_id
      and pc.store_id = v_store_id;

    v_metadata_template_key := nullif(
      pg_catalog.btrim(coalesce(p_metadata->>'templateKey', '')),
      ''
    );
    if v_metadata_template_key is not null and v_template_key is not null
       and v_metadata_template_key <> v_template_key then
      raise exception 'PRODUCT_TEMPLATE_MISMATCH';
    end if;
  end if;

  update public.products as p
  set
    name = coalesce(p_name, p.name),
    description = coalesce(p_description, p.description),
    price_text = coalesce(p_price_text, p.price_text),
    price_amount = case
      when p_clear_price_amount then null
      when p_price_amount is not null then p_price_amount
      else p.price_amount
    end,
    image_urls = coalesce(p_image_urls, p.image_urls),
    category_id = case
      when p_clear_category then null
      when p_category_id is not null then p_category_id
      else p.category_id
    end,
    is_visible = coalesce(p_is_visible, p.is_visible),
    sort_order = coalesce(p_sort_order, p.sort_order),
    stock_quantity = case
      when p_clear_stock_quantity then null
      when p_stock_quantity is not null then p_stock_quantity
      else p.stock_quantity
    end,
    stock_status = case
      when p_clear_stock_status then null
      when p_stock_status is not null then p_stock_status
      else p.stock_status
    end,
    old_price_amount = case
      when p_clear_old_price_amount then null
      when p_old_price_amount is not null then p_old_price_amount
      else p.old_price_amount
    end,
    badge_tag = case
      when p_clear_badge_tag then null
      when p_badge_tag is not null then nullif(pg_catalog.btrim(p_badge_tag), '')
      else p.badge_tag
    end,
    fulfillment_region = case
      when p_clear_fulfillment_region then null
      when p_fulfillment_region is not null then nullif(pg_catalog.btrim(p_fulfillment_region), '')
      else p.fulfillment_region
    end,
    brand = case
      when p_clear_brand then null
      when p_brand is not null then nullif(pg_catalog.btrim(p_brand), '')
      else p.brand
    end,
    barcode = case
      when p_clear_barcode then null
      when p_barcode is not null then nullif(pg_catalog.btrim(p_barcode), '')
      else p.barcode
    end,
    metadata = case
      when p_clear_metadata then '{}'::jsonb
      when p_metadata is not null then p_metadata
      else p.metadata
    end,
    variants = case
      when p_clear_variants then '[]'::jsonb
      when p_variants is not null then p_variants
      else p.variants
    end
  where p.id = p_product_id;

  return pg_catalog.jsonb_build_object(
    'id', p_product_id,
    'success', true
  );
end;
$$;

alter function public.update_store_product_v2(
  uuid, text, text, text, text, numeric, jsonb, uuid, boolean, integer,
  integer, text, numeric, text, text, text, text, jsonb, jsonb,
  boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean,
  boolean, boolean, boolean
) owner to postgres;
revoke execute on function public.update_store_product_v2(
  uuid, text, text, text, text, numeric, jsonb, uuid, boolean, integer,
  integer, text, numeric, text, text, text, text, jsonb, jsonb,
  boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean,
  boolean, boolean, boolean
) from public;
grant execute on function public.update_store_product_v2(
  uuid, text, text, text, text, numeric, jsonb, uuid, boolean, integer,
  integer, text, numeric, text, text, text, text, jsonb, jsonb,
  boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean,
  boolean, boolean, boolean
) to anon, authenticated, service_role;

comment on function public.create_store_product_v3(
  uuid, text, text, text, text, numeric, jsonb, uuid, text, text,
  boolean, integer, numeric, text, text, text, text, integer, text,
  jsonb, jsonb
) is 'Additive rich Product CORE create. Uses the existing products table and keeps v2 available for older clients.';

comment on function public.update_store_product_v2(
  uuid, text, text, text, text, numeric, jsonb, uuid, boolean, integer,
  integer, text, numeric, text, text, text, text, jsonb, jsonb,
  boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean,
  boolean, boolean, boolean
) is 'Additive rich Product CORE update. Legacy update_store_product stays available for older clients.';

-- Owner preview must expose the same Product CORE fields as the published storefront.
-- Public RLS stays unchanged; access still requires the consumed owner session token.
create or replace function public.get_owner_catalog_for_session(p_session_token text)
returns jsonb
language plpgsql
security definer
set search_path = 'pg_catalog', 'public', 'extensions'
as $$
declare
  v_token text := pg_catalog.btrim(coalesce(p_session_token, ''));
  v_token_hash text;
  v_store_id uuid;
  v_is_demo boolean;
begin
  if v_token = '' or pg_catalog.length(v_token) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  v_token_hash := extensions.encode(extensions.sha256(v_token::bytea), 'hex');

  select s.store_id, st.is_demo
    into v_store_id, v_is_demo
  from public.owner_sessions as s
  join public.stores as st on st.id = s.store_id
  where s.session_token_hash = v_token_hash
    and s.consumed_at is not null
    and s.expires_at > pg_catalog.now();

  if not found then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;
  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE' using errcode = 'P0001';
  end if;

  return pg_catalog.jsonb_build_object(
    'categories', coalesce((
      select pg_catalog.jsonb_agg(
        pg_catalog.jsonb_build_object(
          'id', c.id,
          'name', c.name,
          'product_template_key', c.product_template_key
        ) order by c.sort_order, c.id
      )
      from public.product_categories as c
      where c.store_id = v_store_id and c.is_active = true
    ), '[]'::jsonb),
    'products', coalesce((
      select pg_catalog.jsonb_agg(
        pg_catalog.jsonb_build_object(
          'id', p.id,
          'name', p.name,
          'slug', p.slug,
          'description', p.description,
          'price_text', p.price_text,
          'price_amount', p.price_amount,
          'old_price_amount', p.old_price_amount,
          'badge_tag', p.badge_tag,
          'fulfillment_region', p.fulfillment_region,
          'currency', p.currency,
          'stock_status', p.stock_status,
          'stock_quantity', p.stock_quantity,
          'brand', p.brand,
          'barcode', p.barcode,
          'metadata', p.metadata,
          'variants', p.variants,
          'image_urls', p.image_urls,
          'category_id', p.category_id,
          'is_visible', p.is_visible,
          'is_active', p.is_active,
          'source_type', p.source_type,
          'sort_order', p.sort_order
        ) order by p.sort_order, p.id
      )
      from public.products as p
      where p.store_id = v_store_id and p.is_active = true and p.is_visible = true
    ), '[]'::jsonb)
  );
end;
$$;

alter function public.get_owner_catalog_for_session(text) owner to postgres;
revoke execute on function public.get_owner_catalog_for_session(text) from public;
grant execute on function public.get_owner_catalog_for_session(text) to anon, authenticated, service_role;

-- Bulk upload uses the same category template semantics as single-product create.
-- It does not invent rich attributes or variants; it only writes the explicit
-- item kind/template identity required for storefront/owner parity.
create or replace function public.batch_create_products(
  p_store_id uuid,
  p_edit_token text,
  p_products jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = 'pg_catalog', 'public', 'auth'
as $$
declare
  v_product jsonb;
  v_success_count integer := 0;
  v_error_count integer := 0;
  v_errors jsonb := '[]'::jsonb;
  v_index integer := 0;
begin
  if not public._check_store_authorization(p_store_id, p_edit_token) then
    raise exception 'UNAUTHORIZED';
  end if;

  if pg_catalog.jsonb_typeof(coalesce(p_products, '[]'::jsonb)) <> 'array' then
    raise exception 'PRODUCTS_INVALID';
  end if;

  for v_product in select * from pg_catalog.jsonb_array_elements(p_products)
  loop
    v_index := v_index + 1;
    begin
      declare
        v_name text := coalesce(v_product->>'name', '');
        v_slug text := coalesce(v_product->>'slug', '');
        v_description text := coalesce(v_product->>'description', '');
        v_price_text text := coalesce(v_product->>'price_text', '');
        v_price_amount numeric := null;
        v_image_urls jsonb := coalesce(v_product->'image_urls', '[]'::jsonb);
        v_category_id uuid := null;
        v_template_key text := 'generic';
        v_item_kind text := 'physical';
        v_metadata jsonb;
        v_source_type text := coalesce(v_product->>'source_type', 'bulk_import');
        v_external_product_id text := nullif(pg_catalog.btrim(coalesce(v_product->>'external_product_id', '')), '');
        v_is_visible boolean := coalesce((v_product->>'isVisible')::boolean, true);
        v_sort_order integer := coalesce((v_product->>'sort_order')::integer, 0);
      begin
        if pg_catalog.length(pg_catalog.btrim(v_name)) = 0 then
          v_error_count := v_error_count + 1;
          v_errors := v_errors || pg_catalog.jsonb_build_object('index', v_index, 'error', 'EMPTY_NAME');
          continue;
        end if;

        if pg_catalog.length(pg_catalog.btrim(v_slug)) = 0 then
          v_slug := lower(pg_catalog.regexp_replace(pg_catalog.regexp_replace(v_name, '[^a-zA-Z0-9\s-]', '', 'g'), '\s+', '-', 'g'));
          if exists (select 1 from public.products where store_id = p_store_id and slug = v_slug) then
            v_slug := v_slug || '-' || pg_catalog.substr(pg_catalog.md5(pg_catalog.random()::text), 1, 6);
          end if;
        end if;

        if v_price_amount is null and pg_catalog.length(v_price_text) > 0 then
          v_price_amount := nullif(pg_catalog.regexp_replace(pg_catalog.regexp_replace(v_price_text, '[^0-9.,]', '', 'g'), ',', '.', 'g'), '')::numeric;
        end if;

        if v_product->>'category_id' is not null then
          select pc.id, pc.product_template_key
            into v_category_id, v_template_key
          from public.product_categories as pc
          where pc.id = (v_product->>'category_id')::uuid
            and pc.store_id = p_store_id;
        end if;

        v_template_key := coalesce(nullif(pg_catalog.btrim(v_template_key), ''), 'generic');
        v_item_kind := case when v_template_key = 'service' then 'service' else 'physical' end;
        v_metadata := pg_catalog.jsonb_build_object(
          'schemaVersion', 1,
          'itemKind', v_item_kind,
          'templateKey', v_template_key,
          'attributes', '[]'::jsonb
        );

        insert into public.products (
          store_id,
          category_id,
          source_type,
          external_product_id,
          name,
          slug,
          description,
          price_text,
          price_amount,
          image_urls,
          is_visible,
          sort_order,
          stock_quantity,
          stock_status,
          brand,
          barcode,
          metadata,
          variants
        ) values (
          p_store_id,
          v_category_id,
          v_source_type,
          v_external_product_id,
          v_name,
          v_slug,
          v_description,
          v_price_text,
          v_price_amount,
          v_image_urls,
          v_is_visible,
          v_sort_order,
          case when v_item_kind = 'service' then null else null end,
          null,
          null,
          null,
          v_metadata,
          '[]'::jsonb
        );
        v_success_count := v_success_count + 1;
      exception when others then
        v_error_count := v_error_count + 1;
        v_errors := v_errors || pg_catalog.jsonb_build_object('index', v_index, 'error', sqlerrm);
      end;
    end;
  end loop;

  return pg_catalog.jsonb_build_object(
    'success', true,
    'total', v_index,
    'inserted', v_success_count,
    'errors', v_error_count,
    'error_details', v_errors
  );
end;
$$;

alter function public.batch_create_products(uuid, text, jsonb) owner to postgres;
revoke execute on function public.batch_create_products(uuid, text, jsonb) from public;
grant execute on function public.batch_create_products(uuid, text, jsonb) to anon, authenticated, service_role;
