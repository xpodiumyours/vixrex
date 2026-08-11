begin;

do $$
declare
  v_store_id uuid := gen_random_uuid();
  v_other_store_id uuid := gen_random_uuid();
  v_other_category_id uuid := gen_random_uuid();
  v_store_slug text := 'product-core-smoke-' || replace(gen_random_uuid()::text, '-', '');
  v_other_store_slug text := 'product-core-other-' || replace(gen_random_uuid()::text, '-', '');
  v_edit_token text := 'product-core-smoke-edit-token-1234567890';
  v_first jsonb;
  v_second jsonb;
  v_external_first jsonb;
  v_external_again jsonb;
  v_legacy_slug text;
  v_stable_slug text;
  v_rejected boolean := false;
  v_category_rejected boolean := false;
begin
  insert into public.stores (id, slug, name, edit_token)
  values
    (v_store_id, v_store_slug, 'Product CORE Smoke', v_edit_token),
    (v_other_store_id, v_other_store_slug, 'Other Store', v_edit_token);

  insert into public.product_categories (id, store_id, name, slug)
  values (v_other_category_id, v_other_store_id, 'Other Category', 'other-category');

  v_first := public.create_store_product_v2(
    v_store_id,
    v_edit_token,
    'Çanta & Aksesuar'
  );
  v_second := public.create_store_product_v2(
    v_store_id,
    v_edit_token,
    'Çanta & Aksesuar'
  );

  if v_first->>'slug' <> 'canta-aksesuar' then
    raise exception 'Turkce canonical slug uretilmedi: %', v_first;
  end if;
  if v_second->>'slug' <> 'canta-aksesuar-2' then
    raise exception 'Slug cakismasi sirali cozulmedi: %', v_second;
  end if;

  insert into public.products (store_id, name, slug)
  values (v_store_id, 'Legacy Ürün', 'Legacy-Çanta-123')
  returning slug into v_legacy_slug;

  if v_legacy_slug <> 'legacy-canta-123' then
    raise exception 'Legacy v1 slug korunmadi: %', v_legacy_slug;
  end if;

  perform public.update_store_product(
    p_product_id => (v_first->>'id')::uuid,
    p_edit_token => v_edit_token,
    p_name => 'Yeni Ürün Adı',
    p_slug => v_second->>'slug'
  );
  select p.slug
  into v_stable_slug
  from public.products as p
  where p.id = (v_first->>'id')::uuid;

  if v_stable_slug <> 'canta-aksesuar' then
    raise exception 'Update canonical URLyi degistirdi: %', v_stable_slug;
  end if;

  v_external_first := public.create_store_product_v2(
    p_store_id => v_store_id,
    p_edit_token => v_edit_token,
    p_name => 'Instagram Ürünü',
    p_source_type => 'instagram',
    p_external_product_id => 'product-core-media-1'
  );
  v_external_again := public.create_store_product_v2(
    p_store_id => v_store_id,
    p_edit_token => v_edit_token,
    p_name => 'Instagram Ürünü Tekrar',
    p_source_type => 'instagram',
    p_external_product_id => 'product-core-media-1'
  );

  if v_external_first->>'id' <> v_external_again->>'id'
     or (v_external_again->>'created')::boolean then
    raise exception 'External id idempotency bozuldu: %, %',
      v_external_first,
      v_external_again;
  end if;

  begin
    perform public.create_store_product_v2(
      v_store_id,
      'wrong-edit-token-12345678901234567890',
      'Yetkisiz Ürün'
    );
  exception
    when others then
      if sqlerrm like '%UNAUTHORIZED%' then
        v_rejected := true;
      else
        raise;
      end if;
  end;

  if not v_rejected then
    raise exception 'Yetkisiz create reddedilmedi';
  end if;

  begin
    perform public.create_store_product_v2(
      p_store_id => v_store_id,
      p_edit_token => v_edit_token,
      p_name => 'Yanlış Kategori',
      p_category_id => v_other_category_id
    );
  exception
    when others then
      if sqlerrm like '%CATEGORY_NOT_IN_SAME_STORE%' then
        v_category_rejected := true;
      else
        raise;
      end if;
  end;

  if not v_category_rejected then
    raise exception 'Baska magazanin kategorisi kabul edildi';
  end if;
end;
$$;

rollback;
