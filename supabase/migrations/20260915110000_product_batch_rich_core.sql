-- Toplu ürün yüklemeyi mevcut zengin Product CORE yazma yoluna bağlar.
--
-- Güvenlik / geriye uyumluluk:
-- - batch_create_products(uuid, text, jsonb) imzası değişmez.
-- - Eski temel payload'lar çalışmaya devam eder.
-- - Rich alanlar create_store_product_v3 üzerinden tek Product CORE'a yazılır.
-- - Bir hatalı satır bütün batch'i geri almaz; hata satır bazında döner.
-- - Minimum 3 görsel burada uygulanmaz. Bu bir içe aktarma katmanıdır;
--   minimum görsel sayısı yalnız yayın kalite kapısının sorumluluğudur.
-- - 11 görsel üst sınırı korunur.

create or replace function public._parse_product_price_amount(p_value text)
returns numeric
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_value text := pg_catalog.btrim(coalesce(p_value, ''));
  v_clean text;
  v_last_comma integer;
  v_last_dot integer;
begin
  if v_value = '' then
    return null;
  end if;

  -- Para birimi ve diğer metinleri at; rakam, işaret ve ayraçlar kalsın.
  v_clean := pg_catalog.regexp_replace(v_value, '[^0-9,.-]', '', 'g');
  if v_clean = '' or v_clean in ('-', '.', ',', '-.', '-,') then
    return null;
  end if;

  v_last_comma := pg_catalog.length(v_clean) - pg_catalog.strpos(pg_catalog.reverse(v_clean), ',') + 1;
  if pg_catalog.strpos(v_clean, ',') = 0 then
    v_last_comma := 0;
  end if;

  v_last_dot := pg_catalog.length(v_clean) - pg_catalog.strpos(pg_catalog.reverse(v_clean), '.') + 1;
  if pg_catalog.strpos(v_clean, '.') = 0 then
    v_last_dot := 0;
  end if;

  if v_last_comma > 0 and v_last_dot > 0 then
    if v_last_comma > v_last_dot then
      -- 1.250,50 -> 1250.50
      v_clean := pg_catalog.replace(v_clean, '.', '');
      v_clean := pg_catalog.replace(v_clean, ',', '.');
    else
      -- 1,250.50 -> 1250.50
      v_clean := pg_catalog.replace(v_clean, ',', '');
    end if;
  elsif v_last_comma > 0 then
    if v_clean ~ ',[0-9]{1,2}$' then
      v_clean := pg_catalog.replace(v_clean, ',', '.');
    else
      v_clean := pg_catalog.replace(v_clean, ',', '');
    end if;
  elsif v_last_dot > 0 then
    if v_clean ~ '^[+-]?[0-9]{1,3}(\.[0-9]{3})+$' then
      v_clean := pg_catalog.replace(v_clean, '.', '');
    end if;
  end if;

  begin
    return v_clean::numeric;
  exception
    when invalid_text_representation or numeric_value_out_of_range then
      return null;
  end;
end;
$$;

alter function public._parse_product_price_amount(text) owner to postgres;
revoke execute on function public._parse_product_price_amount(text) from public;
grant execute on function public._parse_product_price_amount(text) to service_role;

create or replace function public.batch_create_products(
  p_store_id uuid,
  p_edit_token text,
  p_products jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_product jsonb;
  v_index integer := 0;
  v_success_count integer := 0;
  v_error_count integer := 0;
  v_errors jsonb := '[]'::jsonb;

  v_name text;
  v_description text;
  v_price_text text;
  v_price_amount numeric;
  v_image_urls jsonb;
  v_category_id uuid;
  v_category_name text;
  v_category_result jsonb;
  v_source_type text;
  v_external_product_id text;
  v_is_visible boolean;
  v_sort_order integer;
  v_brand text;
  v_barcode text;
  v_sku text;
  v_stock_quantity integer;
  v_stock_status text;
  v_metadata jsonb;
  v_identifiers jsonb;
  v_variants jsonb;
  v_old_price_amount numeric;
  v_badge_tag text;
  v_fulfillment_region text;
  v_created jsonb;
begin
  if not public._check_store_authorization(p_store_id, p_edit_token) then
    raise exception 'UNAUTHORIZED';
  end if;

  if p_products is null or pg_catalog.jsonb_typeof(p_products) <> 'array' then
    raise exception 'PRODUCT_BATCH_INVALID';
  end if;

  if pg_catalog.jsonb_array_length(p_products) > 3000 then
    raise exception 'PRODUCT_BATCH_TOO_LARGE';
  end if;

  for v_product in
    select value from pg_catalog.jsonb_array_elements(p_products)
  loop
    v_index := v_index + 1;

    begin
      if pg_catalog.jsonb_typeof(v_product) <> 'object' then
        raise exception 'PRODUCT_ROW_INVALID';
      end if;

      v_name := pg_catalog.btrim(coalesce(v_product->>'name', ''));
      if v_name = '' then
        raise exception 'PRODUCT_NAME_REQUIRED';
      end if;

      v_description := coalesce(v_product->>'description', '');
      v_price_text := coalesce(v_product->>'price_text', '');
      v_price_amount := case
        when nullif(pg_catalog.btrim(coalesce(v_product->>'price_amount', '')), '') is not null
          then (v_product->>'price_amount')::numeric
        else public._parse_product_price_amount(v_price_text)
      end;

      v_image_urls := coalesce(v_product->'image_urls', '[]'::jsonb);
      if pg_catalog.jsonb_typeof(v_image_urls) <> 'array' then
        raise exception 'PRODUCT_IMAGES_INVALID';
      end if;
      if pg_catalog.jsonb_array_length(v_image_urls) > 11 then
        raise exception 'PRODUCT_IMAGES_MAX_11';
      end if;

      v_category_id := null;
      if nullif(pg_catalog.btrim(coalesce(v_product->>'category_id', '')), '') is not null then
        v_category_id := (v_product->>'category_id')::uuid;
      end if;

      v_category_name := nullif(pg_catalog.btrim(coalesce(v_product->>'category_name', '')), '');
      if v_category_id is null and v_category_name is not null then
        select pc.id
        into v_category_id
        from public.product_categories as pc
        where pc.store_id = p_store_id
          and pc.is_active = true
          and pg_catalog.lower(pg_catalog.btrim(pc.name)) = pg_catalog.lower(v_category_name)
        order by pc.sort_order, pc.created_at
        limit 1;

        if v_category_id is null then
          v_category_result := public.upsert_store_category_v2(
            p_store_id => p_store_id,
            p_edit_token => p_edit_token,
            p_name => v_category_name,
            p_template_key => 'generic',
            p_slug => null,
            p_sort_order => 0
          );
          v_category_id := nullif(v_category_result->>'id', '')::uuid;
        end if;
      end if;

      v_source_type := coalesce(
        nullif(pg_catalog.btrim(coalesce(v_product->>'source_type', '')), ''),
        'bulk_import'
      );
      v_external_product_id := nullif(
        pg_catalog.btrim(coalesce(v_product->>'external_product_id', '')),
        ''
      );

      v_is_visible := case
        when v_product ? 'isVisible' then (v_product->>'isVisible')::boolean
        when v_product ? 'is_visible' then (v_product->>'is_visible')::boolean
        else true
      end;
      v_sort_order := coalesce(
        nullif(pg_catalog.btrim(coalesce(v_product->>'sort_order', '')), '')::integer,
        v_index - 1
      );

      v_brand := nullif(pg_catalog.btrim(coalesce(v_product->>'brand', '')), '');
      v_barcode := nullif(pg_catalog.btrim(coalesce(v_product->>'barcode', '')), '');
      v_sku := nullif(pg_catalog.btrim(coalesce(v_product->>'sku', '')), '');
      v_stock_quantity := case
        when nullif(pg_catalog.btrim(coalesce(v_product->>'stock_quantity', '')), '') is null then null
        else (v_product->>'stock_quantity')::integer
      end;
      if v_stock_quantity is not null and v_stock_quantity < 0 then
        raise exception 'PRODUCT_STOCK_INVALID';
      end if;
      v_stock_status := nullif(pg_catalog.btrim(coalesce(v_product->>'stock_status', '')), '');

      v_metadata := coalesce(v_product->'metadata', '{}'::jsonb);
      if pg_catalog.jsonb_typeof(v_metadata) <> 'object' then
        raise exception 'PRODUCT_METADATA_INVALID';
      end if;

      -- SKU artık ayrı ikinci bir ürün modeli oluşturmaz; Product CORE'un
      -- identifiers alanına eklenir. Mevcut diğer identifier'lar korunur.
      if v_sku is not null then
        v_identifiers := case
          when pg_catalog.jsonb_typeof(v_metadata->'identifiers') = 'object'
            then v_metadata->'identifiers'
          else '{}'::jsonb
        end;
        v_metadata := pg_catalog.jsonb_set(
          v_metadata,
          '{identifiers}',
          v_identifiers || pg_catalog.jsonb_build_object('sku', v_sku),
          true
        );
      end if;

      if not (v_metadata ? 'schemaVersion') then
        v_metadata := pg_catalog.jsonb_set(v_metadata, '{schemaVersion}', '2'::jsonb, true);
      end if;

      v_variants := coalesce(v_product->'variants', '[]'::jsonb);
      if pg_catalog.jsonb_typeof(v_variants) <> 'array' then
        raise exception 'PRODUCT_VARIANTS_INVALID';
      end if;

      v_old_price_amount := case
        when nullif(pg_catalog.btrim(coalesce(v_product->>'old_price_amount', '')), '') is null then null
        else (v_product->>'old_price_amount')::numeric
      end;
      v_badge_tag := nullif(pg_catalog.btrim(coalesce(v_product->>'badge_tag', '')), '');
      v_fulfillment_region := nullif(
        pg_catalog.btrim(coalesce(v_product->>'fulfillment_region', '')),
        ''
      );

      v_created := public.create_store_product_v3(
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
        p_old_price_amount => v_old_price_amount,
        p_badge_tag => v_badge_tag,
        p_fulfillment_region => v_fulfillment_region,
        p_brand => v_brand,
        p_barcode => v_barcode,
        p_stock_quantity => v_stock_quantity,
        p_stock_status => v_stock_status,
        p_metadata => v_metadata,
        p_variants => v_variants
      );

      if coalesce((v_created->>'success')::boolean, false) then
        v_success_count := v_success_count + 1;
      else
        raise exception 'PRODUCT_CREATE_FAILED';
      end if;
    exception
      when others then
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
