begin;

create or replace function public.ek_urun_katla(p_metin text)
returns text
language sql
immutable
as $$
  select btrim(
    regexp_replace(
      translate(
        lower(
          replace(replace(replace(coalesce(p_metin, ''), 'İ', 'i'), 'I', 'i'), 'ı', 'i')
        ),
        'çğıöşüâîû',
        'cgiosuaiu'
      ),
      '[^a-z0-9]+',
      ' ',
      'g'
    )
  );
$$;

create or replace function public.ek_urun_miktari(p_ad text, p_meta jsonb)
returns text
language plpgsql
immutable
as $$
declare
  v_kaynak text;
  v_parca text[];
  v_deger numeric;
  v_birim text;
  v_kalip text := '([0-9]+([.,][0-9]+)?)\s*(litre|gram|adet|kg|gr|g|ml|cl|lt|l)\M';
begin
  v_parca := regexp_match(public.ek_urun_katla(p_ad), v_kalip);
  if v_parca is null and p_meta is not null then
    select a ->> 'value'
      into v_kaynak
      from jsonb_array_elements(coalesce(p_meta -> 'attributes', '[]'::jsonb)) a
     where lower(coalesce(a ->> 'key', '')) = 'netquantity'
     limit 1;
    v_parca := regexp_match(public.ek_urun_katla(v_kaynak), v_kalip);
  end if;
  if v_parca is null then
    return '';
  end if;
  v_deger := replace(v_parca[1], ',', '.')::numeric;
  v_birim := v_parca[3];
  if v_deger is null or v_deger <= 0 then
    return '';
  end if;
  if v_birim = 'kg' then
    return round(v_deger * 1000)::text || ' g';
  end if;
  if v_birim in ('g', 'gr', 'gram') then
    return round(v_deger)::text || ' g';
  end if;
  if v_birim = 'ml' then
    return round(v_deger)::text || ' ml';
  end if;
  if v_birim = 'cl' then
    return round(v_deger * 10)::text || ' ml';
  end if;
  if v_birim in ('l', 'lt', 'litre') then
    return round(v_deger * 1000)::text || ' ml';
  end if;
  return round(v_deger)::text || ' adet';
end;
$$;

create or replace function public.ek_urun_birlestir(p_hedef uuid, p_kaynak uuid)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  h public.products%rowtype;
  k public.products%rowtype;
  v_toplam integer;
  v_gorseller jsonb;
  v_varyantlar jsonb;
  v_meta jsonb;
  v_ozellikler jsonb;
begin
  if p_hedef = p_kaynak then
    return;
  end if;

  select * into h from public.products where id = p_hedef for update;
  select * into k from public.products where id = p_kaynak for update;

  if h.id is null or k.id is null or h.store_id <> k.store_id then
    return;
  end if;
  if not k.is_active then
    return;
  end if;
  if btrim(coalesce(h.barcode, '')) <> ''
     and btrim(coalesce(k.barcode, '')) <> ''
     and btrim(h.barcode) <> btrim(k.barcode) then
    raise exception 'FARKLI_BARKOD: % ile % ayni karta birlesemez', btrim(h.barcode), btrim(k.barcode);
  end if;

  if h.stock_quantity is null and k.stock_quantity is null then
    v_toplam := null;
  else
    v_toplam := coalesce(h.stock_quantity, 0) + coalesce(k.stock_quantity, 0);
  end if;

  select coalesce(jsonb_agg(deger order by sira), '[]'::jsonb)
    into v_gorseller
    from (
      select deger, sira
        from (
          select distinct on (deger) deger, sira
            from (
              select t.deger, t.ord as sira
                from jsonb_array_elements_text(coalesce(h.image_urls, '[]'::jsonb)) with ordinality t(deger, ord)
              union all
              select t.deger, 100 + t.ord
                from jsonb_array_elements_text(coalesce(k.image_urls, '[]'::jsonb)) with ordinality t(deger, ord)
            ) s
           order by deger, sira
        ) tek
       order by sira
       limit 11
    ) kapali;

  select coalesce(jsonb_agg(v), '[]'::jsonb)
    into v_varyantlar
    from (
      select value as v from jsonb_array_elements(coalesce(h.variants, '[]'::jsonb))
      union
      select value as v from jsonb_array_elements(coalesce(k.variants, '[]'::jsonb))
    ) birlesik
   where v <> 'null'::jsonb;

  select coalesce(jsonb_agg(a), '[]'::jsonb)
    into v_ozellikler
    from (
      select a
        from jsonb_array_elements(coalesce(h.metadata -> 'attributes', '[]'::jsonb)) a
      union all
      select a
        from jsonb_array_elements(coalesce(k.metadata -> 'attributes', '[]'::jsonb)) a
       where not exists (
         select 1
           from jsonb_array_elements(coalesce(h.metadata -> 'attributes', '[]'::jsonb)) b
          where b ->> 'key' = a ->> 'key'
       )
    ) ozellik;

  v_meta := jsonb_set(coalesce(h.metadata, '{}'::jsonb), '{attributes}', v_ozellikler, true);
  v_meta := jsonb_set(
    v_meta,
    '{birlestirilen_urunler}',
    coalesce(v_meta -> 'birlestirilen_urunler', '[]'::jsonb)
      || jsonb_build_object(
           'id', k.id,
           'slug', k.slug,
           'ad', k.name,
           'barkod', nullif(btrim(coalesce(k.barcode, '')), ''),
           'stok', k.stock_quantity,
           'zaman', now()
         ),
    true
  );

  update public.products
     set stock_quantity = v_toplam,
         stock_status = case
                          when v_toplam is null then h.stock_status
                          when v_toplam > 0 then coalesce(nullif(btrim(coalesce(h.stock_status, '')), ''), 'Mevcut')
                          else h.stock_status
                        end,
         image_urls = v_gorseller,
         variants = v_varyantlar,
         metadata = v_meta,
         barcode = coalesce(nullif(btrim(coalesce(h.barcode, '')), ''), nullif(btrim(coalesce(k.barcode, '')), '')),
         category_id = coalesce(h.category_id, k.category_id),
         sort_order = least(h.sort_order, k.sort_order),
         updated_at = now()
   where id = h.id;

  update public.products
     set is_visible = false,
         is_active = false,
         stock_quantity = 0,
         metadata = jsonb_set(
           coalesce(metadata, '{}'::jsonb),
           '{birlestirildi}',
           jsonb_build_object('hedef_id', h.id, 'hedef_slug', h.slug, 'zaman', now()),
           true
         ),
         updated_at = now()
   where id = k.id;

  if to_regclass('public.invoice_job_lines') is not null then
    update public.invoice_job_lines
       set product_id = h.id
     where product_id = k.id;
  end if;

  if to_regclass('public.product_purchase_prices') is not null then
    update public.product_purchase_prices pp
       set product_id = h.id,
           updated_at = now()
     where pp.product_id = k.id
       and not exists (select 1 from public.product_purchase_prices q where q.product_id = h.id);
  end if;
end;
$$;

create or replace function public.tekrar_urunleri_birlestir(p_store_id uuid, p_uygula boolean default false)
returns table (
  asama text,
  anahtar text,
  tutulan text,
  birlestirilen text,
  onceki_stok integer,
  yeni_stok integer
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_grup record;
  v_satir record;
  v_hedef uuid;
  v_hedef_slug text;
  v_kaynak_etiketi text;
  v_eski integer;
  v_yeni integer;
  v_i integer;
begin
  if p_store_id is null then
    return;
  end if;

  for v_grup in
    select btrim(p.barcode) as bc, array_agg(p.id order by p.created_at, p.id) as idler
      from public.products p
     where p.store_id = p_store_id
       and p.is_active
       and btrim(coalesce(p.barcode, '')) <> ''
     group by btrim(p.barcode)
    having count(*) > 1
  loop
    v_hedef := v_grup.idler[1];
    select slug, stock_quantity into v_hedef_slug, v_eski from public.products where id = v_hedef;
    for v_i in 2 .. array_length(v_grup.idler, 1) loop
      select slug || ' (stok ' || coalesce(stock_quantity::text, 'yok') || ')'
        into v_kaynak_etiketi
        from public.products where id = v_grup.idler[v_i];
      if p_uygula then
        perform public.ek_urun_birlestir(v_hedef, v_grup.idler[v_i]);
      end if;
      select stock_quantity into v_yeni from public.products where id = v_hedef;
      asama := 'barkod';
      anahtar := v_grup.bc;
      tutulan := v_hedef_slug;
      birlestirilen := v_kaynak_etiketi;
      onceki_stok := v_eski;
      yeni_stok := v_yeni;
      return next;
      v_eski := v_yeni;
    end loop;
  end loop;

  for v_satir in
    select p.*
      from public.products p
     where p.store_id = p_store_id
       and p.is_active
       and btrim(coalesce(p.barcode, '')) = ''
       and public.ek_urun_miktari(p.name, p.metadata) <> ''
       and exists (
         select 1
           from public.products h
          where h.store_id = p.store_id
            and h.is_active
            and h.id <> p.id
            and btrim(coalesce(h.barcode, '')) <> ''
            and public.ek_urun_katla(h.name) = public.ek_urun_katla(p.name)
            and public.ek_urun_katla(h.brand) = public.ek_urun_katla(p.brand)
            and public.ek_urun_miktari(h.name, h.metadata) = public.ek_urun_miktari(p.name, p.metadata)
       )
  loop
    select h.id into v_hedef
      from public.products h
     where h.store_id = v_satir.store_id
       and h.is_active
       and h.id <> v_satir.id
       and btrim(coalesce(h.barcode, '')) <> ''
       and public.ek_urun_katla(h.name) = public.ek_urun_katla(v_satir.name)
       and public.ek_urun_katla(h.brand) = public.ek_urun_katla(v_satir.brand)
       and public.ek_urun_miktari(h.name, h.metadata) = public.ek_urun_miktari(v_satir.name, v_satir.metadata)
     order by h.created_at, h.id
     limit 1;

    select slug, stock_quantity into v_hedef_slug, v_eski from public.products where id = v_hedef;
    if p_uygula then
      perform public.ek_urun_birlestir(v_hedef, v_satir.id);
    end if;
    select stock_quantity into v_yeni from public.products where id = v_hedef;

    asama := 'barkodsuz';
    anahtar := public.ek_urun_katla(v_satir.name) || ' | ' || public.ek_urun_miktari(v_satir.name, v_satir.metadata);
    tutulan := v_hedef_slug;
    birlestirilen := v_satir.slug || ' (stok ' || coalesce(v_satir.stock_quantity::text, 'yok') || ')';
    onceki_stok := v_eski;
    yeni_stok := v_yeni;
    return next;
  end loop;
end;
$$;

revoke all on function public.ek_urun_katla(text) from public;
revoke all on function public.ek_urun_miktari(text, jsonb) from public;
revoke all on function public.ek_urun_birlestir(uuid, uuid) from public;
revoke all on function public.tekrar_urunleri_birlestir(uuid, boolean) from public;
revoke all on function public.ek_urun_birlestir(uuid, uuid) from anon, authenticated;
revoke all on function public.tekrar_urunleri_birlestir(uuid, boolean) from anon, authenticated;

select *
  from public.tekrar_urunleri_birlestir(
    (select id from public.stores where slug = 'elif-market-test-3-mvqfxnwm'),
    true
  );

commit;
