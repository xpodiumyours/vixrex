begin;

with hedef(slug, sablon) as (
  values
    ('demo-aymira-giyim', 'fashion'),
    ('demo-lezzet-duragi', 'food'),
    ('demo-nova-kuafor', 'service'),
    ('demo-teknofix', 'service'),
    ('kiralik-butik', 'fashion'),
    ('kiralik-gida', 'food'),
    ('kiralik-kafe', 'food'),
    ('kiralik-kuafor', 'service'),
    ('kiralik-teknik', 'service')
)
update public.product_categories as pc
set product_template_key = case
      when hedef.slug in ('demo-teknofix', 'kiralik-teknik')
        and lower(pc.name) like '%aksesuar%'
        then 'electronics'
      else hedef.sablon
    end,
    updated_at = now()
from public.stores as s
join hedef on hedef.slug = s.slug
where pc.store_id = s.id
  and s.is_demo = true
  and pc.product_template_key is distinct from case
    when hedef.slug in ('demo-teknofix', 'kiralik-teknik')
      and lower(pc.name) like '%aksesuar%'
      then 'electronics'
    else hedef.sablon
  end;

with hedef(slug) as (
  values
    ('demo-aymira-giyim'),
    ('demo-lezzet-duragi'),
    ('demo-nova-kuafor'),
    ('demo-teknofix'),
    ('kiralik-butik'),
    ('kiralik-gida'),
    ('kiralik-kafe'),
    ('kiralik-kuafor'),
    ('kiralik-teknik')
),
kaynak as (
  select
    p.id,
    split_part(p.image_urls->>0, '?', 1) as temel_gorsel
  from public.products as p
  join public.stores as s on s.id = p.store_id
  join hedef on hedef.slug = s.slug
  where s.is_demo = true
    and jsonb_typeof(p.image_urls) = 'array'
    and jsonb_array_length(p.image_urls) between 1 and 2
    and nullif(btrim(p.image_urls->>0), '') is not null
)
update public.products as p
set image_urls = jsonb_build_array(
      kaynak.temel_gorsel || '?auto=format&fit=crop&w=1200&h=1500&q=82&crop=center',
      kaynak.temel_gorsel || '?auto=format&fit=crop&w=1200&h=1500&q=82&crop=faces',
      kaynak.temel_gorsel || '?auto=format&fit=crop&w=1200&h=1500&q=82&crop=entropy'
    ),
    updated_at = now()
from kaynak
where kaynak.id = p.id;

with hedef(slug) as (
  values
    ('demo-aymira-giyim'),
    ('demo-lezzet-duragi'),
    ('demo-nova-kuafor'),
    ('demo-teknofix'),
    ('kiralik-butik'),
    ('kiralik-gida'),
    ('kiralik-kafe'),
    ('kiralik-kuafor'),
    ('kiralik-teknik')
),
kaynak as (
  select
    p.id,
    regexp_replace(p.image_urls->>0, '\\?.*    ('demo-lezzet-duragi'),
    ('demo-nova-kuafor'),
    ('demo-teknofix'),
    ('kiralik-butik'),
    ('kiralik-gida'),
    ('kiralik-kafe'),
    ('kiralik-kuafor'),
    ('kiralik-teknik')
),
kaynak as (
  select
    p.id,
    coalesce(p.metadata, '{}'::jsonb) as metadata,
    pc.product_template_key,
    case
      when jsonb_typeof(coalesce(p.metadata, '{}'::jsonb)->'service') = 'object'
        then coalesce(p.metadata, '{}'::jsonb)->'service'
      else '{}'::jsonb
    end as mevcut_hizmet,
    case
      when p.price_amount is null and nullif(btrim(coalesce(p.price_text, '')), '') is null
        then 'ask'
      when lower(coalesce(p.price_text, '')) like '%den%'
        then 'starting_from'
      else 'fixed'
    end as fiyat_bicimi
  from public.products as p
  join public.product_categories as pc on pc.id = p.category_id
  join public.stores as s on s.id = p.store_id
  join hedef on hedef.slug = s.slug
  where s.is_demo = true
    and pc.product_template_key = 'service'
)
update public.products as p
set metadata =
      kaynak.metadata
      || jsonb_build_object(
        'schemaVersion', 2,
        'itemKind', 'service',
        'templateKey', kaynak.product_template_key,
        'service',
          jsonb_build_object(
            'serviceType', p.name,
            'priceMode', kaynak.fiyat_bicimi,
            'serviceLocation', 'business'
          ) || kaynak.mevcut_hizmet
      ),
    stock_quantity = null,
    stock_status = null,
    brand = null,
    barcode = null,
    variants = '[]'::jsonb,
    updated_at = now()
from kaynak
where kaynak.id = p.id;

with hedef(slug) as (
  values
    ('demo-aymira-giyim'),
    ('demo-lezzet-duragi'),
    ('demo-nova-kuafor'),
    ('demo-teknofix'),
    ('kiralik-butik'),
    ('kiralik-gida'),
    ('kiralik-kafe'),
    ('kiralik-kuafor'),
    ('kiralik-teknik')
),
kaynak as (
  select
    p.id,
    p.slug,
    coalesce(p.metadata, '{}'::jsonb) as metadata,
    pc.product_template_key,
    case
      when jsonb_typeof(coalesce(p.metadata, '{}'::jsonb)->'attributes') = 'array'
        then coalesce(p.metadata, '{}'::jsonb)->'attributes'
      else '[]'::jsonb
    end as mevcut_alanlar,
    lower(concat_ws(' ', p.name, p.description)) as arama_metni
  from public.products as p
  join public.product_categories as pc on pc.id = p.category_id
  join public.stores as s on s.id = p.store_id
  join hedef on hedef.slug = s.slug
  where s.is_demo = true
    and pc.product_template_key <> 'service'
),
zengin as (
  select
    kaynak.*,
    case kaynak.slug
      when 'haftalık-sebze-sepeti' then '3 kg'
      when 'organik-domates' then '1 kg'
      when 'koy-peyniri' then '500 gr'
      when 'yoresel-zeytin-karma' then '500 gr'
      when 'cilek-receli' then '400 gr'
      else null
    end as net_miktar,
    case
      when kaynak.arama_metni like '%keten%' then 'Keten'
      when kaynak.arama_metni like '%pamuk%' then 'Pamuk'
      when kaynak.arama_metni like '%kaşmir%' or kaynak.arama_metni like '%kasmir%' then 'Kaşmir'
      when kaynak.arama_metni like '%ipek%' then 'İpek'
      when kaynak.arama_metni like '%deri%' then 'Deri'
      else null
    end as materyal
  from kaynak
),
alanlar as (
  select
    zengin.*,
    zengin.mevcut_alanlar
    || case
      when exists (
        select 1
        from jsonb_array_elements(zengin.mevcut_alanlar) as alan
        where alan->>'key' = 'condition'
      ) then '[]'::jsonb
      else jsonb_build_array(jsonb_build_object('key', 'condition', 'value', 'new'))
    end
    || case
      when zengin.net_miktar is null or exists (
        select 1
        from jsonb_array_elements(zengin.mevcut_alanlar) as alan
        where alan->>'key' = 'netQuantity'
      ) then '[]'::jsonb
      else jsonb_build_array(jsonb_build_object('key', 'netQuantity', 'value', zengin.net_miktar))
    end
    || case
      when zengin.materyal is null or exists (
        select 1
        from jsonb_array_elements(zengin.mevcut_alanlar) as alan
        where alan->>'key' = 'material'
      ) then '[]'::jsonb
      else jsonb_build_array(jsonb_build_object('key', 'material', 'value', zengin.materyal))
    end as guncel_alanlar
  from zengin
)
update public.products as p
set metadata =
      alanlar.metadata
      || jsonb_build_object(
        'schemaVersion', 2,
        'itemKind', 'physical',
        'templateKey', alanlar.product_template_key,
        'attributes', alanlar.guncel_alanlar
      ),
    stock_status = coalesce(nullif(btrim(p.stock_status), ''), 'Stokta'),
    updated_at = now()
from alanlar
where alanlar.id = p.id;

do $$
declare
  v_hedef_slugs text[] := array[
    'demo-aymira-giyim',
    'demo-lezzet-duragi',
    'demo-nova-kuafor',
    'demo-teknofix',
    'kiralik-butik',
    'kiralik-gida',
    'kiralik-kafe',
    'kiralik-kuafor',
    'kiralik-teknik'
  ];
begin
  if exists (
    select 1
    from public.products as p
    join public.stores as s on s.id = p.store_id
    left join public.product_categories as pc
      on pc.id = p.category_id
      and pc.store_id = p.store_id
    where s.slug = any (v_hedef_slugs)
      and s.is_demo = true
      and pc.id is null
  ) then
    raise exception 'KIRALIK_PRODUCT_CATEGORY_REQUIRED';
  end if;

  if exists (
    select 1
    from public.products as p
    join public.stores as s on s.id = p.store_id
    where s.slug = any (v_hedef_slugs)
      and s.is_demo = true
      and case
        when jsonb_typeof(p.image_urls) = 'array'
          then jsonb_array_length(p.image_urls) < 3
        else true
      end
  ) then
    raise exception 'KIRALIK_PRODUCT_IMAGES_REQUIRED';
  end if;

  if exists (
    select 1
    from public.products as p
    join public.stores as s on s.id = p.store_id
    join public.product_categories as pc on pc.id = p.category_id
    where s.slug = any (v_hedef_slugs)
      and s.is_demo = true
      and (
        p.metadata->>'schemaVersion' <> '2'
        or p.metadata->>'templateKey' is distinct from pc.product_template_key
        or p.metadata->>'itemKind' is null
      )
  ) then
    raise exception 'KIRALIK_PRODUCT_METADATA_REQUIRED';
  end if;
end;
$$;

create or replace function public.clone_demo_store_as_draft(
  p_source_slug text,
  p_new_slug text,
  p_edit_token text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_source_id uuid;
  v_new_id uuid;
begin
  if p_new_slug is null or pg_catalog.length(pg_catalog.btrim(p_new_slug)) = 0 then
    raise exception 'INVALID_SLUG';
  end if;
  if p_edit_token is null or pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 then
    raise exception 'INVALID_EDIT_TOKEN';
  end if;

  select id into v_source_id
  from public.stores
  where slug = pg_catalog.btrim(p_source_slug)
    and is_demo = true;

  if v_source_id is null then
    raise exception 'SOURCE_NOT_FOUND';
  end if;

  insert into public.stores (
    slug, edit_token, user_id, cloned_from_slug,
    name, business_type, description, corporate_bio,
    whatsapp, phone, email, hero_badge, instagram, website, address,
    theme, theme_preset, status,
    marketplace_links, gallery_items, products, product_categories, offerings,
    catalog_link, references_link, vcard_link, shelf_image_url, logo_url,
    working_hours, is_published, is_store, kategori,
    latitude, longitude, location_accuracy_meters, location_source,
    province_code, province_name, district_code, district_name,
    google_business_link,
    featured_banner_label, featured_banner_title, featured_banner_description,
    featured_banner_image_url, featured_banner_price_text,
    faq_items, about_kicker, about_title, about_image_url, about_image_caption,
    about_values, gallery_section_kicker, gallery_section_title,
    show_storefront_rating, show_directions_link,
    edit_token_expires_at
  )
  select
    pg_catalog.btrim(p_new_slug), pg_catalog.btrim(p_edit_token), null,
    pg_catalog.btrim(p_source_slug),
    '', business_type, description, corporate_bio,
    '', null, null, hero_badge, instagram, website, '',
    theme, theme_preset, 'draft',
    marketplace_links, gallery_items, products, product_categories, offerings,
    catalog_link, references_link, vcard_link, shelf_image_url, null,
    null, false, is_store, kategori,
    null, null, null, null,
    null, null, null, null,
    null,
    null, null, null, null, null,
    faq_items, about_kicker, about_title, about_image_url, about_image_caption,
    about_values, gallery_section_kicker, gallery_section_title,
    show_storefront_rating, show_directions_link,
    now() + interval '14 days'
  from public.stores
  where id = v_source_id
  returning id into v_new_id;

  drop table if exists _kategori_esleme;
  create temporary table _kategori_esleme (
    eski_id uuid primary key,
    yeni_id uuid not null
  ) on commit drop;

  insert into _kategori_esleme (eski_id, yeni_id)
  select id, gen_random_uuid()
  from public.product_categories
  where store_id = v_source_id;

  insert into public.product_categories (
    id, store_id, name, slug, sort_order, is_active, product_template_key
  )
  select
    e.yeni_id,
    v_new_id,
    k.name,
    k.slug,
    k.sort_order,
    k.is_active,
    k.product_template_key
  from public.product_categories as k
  join _kategori_esleme as e on e.eski_id = k.id
  where k.store_id = v_source_id;

  insert into public.products (
    id, store_id, category_id, source_type, external_product_id,
    name, slug, description, price_amount, price_text, currency,
    stock_quantity, stock_status, image_urls, metadata,
    seo_title, seo_description, is_visible, is_active, sort_order,
    brand, barcode, vat_rate, variants, old_price_amount, badge_tag,
    fulfillment_region
  )
  select
    gen_random_uuid(), v_new_id, e.yeni_id, p.source_type,
    p.external_product_id,
    p.name, p.slug, p.description, p.price_amount, p.price_text, p.currency,
    p.stock_quantity, p.stock_status, p.image_urls, p.metadata,
    p.seo_title, p.seo_description, p.is_visible, p.is_active, p.sort_order,
    p.brand, p.barcode, p.vat_rate, p.variants, p.old_price_amount,
    p.badge_tag, p.fulfillment_region
  from public.products as p
  left join _kategori_esleme as e on e.eski_id = p.category_id
  where p.store_id = v_source_id;
end;
$$;

commit;

notify pgrst, 'reload schema';
