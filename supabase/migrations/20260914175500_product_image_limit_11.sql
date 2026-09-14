-- Ürün görsel üst sınırını Web/Flutter sözleşmesiyle 11'e eşitler.
-- Eski migration değiştirilmez; mevcut trigger fonksiyonu additive olarak güncellenir.

create or replace function public.enforce_product_image_count()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  image_count integer;
  clean_variants jsonb := '[]'::jsonb;
  variant_item jsonb;
  clean_variant_images jsonb;
  variant_image jsonb;
begin
  if tg_op = 'INSERT' or new.image_urls is distinct from old.image_urls then
    if jsonb_typeof(new.image_urls) <> 'array' then
      raise exception 'PRODUCT_IMAGES_INVALID';
    end if;

    image_count := jsonb_array_length(new.image_urls);
    if image_count < 3 then
      raise exception 'PRODUCT_IMAGES_MIN_3';
    end if;
    if image_count > 11 then
      raise exception 'PRODUCT_IMAGES_MAX_11';
    end if;
  end if;

  if jsonb_typeof(coalesce(new.variants, '[]'::jsonb)) = 'array' then
    for variant_item in
      select value
      from jsonb_array_elements(coalesce(new.variants, '[]'::jsonb))
    loop
      if jsonb_typeof(variant_item) = 'object'
         and jsonb_typeof(variant_item->'imageUrls') = 'array' then
        clean_variant_images := '[]'::jsonb;
        for variant_image in
          select value
          from jsonb_array_elements(variant_item->'imageUrls')
        loop
          if exists (
            select 1
            from jsonb_array_elements(coalesce(new.image_urls, '[]'::jsonb)) as gallery(value)
            where gallery.value = variant_image
          ) and not clean_variant_images @> jsonb_build_array(variant_image) then
            clean_variant_images := clean_variant_images || jsonb_build_array(variant_image);
          end if;
        end loop;
        variant_item := jsonb_set(
          variant_item,
          '{imageUrls}',
          clean_variant_images,
          true
        );
      end if;
      clean_variants := clean_variants || jsonb_build_array(variant_item);
    end loop;
    new.variants := clean_variants;
  end if;

  return new;
end;
$$;
