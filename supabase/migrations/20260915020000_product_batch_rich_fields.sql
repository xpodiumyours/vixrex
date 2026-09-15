create or replace function public._parse_product_price_amount(p_value text)
returns numeric
language plpgsql
immutable
set search_path = 'pg_catalog', 'public'
as $$
declare
  v_clean text := pg_catalog.regexp_replace(pg_catalog.btrim(coalesce(p_value, '')), '[^0-9.,]', '', 'g');
  v_last_comma integer;
  v_last_dot integer;
begin
  if v_clean = '' then
    return null;
  end if;

  v_last_comma := case
    when pg_catalog.strpos(v_clean, ',') = 0 then 0
    else pg_catalog.length(v_clean) - pg_catalog.strpos(pg_catalog.reverse(v_clean), ',') + 1
  end;
  v_last_dot := case
    when pg_catalog.strpos(v_clean, '.') = 0 then 0
    else pg_catalog.length(v_clean) - pg_catalog.strpos(pg_catalog.reverse(v_clean), '.') + 1
  end;

  if v_last_comma > 0 and v_last_dot > 0 then
    if v_last_comma > v_last_dot then
      v_clean := pg_catalog.replace(v_clean, '.', '');
      v_clean := pg_catalog.replace(v_clean, ',', '.');
    else
      v_clean := pg_catalog.replace(v_clean, ',', '');
    end if;
  elsif v_last_comma > 0 then
    v_clean := pg_catalog.replace(v_clean, ',', '.');
  elsif v_clean ~ '^[0-9]{1,3}(\.[0-9]{3})+$' then
    v_clean := pg_catalog.replace(v_clean, '.', '');
  end if;

  if v_clean !~ '^[0-9]+(\.[0-9]+)?$' then
    raise exception 'PRODUCT_PRICE_INVALID';
  end if;

  return v_clean::numeric;
end;
$$;

alter function public._parse_product_price_amount(text) owner to postgres;
revoke execute on function public._parse_product_price_amount(text) from public, anon, authenticated;
grant execute on function public._parse_product_price_amount(text) to service_role;

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
  v_result jsonb;
  v_category_slug text;
  v_variants jsonb;
  v_success_count integer := 0;
  v_error_count integer := 0;
  v_errors jsonb := '[]'::jsonb;
  v_index integer := 0;
  v_name text;
  v_description text;
  v_price_text text;
  v_price_amount numeric;
  v_image_urls jsonb;
  v_category_id uuid;
  v_category_name text;
  v_template_key text;
  v_item_kind text;
  v_metadata jsonb;
  v_source_type text;
  v_external_product_id text;
  v_is_visible boolean;
  v_sort_order integer;
  v_brand text;
  v_barcode text;
  v_sku text;
  v_stock_quantity integer;
  v_stock_status text;
begin
  if not public._check_store_authorization(p_store_id, p_edit_token) then
    raise exception 'UNAUTHORIZED';
  end if;

  if pg_catalog.jsonb_typeof(coalesce(p_products, '[]'::jsonb)) <> 'array' then
    raise exception 'PRODUCTS_INVALID';
  end if;

  for v_product in
    select value from pg_catalog.jsonb_array_elements(p_products)
  loop
    v_index := v_index + 1;
    begin
      if pg_catalog.jsonb_typeof(v_product) is distinct from 'object' then
        raise exception 'PRODUCT_INVALID';
      end if;
      v_name := pg_catalog.btrim(coalesce(v_product->>'name', ''));
      v_description := coalesce(v_product->>'description', '');
      v_price_text := coalesce(v_product->>'price_text', '');
      v_price_amount := null;
      v_image_urls := coalesce(v_product->'image_urls', '[]'::jsonb);
      v_category_id := null;
      v_category_name := pg_catalog.btrim(coalesce(v_product->>'category_name', ''));
      v_template_key := 'generic';
      v_item_kind := 'physical';
      v_source_type := coalesce(nullif(pg_catalog.btrim(v_product->>'source_type'), ''), 'bulk_import');
      v_external_product_id := nullif(pg_catalog.btrim(coalesce(v_product->>'external_product_id', '')), '');
      v_is_visible := coalesce((v_product->>'isVisible')::boolean, true);
      v_sort_order := coalesce((v_product->>'sort_order')::integer, 0);
      v_brand := nullif(pg_catalog.btrim(coalesce(v_product->>'brand', '')), '');
      v_barcode := nullif(pg_catalog.btrim(coalesce(v_product->>'barcode', '')), '');
      v_sku := nullif(pg_catalog.btrim(coalesce(v_product->>'sku', '')), '');
      v_stock_quantity := null;
      v_stock_status := nullif(pg_catalog.btrim(coalesce(v_product->>'stock_status', '')), '');

      if v_name = '' then
        raise exception 'EMPTY_NAME';
      end if;

      if pg_catalog.jsonb_typeof(v_image_urls) is distinct from 'array' then
        raise exception 'PRODUCT_IMAGES_INVALID';
      end if;

      if pg_catalog.jsonb_array_length(v_image_urls) > 11 or exists (
        select 1 from pg_catalog.jsonb_array_elements(v_image_urls) as image(value)
        where pg_catalog.jsonb_typeof(image.value) <> 'string'
          or pg_catalog.btrim(image.value #>> '{}') !~* '^https?://[^[:space:]/?#]+[^[:space:]]*$'
      ) then
        raise exception 'PRODUCT_IMAGES_INVALID';
      end if;

      if pg_catalog.btrim(v_price_text) <> '' then
        v_price_amount := public._parse_product_price_amount(v_price_text);
      end if;

      if nullif(pg_catalog.btrim(coalesce(v_product->>'stock_quantity', '')), '') is not null then
        v_stock_quantity := (v_product->>'stock_quantity')::integer;
        if v_stock_quantity < 0 then
          raise exception 'PRODUCT_STOCK_INVALID';
        end if;
      end if;

      if nullif(pg_catalog.btrim(coalesce(v_product->>'category_id', '')), '') is not null then
        select pc.id, pc.product_template_key
          into v_category_id, v_template_key
        from public.product_categories as pc
        where pc.id = (v_product->>'category_id')::uuid
          and pc.store_id = p_store_id
          and pc.is_active = true;

        if v_category_id is null then
          raise exception 'CATEGORY_NOT_IN_SAME_STORE';
        end if;
      elsif v_category_name <> '' then
        select pc.id, pc.product_template_key
          into v_category_id, v_template_key
        from public.product_categories as pc
        where pc.store_id = p_store_id
          and pc.is_active = true
          and pg_catalog.lower(pc.name) = pg_catalog.lower(v_category_name)
        order by pc.sort_order, pc.id
        limit 1;

        if v_category_id is null then
          v_category_slug := public._normalize_product_slug(v_category_name);
          if v_category_slug is null or v_category_slug = '' then
            v_category_slug := 'kategori';
          end if;
          if exists (
            select 1 from public.product_categories
            where store_id = p_store_id and slug = v_category_slug
          ) then
            v_category_slug := v_category_slug || '-' || pg_catalog.substr(pg_catalog.md5(v_category_name), 1, 8);
          end if;
          insert into public.product_categories (store_id, name, slug, product_template_key)
          values (p_store_id, v_category_name, v_category_slug, 'generic')
          returning id, product_template_key into v_category_id, v_template_key;
        end if;
      end if;

      v_template_key := coalesce(nullif(pg_catalog.btrim(v_template_key), ''), 'generic');
      v_item_kind := case when v_template_key = 'service' then 'service' else 'physical' end;
      v_metadata := coalesce(v_product->'metadata', '{}'::jsonb);
      v_variants := coalesce(v_product->'variants', '[]'::jsonb);
      if pg_catalog.jsonb_typeof(v_metadata) is distinct from 'object' then
        raise exception 'PRODUCT_METADATA_INVALID';
      end if;
      if pg_catalog.jsonb_typeof(v_variants) is distinct from 'array' then
        raise exception 'PRODUCT_VARIANTS_INVALID';
      end if;
      v_metadata := pg_catalog.jsonb_build_object(
        'schemaVersion', 2,
        'itemKind', v_item_kind,
        'attributes', '[]'::jsonb
      ) || v_metadata;
      if not (v_metadata ? 'templateKey') then
        v_metadata := v_metadata || pg_catalog.jsonb_build_object('templateKey', v_template_key);
      end if;
      if v_sku is not null then
        if v_metadata ? 'identifiers' and pg_catalog.jsonb_typeof(v_metadata->'identifiers') <> 'object' then
          raise exception 'PRODUCT_METADATA_INVALID';
        end if;
        v_metadata := v_metadata || pg_catalog.jsonb_build_object(
          'identifiers', coalesce(v_metadata->'identifiers', '{}'::jsonb) || pg_catalog.jsonb_build_object('sku', v_sku)
        );
      end if;

      v_result := public.create_store_product_v3(
        p_store_id => p_store_id,
        p_edit_token => p_edit_token,
        p_name => v_name,
        p_description => v_description,
        p_price_text => v_price_text,
        p_price_amount => v_price_amount,
        p_image_urls => v_image_urls,
        p_category_id => v_category_id,
        p_source_type => v_source_type,
        p_external_product_id => v_external_product_id,
        p_is_visible => v_is_visible,
        p_sort_order => v_sort_order,
        p_brand => v_brand,
        p_barcode => v_barcode,
        p_stock_quantity => v_stock_quantity,
        p_stock_status => v_stock_status,
        p_metadata => v_metadata,
        p_variants => v_variants
      );

      if coalesce((v_result->>'success')::boolean, false) then
        if coalesce((v_result->>'created')::boolean, true) then
          v_success_count := v_success_count + 1;
        else
          raise exception 'PRODUCT_ALREADY_EXISTS';
        end if;
      else
        raise exception 'PRODUCT_CREATE_FAILED';
      end if;
    exception when others then
      v_error_count := v_error_count + 1;
      v_errors := v_errors || pg_catalog.jsonb_build_array(
        pg_catalog.jsonb_build_object(
          'index', v_index,
          'error', sqlerrm
        )
      );
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
