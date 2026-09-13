-- Zengin ürün veri modeli — güvenli additive temel.
-- Canlıya doğrudan uygulanmak için değil; branch/preview doğrulamasından sonra migrate edilir.
--
-- 1) product_categories: kategori adına bakarak tahmin yapmak yerine açık bir
--    şablon anahtarı taşır. Mevcut kategoriler 'generic' kalır.
-- 2) products: yeni ürünlerde 3–10 fotoğraf zorunludur. Legacy ürünler sırf
--    başka alanları düzenleniyor diye bloklanmaz; görsel listesi değişirse yeni
--    kalite kuralına uyması gerekir.
-- 3) varyant görselleri ikinci bir medya kaynağı oluşturmaz; yalnız ürünün kendi
--    image_urls galerisindeki fotoğraflara bağlanabilir.

alter table public.product_categories
  add column if not exists product_template_key text not null default 'generic';

comment on column public.product_categories.product_template_key is
  'shared/product_attribute_schema.json içindeki ürün tipi şablon anahtarı; isimden tahmin edilmez.';

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
    if image_count > 10 then
      raise exception 'PRODUCT_IMAGES_MAX_10';
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

drop trigger if exists trg_products_image_count on public.products;
create trigger trg_products_image_count
before insert or update of image_urls, variants on public.products
for each row
execute function public.enforce_product_image_count();
