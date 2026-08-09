do $$
declare
  v_store_id uuid;
begin
  select id into v_store_id from public.stores where slug = 'demo-teknofix';
  if v_store_id is null then raise exception 'demo-teknofix bulunamadi'; end if;

  if (select jsonb_array_length(gallery_items) from public.stores where id = v_store_id) <> 5 then
    raise exception 'galeri 5 oge icermiyor';
  end if;
  if (select nullif(trim(about_image_url), '') from public.stores where id = v_store_id) is null then
    raise exception 'hakkimizda gorseli bos';
  end if;
  if (select count(*) from public.product_categories where store_id = v_store_id and is_active) < 4 then
    raise exception 'dort aktif kategori yok';
  end if;
  if (select count(*) from public.products where store_id = v_store_id and is_active and is_visible) < 8 then
    raise exception 'sekiz gorunur hizmet yok';
  end if;
  if (select count(distinct image_urls->>0) from public.products where store_id = v_store_id) < 4 then
    raise exception 'urun gorselleri yeterince cesitli degil';
  end if;
  if (
    select count(distinct ilk_urun.image_url)
    from public.product_categories kategori
    cross join lateral (
      select urun.image_urls->>0 as image_url
      from public.products urun
      where urun.store_id = v_store_id
        and urun.category_id = kategori.id
        and urun.is_active
        and urun.is_visible
      order by urun.sort_order, urun.name
      limit 1
    ) ilk_urun
    where kategori.store_id = v_store_id and kategori.is_active
  ) < 4 then
    raise exception 'kategori kapak gorselleri birbirinden farkli degil';
  end if;
  if (select count(*) from public.store_articles where store_slug = 'demo-teknofix' and status = 'published') < 3 then
    raise exception 'uc yayindaki blog yazisi yok';
  end if;
end;
$$;
