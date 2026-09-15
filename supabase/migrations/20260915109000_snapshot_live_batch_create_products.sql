-- CANLI MEVCUT DURUM SNAPSHOT'U — 2026-09-15
--
-- Bu migration hedef davranış değildir. Vixrex production Supabase'te bu
-- çalışmadan önce fiilen çalışan batch_create_products(uuid,text,jsonb)
-- fonksiyonunun geri dönüş kaynağıdır.
--
-- Sonraki migration bu fonksiyonu zengin Product CORE davranışıyla
-- CREATE OR REPLACE edecektir. Bu dosya özellikle eski canlı davranışın
-- repoda kaybolmaması için tutulur.

create or replace function public.batch_create_products(
  p_store_id uuid,
  p_edit_token text,
  p_products jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to 'pg_catalog', 'public', 'auth'
as $function$
DECLARE
  v_product JSONB;
  v_new_id UUID;
  v_success_count INT := 0;
  v_error_count INT := 0;
  v_errors JSONB := '[]'::JSONB;
  v_index INT := 0;
BEGIN
  IF NOT public._check_store_authorization(p_store_id, p_edit_token) THEN
    RAISE EXCEPTION 'UNAUTHORIZED';
  END IF;
  FOR v_product IN SELECT * FROM jsonb_array_elements(p_products)
  LOOP
    v_index := v_index + 1;

    BEGIN
      DECLARE
        v_name TEXT := COALESCE(v_product->>'name', '');
        v_slug TEXT := COALESCE(v_product->>'slug', '');
        v_description TEXT := COALESCE(v_product->>'description', '');
        v_price_text TEXT := COALESCE(v_product->>'price_text', '');
        v_price_amount NUMERIC := NULL;
        v_image_urls JSONB := COALESCE(v_product->'image_urls', '[]'::jsonb);
        v_category_id UUID := NULL;
        v_source_type TEXT := COALESCE(v_product->>'source_type', 'xml_import');
        v_external_product_id TEXT := v_product->>'external_product_id';
        v_is_visible BOOLEAN := COALESCE((v_product->>'isVisible')::boolean, true);
        v_sort_order INT := COALESCE((v_product->>'sort_order')::int, 0);
      BEGIN
        IF length(trim(v_name)) = 0 THEN
          v_error_count := v_error_count + 1;
          v_errors := v_errors || jsonb_build_object('index', v_index, 'error', 'EMPTY_NAME');
          CONTINUE;
        END IF;
        IF length(trim(v_slug)) = 0 THEN
          v_slug := lower(regexp_replace(regexp_replace(v_name, '[^a-zA-Z0-9\s-]', '', 'g'), '\s+', '-', 'g'));
          IF EXISTS (SELECT 1 FROM public.products WHERE store_id = p_store_id AND slug = v_slug) THEN
            v_slug := v_slug || '-' || substr(md5(random()::text), 1, 6);
          END IF;
        END IF;
        IF v_price_amount IS NULL AND length(v_price_text) > 0 THEN
          v_price_amount := NULLIF(regexp_replace(regexp_replace(v_price_text, '[^0-9.,]', '', 'g'), ',', '.', 'g'), '')::numeric;
        END IF;
        IF v_product->>'category_id' IS NOT NULL THEN
          IF EXISTS (
            SELECT 1
            FROM public.product_categories pc
            WHERE pc.id = (v_product->>'category_id')::uuid
              AND pc.store_id = p_store_id
          ) THEN
            v_category_id := (v_product->>'category_id')::uuid;
          END IF;
        END IF;
        INSERT INTO public.products (
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
          sort_order
        )
        VALUES (
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
          v_sort_order
        );
        v_success_count := v_success_count + 1;
      EXCEPTION WHEN OTHERS THEN
        v_error_count := v_error_count + 1;
        v_errors := v_errors || jsonb_build_object('index', v_index, 'error', SQLERRM);
      END;
    END;
  END LOOP;
  RETURN jsonb_build_object(
    'success', true,
    'total', v_index,
    'inserted', v_success_count,
    'errors', v_error_count,
    'error_details', v_errors
  );
END;
$function$;

alter function public.batch_create_products(uuid, text, jsonb) owner to postgres;

grant execute on function public.batch_create_products(uuid, text, jsonb) to public;
grant execute on function public.batch_create_products(uuid, text, jsonb) to anon;
grant execute on function public.batch_create_products(uuid, text, jsonb) to authenticated;
grant execute on function public.batch_create_products(uuid, text, jsonb) to service_role;
