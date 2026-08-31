-- #277: Yalnız Hızlı Teknik kiralık demo vitrininin boş galerisini,
-- mevcut teknik servis şablonuyla aynı stok görsel deseniyle tamamlar.

-- Demo değişmezlik koruması yalnız bu atomik bakım migration'ı boyunca
-- kapatılır. Herhangi bir hata tüm transaction'ı, bu ALTER dahil, geri alır.
alter table public.stores disable trigger protect_landing_demo_stores;

do $$
declare
  v_gallery_items jsonb := '[
    {"id":"cover","title":"Atölyemizden bir kare — hassas komponent onarımı","imageUrl":"https://images.unsplash.com/photo-1512499617640-c74ae3a79d37?auto=format&fit=crop&w=800&q=80"},
    {"id":"gallery-0","title":"Orijinal parça stok alanımız","imageUrl":"https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?auto=format&fit=crop&w=800&q=80"},
    {"id":"gallery-1","title":"iPhone ekran değişimi anı","imageUrl":"https://images.unsplash.com/photo-1545259741-2ea3ebf61fa3?auto=format&fit=crop&w=800&q=80"},
    {"id":"gallery-2","title":"Laptop anakart tamiri, mikroskop altında","imageUrl":"https://images.unsplash.com/photo-1585771724684-38269d6639fd?auto=format&fit=crop&w=800&q=80"},
    {"id":"gallery-3","title":"Teslim öncesi son kalite kontrolü","imageUrl":"https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=800&q=85"}
  ]'::jsonb;
  v_preflight_count bigint;
  v_updated_count bigint;
begin
  -- Ön kontrol ile güncelleme arasına eşzamanlı yazma giremez.
  lock table public.stores in share row exclusive mode;

  select pg_catalog.count(*)
  into v_preflight_count
  from public.stores
  where slug = 'kiralik-teknik'
    and is_demo = true
    and is_published = true
    and pg_catalog.jsonb_typeof(gallery_items) = 'array'
    and pg_catalog.jsonb_array_length(gallery_items) = 0;

  if v_preflight_count <> 1 then
    raise exception
      'KIRALIK_TEKNIK_GALLERY_PREFLIGHT_FAILED: expected one published demo with empty gallery, found %',
      v_preflight_count;
  end if;

  update public.stores
  set gallery_items = v_gallery_items
  where slug = 'kiralik-teknik'
    and is_demo = true
    and is_published = true
    and pg_catalog.jsonb_array_length(gallery_items) = 0;

  get diagnostics v_updated_count = row_count;

  if v_updated_count <> 1 then
    raise exception
      'KIRALIK_TEKNIK_GALLERY_UPDATE_FAILED: expected one row, updated %',
      v_updated_count;
  end if;

  if not exists (
    select 1
    from public.stores
    where slug = 'kiralik-teknik'
      and gallery_items = v_gallery_items
      and pg_catalog.jsonb_array_length(gallery_items) = 5
  ) then
    raise exception 'KIRALIK_TEKNIK_GALLERY_POSTCHECK_FAILED';
  end if;
end;
$$;

-- Bakım tamamlandı; demo satırları yeniden değişmezdir.
alter table public.stores enable trigger protect_landing_demo_stores;
