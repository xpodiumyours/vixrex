alter table public.product_categories
  drop constraint if exists product_categories_template_key_check;

alter table public.product_categories
  add constraint product_categories_template_key_check
  check (
    product_template_key = any (
      array[
        'generic'::text,
        'fashion'::text,
        'electronics'::text,
        'beauty'::text,
        'food'::text,
        'cafe_restaurant'::text,
        'home'::text,
        'automotive'::text,
        'service'::text,
        'technical_service'::text
      ]
    )
  );
