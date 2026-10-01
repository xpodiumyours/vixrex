-- Vixrex fatura yayın kapısı — veritabanı son kapı (P6).
--
-- Kural: source_type='invoice' olan satır, YALNIZCA publish_invoice_product
-- RPC'si üzerinden görünür olur. Eski uygulama sürümü, doğrudan toplu istek,
-- is_visible=true gönderen eski RPC veya telefonun toplu görünürlük düğmesi
-- bu kapıyı atlayamaz.
--
-- Tasarım notları:
-- - Mevcut görünür satırlar bu migration ile TOPLUCA değiştirilmez; tetik
--   yalnız gelecekteki INSERT/UPDATE'lere bakar.
-- - Sıradan düzenleme (PATCH) görünürlüğü değiştirmez: görünür fatura ürünü
--   görünür kalır, taslak fatura ürünü taslak kalır.
-- - Yayın şartı (fiyat, fotoğraf, stok, kanıt durumu, stok onayı) publish
--   RPC'sinde yeniden okunur; arayüz düğmesine güvenilmez.
-- - Fatura kanıt özeti (kartDurumu + stokOnaylandi) products.fatura_kanit
--   kolonunda tutulur; sunucu her yazımda günceller.
--
-- ROLLBACK SQL (yalnız acil durum; önce istemciler eski davranışa alınır):
-- drop trigger fatura_yayin_kilidi on public.products;
-- drop function public.fatura_yayin_kilidi();
-- drop function public.publish_invoice_product(uuid, text);

alter table public.products
  add column if not exists fatura_kanit jsonb;

comment on column public.products.fatura_kanit is
  'Yalniz source_type=invoice satirlarda yazilir: {"kartDurumu":"kanitli|eksik|celiski|iz-yok","stokOnaylandi":true|false}. Yayin kapisi buradan okur; musteriye gosterilmez.';

create or replace function public.fatura_yayin_kilidi()
returns trigger
language plpgsql
as $$
begin
  if new.source_type is distinct from 'invoice' then
    return new;
  end if;

  -- Yeni fatura satırı görünür doğamaz; önce taslak kurulur, sonra
  -- publish_invoice_product ile kapılar yeniden okunarak açılır.
  if tg_op = 'INSERT' then
    new.is_visible := false;
    return new;
  end if;

  -- Taslaktaki fatura ürünü, publish RPC'si dışındaki hiçbir yolla
  -- görünür yapılamaz (doğrudan UPDATE, eski RPC, toplu görünürlük).
  if tg_op = 'UPDATE'
    and coalesce(old.is_visible, false) = false
    and coalesce(new.is_visible, false) = true
    and current_setting('vixrex.fatura_yayin_serbest', true) is distinct from 'acik'
  then
    raise exception 'FATURA_YAYIN_KAPISI: fatura taslagi yalniz Yayınla ile acilir'
      using errcode = 'P0001';
  end if;

  return new;
end;
$$;

drop trigger if exists fatura_yayin_kilidi on public.products;
create trigger fatura_yayin_kilidi
  before insert or update on public.products
  for each row execute function public.fatura_yayin_kilidi();

-- Ayrı Yayınla eylemi. Sahiplik (edit_token), güncel fiyat, fotoğraf sayısı,
-- stok ve fatura kanıt durumu tek seferde doğrulanır. Herhangi bir kapı
-- kapalıysa ürün görünmez, somut eksik hata metninde döner.
create or replace function public.publish_invoice_product(
  p_product_id uuid,
  p_edit_token text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_store_id uuid;
  v_source text;
  v_visible boolean;
  v_price numeric;
  v_images jsonb;
  v_stock integer;
  v_kanit jsonb;
  v_kart_durumu text;
  v_stok_onay boolean;
begin
  select id into v_store_id
  from public.stores
  where edit_token = p_edit_token
  limit 1;

  if v_store_id is null then
    return jsonb_build_object('success', false, 'hata', 'Vitrin bulunamadı.');
  end if;

  select source_type, is_visible, price_amount, image_urls, stock_quantity, fatura_kanit
    into v_source, v_visible, v_price, v_images, v_stock, v_kanit
  from public.products
  where id = p_product_id
    and store_id = v_store_id;

  if not found then
    return jsonb_build_object('success', false, 'hata', 'Ürün bulunamadı.');
  end if;

  if v_source is distinct from 'invoice' then
    return jsonb_build_object('success', false, 'hata', 'Bu ürün fatura akışından gelmedi.');
  end if;

  if coalesce(v_visible, false) = true then
    return jsonb_build_object('success', true, 'id', p_product_id, 'zaten_yayinda', true);
  end if;

  if v_price is null or v_price <= 0 then
    return jsonb_build_object('success', false, 'hata', 'Satış fiyatı girilmedi.');
  end if;

  if v_images is null or jsonb_typeof(v_images) <> 'array' or jsonb_array_length(v_images) < 1 then
    return jsonb_build_object('success', false, 'hata', 'En az 1 doğrulanmış ürün fotoğrafı gerekiyor.');
  end if;

  if v_stock is null then
    return jsonb_build_object('success', false, 'hata', 'Stok onaylanmadı; faturadaki adet öneridir.');
  end if;

  v_kart_durumu := coalesce(v_kanit ->> 'kartDurumu', 'eksik');
  v_stok_onay := coalesce((v_kanit ->> 'stokOnaylandi')::boolean, false);

  if v_kart_durumu is distinct from 'kanitli' then
    return jsonb_build_object('success', false, 'hata', 'Satır kanıtlı değil; bu satırdan kart yayına çıkmaz.');
  end if;

  if v_stok_onay is not true then
    return jsonb_build_object('success', false, 'hata', 'Stok onaylanmadı; faturadaki adet öneridir.');
  end if;

  -- Tetik kilidini yalnız bu güvenli bölge açar; işlem bitince kapanır.
  perform set_config('vixrex.fatura_yayin_serbest', 'acik', true);

  update public.products
  set is_visible = true,
      updated_at = now()
  where id = p_product_id;

  return jsonb_build_object('success', true, 'id', p_product_id);
end;
$$;

alter function public.publish_invoice_product(uuid, text) owner to postgres;

revoke execute on function public.publish_invoice_product(uuid, text) from public;

grant execute on function public.publish_invoice_product(uuid, text)
  to anon, authenticated, service_role;

comment on function public.publish_invoice_product(uuid, text) is
  'Fatura taslagini gorunur yapan TEK yol. Kapilar (sahiplik, fiyat, fotograf, stok, kanit) yeniden okunur.';
