-- Vixrex Product CORE parity for owner preview and bulk upload.
-- Keeps the existing owner-session/edit-token authorization model.
-- No second product store or alternate write path is introduced.

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
      where c.store_id = v_store_id
        and c.is_active = true
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
      where p.store_id = v_store_id
        and p.is_active = true
        and p.is_visible = true
    ), '[]'::jsonb)
  );
end;
$$;

alter function public.get_owner_catalog_for_session(text) owner to postgres;
revoke execute on function public.get_owner_catalog_for_session(text) from public;
grant execute on function public.get_owner_catalog_for_session(text) to anon, authenticated, service_role;

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
  v_template_key text;
  v_item_kind text;
  v_metadata jsonb;
  v_source_type text;
  v_external_product_id text;
  v_is_visible boolean;
  v_sort_order integer;
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
      v_name := pg_catalog.btrim(coalesce(v_product->>'name', ''));
      v_description := coalesce(v_product->>'description', '');
      v_price_text := coalesce(v_product->>'price_text', '');
      v_price_amount := null;
      v_image_urls := coalesce(v_product->'image_urls', '[]'::jsonb);
      v_category_id := null;
      v_template_key := 'generic';
      v_item_kind := 'physical';
      v_source_type := coalesce(nullif(pg_catalog.btrim(v_product->>'source_type'), ''), 'bulk_import');
      v_external_product_id := nullif(pg_catalog.btrim(coalesce(v_product->>'external_product_id', '')), '');
      v_is_visible := coalesce((v_product->>'isVisible')::boolean, true);
      v_sort_order := coalesce((v_product->>'sort_order')::integer, 0);

      if v_name = '' then
        raise exception 'EMPTY_NAME';
      end if;

      if pg_catalog.btrim(v_price_text) <> '' then
        v_price_amount := nullif(
          pg_catalog.regexp_replace(
            pg_catalog.regexp_replace(v_price_text, '[^0-9.,]', '', 'g'),
            ',',
            '.',
            'g'
          ),
          ''
        )::numeric;
      end if;

      if nullif(pg_catalog.btrim(coalesce(v_product->>'category_id', '')), '') is not null then
        select pc.id, pc.product_template_key
          into v_category_id, v_template_key
        from public.product_categories as pc
        where pc.id = (v_product->>'category_id')::uuid
          and pc.store_id = p_store_id;

        if v_category_id is null then
          raise exception 'CATEGORY_NOT_IN_SAME_STORE';
        end if;
      end if;

      v_template_key := coalesce(nullif(pg_catalog.btrim(v_template_key), ''), 'generic');
      v_item_kind := case when v_template_key = 'service' then 'service' else 'physical' end;
      v_metadata := pg_catalog.jsonb_build_object(
        'schemaVersion', 1,
        'itemKind', v_item_kind,
        'templateKey', v_template_key,
        'attributes', '[]'::jsonb
      );

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
        p_stock_quantity => null,
        p_stock_status => null,
        p_metadata => v_metadata,
        p_variants => '[]'::jsonb
      );

      if coalesce((v_result->>'success')::boolean, false) then
        v_success_count := v_success_count + 1;
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
