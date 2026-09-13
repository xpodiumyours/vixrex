-- Zengin ürün veri modeli — güvenli additive temel.
-- Canlıya doğrudan uygulanmak için değil; branch/preview doğrulamasından sonra migrate edilir.
--
-- 1) product_categories: kategori adına bakarak tahmin yapmak yerine açık bir
--    şablon anahtarı taşır. Mevcut kategoriler 'generic' kalır.
-- 2) products: yeni ürünlerde 3–10 fotoğraf zorunludur. Legacy ürünler sırf
--    başka alanları düzenleniyor diye bloklanmaz; görsel listesi değişirse yeni
--    kalite kuralına uyması gerekir.

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
begin
  if tg_op = 'UPDATE' and new.image_urls is not distinct from old.image_urls then
    return new;
  end if;

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

  return new;
end;
$$;

drop trigger if exists trg_products_image_count on public.products;
create trigger trg_products_image_count
before insert or update of image_urls on public.products
for each row
execute function public.enforce_product_image_count();
