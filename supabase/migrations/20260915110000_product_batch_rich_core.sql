-- Toplu ürün yüklemeyi mevcut zengin Product CORE yazma yoluna bağlar.
--
-- Güvenlik / geriye uyumluluk:
-- - batch_create_products(uuid, text, jsonb) imzası değişmez.
-- - Eski temel payload'lar çalışmaya devam eder.
-- - Kimlik önceliği: external_product_id -> barkod/GTIN -> SKU.
-- - Mevcut ürün bulunursa yalnız dolu/gelen alanlar güncellenir; boş alanlar
--   esnafın mevcut verisini silmez.
-- - Sayaçlar eklendi / güncellendi / değişmedi / hatalı olarak ayrılır.
-- - Bir hatalı satır bütün batch'i geri almaz; hata satır bazında döner.
-- - Minimum 3 görsel burada uygulanmaz. Bu bir içe aktarma katmanıdır;
--   minimum görsel sayısı yalnız yayın kalite kapısının sorumluluğudur.
-- - 11 görsel üst sınırı korunur.
-- - Otomatik ürün silme yapılmaz.

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
      v_clean := pg_catalog.replace(v_clean, '.', '');
      v_clean := pg_catalog.replace(v_clean, ',', '.');
    else
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
  v_inserted_count integer := 0;
  v_updated_count integer := 0;
  v_unchanged_count integer := 0;
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
  v_has_is_visible boolean;
  v_is_visible boolean;
  v_has_sort_order boolean;
  v_sort_order integer;
  v_brand text;
  v_barcode text;
  v_sku text;
  v_stock_quantity integer;
  v_stock_status text;
  v_input_metadata jsonb;
  v_create_metadata jsonb;
  v_update_metadata jsonb;
  v_identifiers jsonb;
  v_input_identifiers jsonb;
  v_variants jsonb;
  v_old_price_amount numeric;
  v_badge_tag text;
  v_fulfillment_region text;

  v_existing_id uuid;
  v_match_count integer;
  v_current public.products%rowtype;
  v_changed boolean;
  v_created jsonb;
  v_updated jsonb;
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

      v_description := nullif(pg_catalog.btrim(coalesce(v_product->>'description', '')), '');
      v_price_text := nullif(pg_catalog.btrim(coalesce(v_product->>'price_text', '')), '');
      v_price_amount := case
        when nullif(pg_catalog.btrim(coalesce(v_product->>'price_amount', '')), '') is not null
          then (v_product->>'price_amount')::numeric
        when v_price_text is not null
          then public._parse_product_price_amount(v_price_text)
        else null
      end;

      v_image_urls := case
        when v_product ? 'image_urls' then coalesce(v_product->'image_urls', '[]'::jsonb)
        else '[]'::jsonb
      end;
      if pg_catalog.jsonb_typeof(v_image_urls) <> 'array' then
        raise exception 'PRODUCT_IMAGES_INVALID';
      end if;
      if pg_catalog.jsonb_array_length(v_image_urls) > 11 then
        raise exception 'PRODUCT_IMAGES_MAX_11';
      end if;

      v_category_id := null;
      if nullif(pg_catalog.btrim(coalesce(v_product->>'category_id', '')), '') is not null then
        v_category_id := (v_product->>'category_id')::uuid;
        if not exists (
          select 1
          from public.product_categories as pc
          where pc.id = v_category_id
            and pc.store_id = p_store_id
        ) then
          raise exception 'CATEGORY_NOT_IN_SAME_STORE';
        end if;
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

      v_has_is_visible := (v_product ? 'isVisible') or (v_product ? 'is_visible');
      v_is_visible := case
        when v_product ? 'isVisible' then (v_product->>'isVisible')::boolean
        when v_product ? 'is_visible' then (v_product->>'is_visible')::boolean
        else null
      end;

      v_has_sort_order := v_product ? 'sort_order';
      v_sort_order := case
        when v_has_sort_order and nullif(pg_catalog.btrim(coalesce(v_product->>'sort_order', '')), '') is not null
          then (v_product->>'sort_order')::integer
        else null
      end;

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

      v_input_metadata := case
        when v_product ? 'metadata' then coalesce(v_product->'metadata', '{}'::jsonb)
        else '{}'::jsonb
      end;
      if pg_catalog.jsonb_typeof(v_input_metadata) <> 'object' then
        raise exception 'PRODUCT_METADATA_INVALID';
      end if;
      if v_input_metadata ? 'identifiers'
         and pg_catalog.jsonb_typeof(v_input_metadata->'identifiers') <> 'object' then
        raise exception 'PRODUCT_IDENTIFIERS_INVALID';
      end if;

      v_variants := case
        when v_product ? 'variants' then coalesce(v_product->'variants', '[]'::jsonb)
        else '[]'::jsonb
      end;
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

      -- Kimlik önceliği: external_product_id -> barkod/GTIN -> SKU.
      -- Bir kimlik alanı geldiyse yalnız o seviye kullanılır; ürün adı/slug
      -- hiçbir zaman kimlik kabul edilmez.
      v_existing_id := null;
      v_match_count := 0;

      if v_external_product_id is not null then
        select pg_catalog.count(*)::integer
        into v_match_count
        from public.products as p
        where p.store_id = p_store_id
          and p.external_product_id = v_external_product_id;

        if v_match_count = 1 then
          select p.id
          into v_existing_id
          from public.products as p
          where p.store_id = p_store_id
            and p.external_product_id = v_external_product_id
          limit 1;
        elsif v_match_count > 1 then
          raise exception 'PRODUCT_IDENTITY_AMBIGUOUS_EXTERNAL_ID';
        end if;
      elsif v_barcode is not null then
        select pg_catalog.count(*)::integer
        into v_match_count
        from public.products as p
        where p.store_id = p_store_id
          and p.barcode = v_barcode;

        if v_match_count = 1 then
          select p.id
          into v_existing_id
          from public.products as p
          where p.store_id = p_store_id
            and p.barcode = v_barcode
          limit 1;
        elsif v_match_count > 1 then
          raise exception 'PRODUCT_IDENTITY_AMBIGUOUS_BARCODE';
        end if;
      elsif v_sku is not null then
        select pg_catalog.count(*)::integer
        into v_match_count
        from public.products as p
        where p.store_id = p_store_id
          and nullif(pg_catalog.btrim(coalesce(p.metadata->'identifiers'->>'sku', '')), '') = v_sku;

        if v_match_count = 1 then
          select p.id
          into v_existing_id
          from public.products as p
          where p.store_id = p_store_id
            and nullif(pg_catalog.btrim(coalesce(p.metadata->'identifiers'->>'sku', '')), '') = v_sku
          limit 1;
        elsif v_match_count > 1 then
          raise exception 'PRODUCT_IDENTITY_AMBIGUOUS_SKU';
        end if;
      end if;

      if v_existing_id is null then
        v_create_metadata := v_input_metadata;
        if v_sku is not null then
          v_identifiers := case
            when pg_catalog.jsonb_typeof(v_create_metadata->'identifiers') = 'object'
              then v_create_metadata->'identifiers'
            else '{}'::jsonb
          end;
          v_create_metadata := pg_catalog.jsonb_set(
            v_create_metadata,
            '{identifiers}',
            v_identifiers || pg_catalog.jsonb_build_object('sku', v_sku),
            true
          );
        end if;
        if not (v_create_metadata ? 'schemaVersion') then
          v_create_metadata := pg_catalog.jsonb_set(
            v_create_metadata,
            '{schemaVersion}',
            '2'::jsonb,
            true
          );
        end if;

        v_created := public.create_store_product_v3(
          p_store_id => p_store_id,
          p_edit_token => p_edit_token,
          p_name => v_name,
          p_description => coalesce(v_description, ''),
          p_price_text => coalesce(v_price_text, ''),
          p_price_amount => v_price_amount,
          p_image_urls => v_image_urls,
          p_category_id => v_category_id,
          p_source_type => v_source_type,
          p_external_product_id => v_external_product_id,
          p_is_visible => coalesce(v_is_visible, true),
          p_sort_order => coalesce(v_sort_order, v_index - 1),
          p_old_price_amount => v_old_price_amount,
          p_badge_tag => v_badge_tag,
          p_fulfillment_region => v_fulfillment_region,
          p_brand => v_brand,
          p_barcode => v_barcode,
          p_stock_quantity => v_stock_quantity,
          p_stock_status => v_stock_status,
          p_metadata => v_create_metadata,
          p_variants => v_variants
        );

        if not coalesce((v_created->>'success')::boolean, false) then
          raise exception 'PRODUCT_CREATE_FAILED';
        end if;
        if not coalesce((v_created->>'created')::boolean, false) then
          raise exception 'PRODUCT_CREATE_CONFLICT';
        end if;

        v_inserted_count := v_inserted_count + 1;
        continue;
      end if;

      select p.*
      into v_current
      from public.products as p
      where p.id = v_existing_id;

      -- Metadata güncellemesi alan bazlı merge edilir. Dosyada olmayan mevcut
      -- identifiers/özellikler korunur; SKU yalnız geldiyse değiştirilir.
      v_update_metadata := null;
      if v_input_metadata <> '{}'::jsonb or v_sku is not null then
        v_update_metadata := coalesce(v_current.metadata, '{}'::jsonb);

        if v_input_metadata <> '{}'::jsonb then
          v_identifiers := case
            when pg_catalog.jsonb_typeof(v_update_metadata->'identifiers') = 'object'
              then v_update_metadata->'identifiers'
            else '{}'::jsonb
          end;
          v_input_identifiers := case
            when pg_catalog.jsonb_typeof(v_input_metadata->'identifiers') = 'object'
              then v_input_metadata->'identifiers'
            else '{}'::jsonb
          end;

          v_update_metadata :=
            (v_update_metadata - 'identifiers') || (v_input_metadata - 'identifiers');

          if (v_identifiers || v_input_identifiers) <> '{}'::jsonb then
            v_update_metadata := pg_catalog.jsonb_set(
              v_update_metadata,
              '{identifiers}',
              v_identifiers || v_input_identifiers,
              true
            );
          end if;
        end if;

        if v_sku is not null then
          v_identifiers := case
            when pg_catalog.jsonb_typeof(v_update_metadata->'identifiers') = 'object'
              then v_update_metadata->'identifiers'
            else '{}'::jsonb
          end;
          v_update_metadata := pg_catalog.jsonb_set(
            v_update_metadata,
            '{identifiers}',
            v_identifiers || pg_catalog.jsonb_build_object('sku', v_sku),
            true
          );
        end if;

        if not (v_update_metadata ? 'schemaVersion') then
          v_update_metadata := pg_catalog.jsonb_set(
            v_update_metadata,
            '{schemaVersion}',
            '2'::jsonb,
            true
          );
        end if;
      end if;

      v_changed := false;
      if v_current.name is distinct from v_name then
        v_changed := true;
      end if;
      if v_description is not null and v_current.description is distinct from v_description then
        v_changed := true;
      end if;
      if v_price_text is not null and v_current.price_text is distinct from v_price_text then
        v_changed := true;
      end if;
      if v_price_amount is not null and v_current.price_amount is distinct from v_price_amount then
        v_changed := true;
      end if;
      if pg_catalog.jsonb_array_length(v_image_urls) > 0
         and v_current.image_urls is distinct from v_image_urls then
        v_changed := true;
      end if;
      if v_category_id is not null and v_current.category_id is distinct from v_category_id then
        v_changed := true;
      end if;
      if v_has_is_visible and v_current.is_visible is distinct from v_is_visible then
        v_changed := true;
      end if;
      if v_has_sort_order and v_sort_order is not null
         and v_current.sort_order is distinct from v_sort_order then
        v_changed := true;
      end if;
      if v_stock_quantity is not null
         and v_current.stock_quantity is distinct from v_stock_quantity then
        v_changed := true;
      end if;
      if v_stock_status is not null
         and v_current.stock_status is distinct from v_stock_status then
        v_changed := true;
      end if;
      if v_old_price_amount is not null
         and v_current.old_price_amount is distinct from v_old_price_amount then
        v_changed := true;
      end if;
      if v_badge_tag is not null and v_current.badge_tag is distinct from v_badge_tag then
        v_changed := true;
      end if;
      if v_fulfillment_region is not null
         and v_current.fulfillment_region is distinct from v_fulfillment_region then
        v_changed := true;
      end if;
      if v_brand is not null and v_current.brand is distinct from v_brand then
        v_changed := true;
      end if;
      if v_barcode is not null and v_current.barcode is distinct from v_barcode then
        v_changed := true;
      end if;
      if v_update_metadata is not null
         and v_current.metadata is distinct from v_update_metadata then
        v_changed := true;
      end if;
      if pg_catalog.jsonb_array_length(v_variants) > 0
         and v_current.variants is distinct from v_variants then
        v_changed := true;
      end if;

      if not v_changed then
        v_unchanged_count := v_unchanged_count + 1;
        continue;
      end if;

      v_updated := public.update_store_product_v2(
        p_product_id => v_existing_id,
        p_edit_token => p_edit_token,
        p_name => v_name,
        p_description => v_description,
        p_price_text => v_price_text,
        p_price_amount => v_price_amount,
        p_image_urls => case
          when pg_catalog.jsonb_array_length(v_image_urls) > 0 then v_image_urls
          else null
        end,
        p_category_id => v_category_id,
        p_is_visible => case when v_has_is_visible then v_is_visible else null end,
        p_sort_order => case when v_has_sort_order then v_sort_order else null end,
        p_stock_quantity => v_stock_quantity,
        p_stock_status => v_stock_status,
        p_old_price_amount => v_old_price_amount,
        p_badge_tag => v_badge_tag,
        p_fulfillment_region => v_fulfillment_region,
        p_brand => v_brand,
        p_barcode => v_barcode,
        p_metadata => v_update_metadata,
        p_variants => case
          when pg_catalog.jsonb_array_length(v_variants) > 0 then v_variants
          else null
        end,
        p_clear_category => false,
        p_clear_price_amount => false,
        p_clear_stock_quantity => false,
        p_clear_stock_status => false,
        p_clear_old_price_amount => false,
        p_clear_badge_tag => false,
        p_clear_fulfillment_region => false,
        p_clear_brand => false,
        p_clear_barcode => false,
        p_clear_metadata => false,
        p_clear_variants => false
      );

      if not coalesce((v_updated->>'success')::boolean, false) then
        raise exception 'PRODUCT_UPDATE_FAILED';
      end if;

      v_updated_count := v_updated_count + 1;
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
    'inserted', v_inserted_count,
    'updated', v_updated_count,
    'unchanged', v_unchanged_count,
    'errors', v_error_count,
    'error_details', v_errors
  );
end;
$$;

alter function public.batch_create_products(uuid, text, jsonb) owner to postgres;
revoke execute on function public.batch_create_products(uuid, text, jsonb) from public;
grant execute on function public.batch_create_products(uuid, text, jsonb) to anon, authenticated, service_role;
