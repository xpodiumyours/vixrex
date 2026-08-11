-- Product CORE slug authority.
--
-- Expand/contract strategy:
-- - Existing create_store_product remains available for older clients.
-- - New clients use create_store_product_v2 and never generate canonical slugs.
-- - The trigger owns final slug canonicalization for every relational writer.
-- - Legacy writers may provide a slug seed until old Flutter clients retire.
-- - Existing product slugs remain stable on updates.

create or replace function public._normalize_product_slug(p_value text)
returns text
language sql
immutable
set search_path = ''
as $$
  select coalesce(
    nullif(
      pg_catalog.btrim(
        pg_catalog.regexp_replace(
          pg_catalog.lower(
            pg_catalog.translate(
              coalesce(p_value, ''),
              'ÇĞİIÖŞÜÂÎÛçğıöşüâîû',
              'CGIIOSUAIUcgiosuaiu'
            )
          ),
          '[^a-z0-9]+',
          '-',
          'g'
        ),
        '-'
      ),
      ''
    ),
    'urun'
  );
$$;

alter function public._normalize_product_slug(text) owner to postgres;
revoke execute on function public._normalize_product_slug(text) from public;
revoke execute on function public._normalize_product_slug(text) from anon, authenticated;

create or replace function public.set_product_canonical_slug()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_base_slug text;
  v_candidate text;
  v_suffix integer := 2;
begin
  if tg_op = 'UPDATE' then
    new.slug := old.slug;
    return new;
  end if;

  -- Legacy v1 compatibility: released clients keep the slug they already
  -- stored locally. CORE still normalizes and validates the final DB value.
  -- create_store_product_v2 sends an empty slug and follows the name-based
  -- canonical path below. Remove this branch only in a later contract phase.
  if nullif(pg_catalog.btrim(coalesce(new.slug, '')), '') is not null then
    new.slug := public._normalize_product_slug(new.slug);
    return new;
  end if;

  v_base_slug := public._normalize_product_slug(new.name);

  -- Serialize every slug assignment in the same store. A base-only lock would
  -- still allow `urun` and `urun-2` writers to race for the same candidate.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      new.store_id::text,
      0
    )
  );

  v_candidate := v_base_slug;
  while exists (
    select 1
    from public.products as p
    where p.store_id = new.store_id
      and p.slug = v_candidate
  ) loop
    v_candidate := v_base_slug || '-' || v_suffix::text;
    v_suffix := v_suffix + 1;
  end loop;

  -- products_store_id_slug_key remains the final database guard.
  new.slug := v_candidate;
  return new;
end;
$$;

alter function public.set_product_canonical_slug() owner to postgres;
revoke execute on function public.set_product_canonical_slug() from public;
revoke execute on function public.set_product_canonical_slug() from anon, authenticated;

create trigger product_canonical_slug_guard
before insert or update on public.products
for each row
execute function public.set_product_canonical_slug();

-- Keep the legacy RPC signature callable while making product URLs immutable.
-- p_slug is accepted for binary/API compatibility but intentionally ignored.
create or replace function public.update_store_product(
  p_product_id uuid,
  p_edit_token text default null,
  p_name text default null,
  p_slug text default null,
  p_description text default null,
  p_price_text text default null,
  p_price_amount numeric default null,
  p_image_urls jsonb default null,
  p_category_id uuid default null,
  p_is_visible boolean default null,
  p_sort_order integer default null,
  p_stock_quantity integer default null,
  p_stock_status text default null,
  p_clear_category boolean default false,
  p_clear_price_amount boolean default false,
  p_clear_stock_quantity boolean default false,
  p_clear_stock_status boolean default false,
  p_old_price_amount numeric default null,
  p_badge_tag text default null,
  p_fulfillment_region text default null,
  p_clear_old_price_amount boolean default false,
  p_clear_badge_tag boolean default false,
  p_clear_fulfillment_region boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_store_id uuid;
begin
  select p.store_id
  into v_store_id
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
      when p_fulfillment_region is not null
        then nullif(pg_catalog.btrim(p_fulfillment_region), '')
      else p.fulfillment_region
    end
  where p.id = p_product_id;

  return pg_catalog.jsonb_build_object(
    'id', p_product_id,
    'success', true
  );
end;
$$;

alter function public.update_store_product(
  uuid,
  text,
  text,
  text,
  text,
  text,
  numeric,
  jsonb,
  uuid,
  boolean,
  integer,
  integer,
  text,
  boolean,
  boolean,
  boolean,
  boolean,
  numeric,
  text,
  text,
  boolean,
  boolean,
  boolean
) owner to postgres;

comment on function public.update_store_product(
  uuid,
  text,
  text,
  text,
  text,
  text,
  numeric,
  jsonb,
  uuid,
  boolean,
  integer,
  integer,
  text,
  boolean,
  boolean,
  boolean,
  boolean,
  numeric,
  text,
  text,
  boolean,
  boolean,
  boolean
) is 'Product CORE update interface. The legacy p_slug argument is accepted but ignored so canonical URLs remain stable.';

create or replace function public.create_store_product_v2(
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
  p_fulfillment_region text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_new_product uuid;
  v_new_slug text;
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

  if p_category_id is not null and not exists (
    select 1
    from public.product_categories as pc
    where pc.id = p_category_id
      and pc.store_id = p_store_id
  ) then
    raise exception 'CATEGORY_NOT_IN_SAME_STORE';
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
      fulfillment_region
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
      nullif(
        pg_catalog.btrim(coalesce(p_badge_tag, '')),
        ''
      ),
      nullif(
        pg_catalog.btrim(coalesce(p_fulfillment_region, '')),
        ''
      )
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

alter function public.create_store_product_v2(
  uuid,
  text,
  text,
  text,
  text,
  numeric,
  jsonb,
  uuid,
  text,
  text,
  boolean,
  integer,
  numeric,
  text,
  text
) owner to postgres;

revoke execute on function public.create_store_product_v2(
  uuid,
  text,
  text,
  text,
  text,
  numeric,
  jsonb,
  uuid,
  text,
  text,
  boolean,
  integer,
  numeric,
  text,
  text
) from public;

grant execute on function public.create_store_product_v2(
  uuid,
  text,
  text,
  text,
  text,
  numeric,
  jsonb,
  uuid,
  text,
  text,
  boolean,
  integer,
  numeric,
  text,
  text
) to anon, authenticated, service_role;

comment on function public.create_store_product_v2(
  uuid,
  text,
  text,
  text,
  text,
  numeric,
  jsonb,
  uuid,
  text,
  text,
  boolean,
  integer,
  numeric,
  text,
  text
) is 'Product CORE create interface. Canonical slug is generated by the database and returned with the product id.';

-- ROLLBACK SQL (run only after reverting clients to create_store_product):
-- drop trigger product_canonical_slug_guard on public.products;
-- drop function public.create_store_product_v2(uuid, text, text, text, text,
--   numeric, jsonb, uuid, text, text, boolean, integer, numeric, text, text);
-- drop function public.set_product_canonical_slug();
-- drop function public._normalize_product_slug(text);
