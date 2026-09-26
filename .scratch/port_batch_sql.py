from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
t = subprocess.check_output(['git', 'show', 'work/product-live-ready-20260914:supabase/migrations/20260914103000_batch_product_price_consistency.sql'], cwd=root).decode('utf-8')
t = '\n'.join(line for line in t.splitlines() if not line.lstrip().startswith('--')) + '\n'
t = t.replace('  v_category_result jsonb;', '  v_category_slug text;\n  v_variants jsonb;')
t = t.replace("    begin\n      v_name", "    begin\n      if pg_catalog.jsonb_typeof(v_product) is distinct from 'object' then\n        raise exception 'PRODUCT_INVALID';\n      end if;\n      v_name")
t = t.replace("      if pg_catalog.jsonb_typeof(v_image_urls) <> 'array' then", "      if pg_catalog.jsonb_typeof(v_image_urls) is distinct from 'array' then")
t = t.replace("      if pg_catalog.btrim(v_price_text) <> '' then", """      if pg_catalog.jsonb_array_length(v_image_urls) > 11 or exists (
        select 1 from pg_catalog.jsonb_array_elements(v_image_urls) as image(value)
        where pg_catalog.jsonb_typeof(image.value) <> 'string'
          or pg_catalog.btrim(image.value #>> '{}') !~* '^https?://[^[:space:]/?#]+[^[:space:]]*$'
      ) then
        raise exception 'PRODUCT_IMAGES_INVALID';
      end if;

      if pg_catalog.btrim(v_price_text) <> '' then""")
start = t.index('          v_category_result :=')
end = t.index('\n        end if;', start)
t = t[:start] + """          v_category_slug := public.slugify_tr(v_category_name);
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
          returning id, product_template_key into v_category_id, v_template_key;""" + t[end:]
start = t.index('      v_metadata :=')
end = t.index('\n      v_result :=', start)
t = t[:start] + """      v_metadata := coalesce(v_product->'metadata', '{}'::jsonb);
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
""" + t[end:]
for field in ['brand', 'barcode', 'stock_quantity', 'stock_status']:
    t = t.replace("case when v_item_kind = 'service' then null else v_" + field + ' end', 'v_' + field)
t = t.replace("p_variants => '[]'::jsonb", 'p_variants => v_variants')
t = t.replace("        v_success_count := v_success_count + 1;", "        if coalesce((v_result->>'created')::boolean, true) then\n          v_success_count := v_success_count + 1;\n        else\n          raise exception 'PRODUCT_ALREADY_EXISTS';\n        end if;")
(root / 'supabase/migrations/20260915020000_product_batch_rich_fields.sql').write_text(t.lstrip(), encoding='utf-8')
