-- ============================================================================
-- Sipariş + tahsilat — müşteri siparişi ve ödeme eşleştirmesi
-- ============================================================================
-- NEDEN VAR
-- Ürün vitrinde görüldüğü halde satın alma yolu yoktu; müşteri yalnız
-- WhatsApp'a yazılıyordu. Bu şema, vitrindeki üründen sipariş almayı ve
-- PayTR ile online tahsilatı ekler (2026-09-26, sipariş+tahsilat paketi).
--
-- NE EKLER
--   1) store_orders: müşteri siparişi (isim+telefon, hesap GEREKMEZ).
--      status: new → confirmed → delivered / cancelled.
--      payment_status: unpaid → paid (yalnız imzası doğrulanmış PayTR
--      callback'i yazar — premium_orders ile aynı kural).
--   2) store_order_items: sipariş kalemleri — fiyat ANLIK ÜRÜNDEN alınır,
--      kalem bazında dondurulur (customer fiyatı değiştiremez).
--   3) create_store_order(): tutarı SUNUCU hesaplar (ürünün price_amount
--      alanı), görünürlük/aidiyet denetimi yapar, oran sınırı uygular.
--   4) record_store_order_payment(): YALNIZ imzası doğrulanmış callback
--      çağırır. Fail-closed (tutar uyuşmazsa işlenmez), idempotent.
--
-- GÜVENLİK
-- store_orders / store_order_items: RLS AÇIK, politika YOK — anon ve
-- authenticated doğrudan erişemez. Tüm erişim service_role (Next.js
-- server-only) veya buradaki security definer fonksiyonları iledir.
-- ============================================================================

create table if not exists public.store_orders (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  callback_id text not null unique,
  customer_name text not null,
  customer_phone text not null,
  customer_note text not null default '',
  fulfillment text not null default 'pickup'
    check (fulfillment in ('pickup', 'delivery')),
  payment_method text not null default 'cash'
    check (payment_method in ('cash', 'online')),
  status text not null default 'new'
    check (status in ('new', 'confirmed', 'delivered', 'cancelled')),
  payment_status text not null default 'unpaid'
    check (payment_status in ('unpaid', 'paid')),
  amount_kurus integer not null check (amount_kurus > 0),
  currency text not null default 'TRY',
  merchant_oid text,
  created_at timestamptz not null default now(),
  paid_at timestamptz
);

comment on table public.store_orders is
  'Müşteri siparişleri. Fiyat tutarı SUNUCU tarafından ürün fiyatından
   hesaplanır. RLS açık, politika yok: yalnız service_role erişir.';

comment on column public.store_orders.callback_id is
  'PayTR Link API callback_id eşleştirmesi — benzersiz, tahmin edilemez
   (ord_ + uuid). Aynı zamanda ödeme linki yeniden üretiminin anahtarıdır.';

alter table public.store_orders enable row level security;
revoke all on table public.store_orders from public, anon, authenticated;
grant all on table public.store_orders to service_role;

create table if not exists public.store_order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.store_orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  unit_price_kurus integer not null check (unit_price_kurus >= 0),
  quantity integer not null check (quantity > 0 and quantity <= 99)
);

alter table public.store_order_items enable row level security;
revoke all on table public.store_order_items from public, anon, authenticated;
grant all on table public.store_order_items to service_role;

create or replace function public.create_store_order(
  p_store_slug text,
  p_callback_id text,
  p_customer_name text,
  p_customer_phone text,
  p_customer_note text default '',
  p_fulfillment text default 'pickup',
  p_payment_method text default 'cash',
  p_items jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_store_slug text := pg_catalog.btrim(coalesce(p_store_slug, ''));
  v_callback_id text := pg_catalog.btrim(coalesce(p_callback_id, ''));
  v_name text := pg_catalog.btrim(coalesce(p_customer_name, ''));
  v_phone text := pg_catalog.btrim(coalesce(p_customer_phone, ''));
  v_note text := pg_catalog.btrim(coalesce(p_customer_note, ''));
  v_fulfillment text := pg_catalog.btrim(coalesce(p_fulfillment, 'pickup'));
  v_payment text := pg_catalog.btrim(coalesce(p_payment_method, 'cash'));
  v_store public.stores;
  v_order_id uuid;
  v_total integer := 0;
  v_allowed boolean;
  v_retry_after integer;
  v_item jsonb;
  v_product public.products;
  v_qty integer;
  v_unit integer;
begin
  if v_store_slug = '' then
    raise exception 'STORE_NOT_FOUND';
  end if;
  if v_callback_id = '' or length(v_callback_id) > 64 then
    raise exception 'INVALID_CALLBACK_ID';
  end if;
  if length(v_name) < 2 or length(v_name) > 120 then
    raise exception 'INVALID_CUSTOMER_NAME';
  end if;
  if length(v_phone) < 10 or length(v_phone) > 20 then
    raise exception 'INVALID_CUSTOMER_PHONE';
  end if;
  if length(v_note) > 500 then
    raise exception 'INVALID_CUSTOMER_NOTE';
  end if;
  if v_fulfillment not in ('pickup', 'delivery') then
    raise exception 'INVALID_FULFILLMENT';
  end if;
  if v_payment not in ('cash', 'online') then
    raise exception 'INVALID_PAYMENT_METHOD';
  end if;
  if p_items is null or pg_catalog.jsonb_typeof(p_items) <> 'array'
     or pg_catalog.jsonb_array_length(p_items) = 0
     or pg_catalog.jsonb_array_length(p_items) > 20 then
    raise exception 'INVALID_ITEMS';
  end if;

  select s.* into v_store
  from public.stores s
  where s.slug = v_store_slug and s.is_published = true;

  if v_store.id is null then
    raise exception 'STORE_NOT_FOUND';
  end if;

  select allowed, retry_after_seconds
  into v_allowed, v_retry_after
  from public.consume_assistant_request('order:' || v_store.id::text, 5, 3600);
  if not v_allowed then
    raise exception 'RATE_LIMITED'
      using errcode = 'P0001', detail = v_retry_after::text;
  end if;

  insert into public.store_orders (
    store_id, callback_id, customer_name, customer_phone, customer_note,
    fulfillment, payment_method, amount_kurus, currency
  )
  values (
    v_store.id, v_callback_id, v_name, v_phone, v_note,
    v_fulfillment, v_payment, 1, 'TRY'
  )
  returning id into v_order_id;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_qty := coalesce((v_item->>'quantity')::integer, 0);
    if v_qty < 1 or v_qty > 99 then
      raise exception 'INVALID_QUANTITY';
    end if;

    select p.* into v_product
    from public.products p
    where p.store_id = v_store.id
      and p.slug = pg_catalog.btrim(coalesce(v_item->>'product_slug', ''))
      and p.is_visible = true
      and p.is_active = true
    limit 1;

    if v_product.id is null then
      raise exception 'PRODUCT_NOT_FOUND';
    end if;

    v_unit := round(coalesce(v_product.price_amount, 0) * 100)::integer;
    if v_unit <= 0 then
      raise exception 'PRODUCT_PRICE_MISSING';
    end if;

    insert into public.store_order_items (
      order_id, product_id, product_name, unit_price_kurus, quantity
    )
    values (v_order_id, v_product.id, v_product.name, v_unit, v_qty);

    v_total := v_total + (v_unit * v_qty);
  end loop;

  if v_total <= 0 then
    raise exception 'INVALID_AMOUNT';
  end if;

  update public.store_orders
  set amount_kurus = v_total
  where id = v_order_id;

  return jsonb_build_object(
    'order_id', v_order_id,
    'callback_id', v_callback_id,
    'amount_kurus', v_total,
    'currency', 'TRY',
    'whatsapp', coalesce(v_store.whatsapp, ''),
    'store_name', coalesce(v_store.name, ''),
    'items', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'product_name', soi.product_name,
        'unit_price_kurus', soi.unit_price_kurus,
        'quantity', soi.quantity
      )), '[]'::jsonb)
      from public.store_order_items soi
      where soi.order_id = v_order_id
    )
  );
end;
$$;

comment on function public.create_store_order(text, text, text, text, text, text, text, jsonb) is
  'Müşteri siparişini açar: tutar SUNUCU tarafından ürün fiyatından hesaplanır,
   oran sınırı uygulanır, yalnız yayındaki vitrin ve görünür ürünler sipariş
   edilebilir. Dönen whatsapp alanı sipariş özeti bağlantısı içindir.';

revoke execute on function public.create_store_order(text, text, text, text, text, text, text, jsonb)
  from public, anon, authenticated;
grant execute on function public.create_store_order(text, text, text, text, text, text, text, jsonb)
  to service_role;

create or replace function public.record_store_order_payment(
  p_callback_id text,
  p_merchant_oid text,
  p_amount_kurus integer,
  p_currency text default 'TRY'
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_callback_id text := pg_catalog.btrim(coalesce(p_callback_id, ''));
  v_merchant_oid text := pg_catalog.btrim(coalesce(p_merchant_oid, ''));
  v_currency text := pg_catalog.upper(pg_catalog.btrim(coalesce(p_currency, 'TRY')));
  v_order public.store_orders;
begin
  if v_callback_id = '' then
    raise exception 'INVALID_CALLBACK_ID';
  end if;
  if v_merchant_oid = '' then
    raise exception 'INVALID_MERCHANT_OID';
  end if;
  if v_currency in ('', 'TL') then
    v_currency := 'TRY';
  end if;

  perform 1
  from public.store_orders so
  where so.callback_id = v_callback_id
  limit 1
  for update;

  v_order := (
    select so from public.store_orders so
    where so.callback_id = v_callback_id
    limit 1
  );

  if v_order.callback_id is null then
    raise exception 'UNKNOWN_ORDER';
  end if;

  if v_order.payment_status = 'paid' then
    return jsonb_build_object(
      'already_paid', true,
      'order_id', v_order.id
    );
  end if;

  if p_amount_kurus is null or p_amount_kurus <> v_order.amount_kurus then
    raise exception 'AMOUNT_MISMATCH'
      using errcode = 'P0001',
            detail = 'beklenen=' || v_order.amount_kurus ||
                     ', gelen=' || coalesce(p_amount_kurus, 0);
  end if;

  if v_currency <> v_order.currency then
    raise exception 'CURRENCY_MISMATCH';
  end if;

  update public.store_orders
  set payment_status = 'paid',
      paid_at = now(),
      merchant_oid = v_merchant_oid,
      status = case when status = 'new' then 'confirmed' else status end
  where callback_id = v_callback_id;

  return jsonb_build_object(
    'already_paid', false,
    'order_id', v_order.id
  );
end;
$$;

comment on function public.record_store_order_payment(text, text, integer, text) is
  'Doğrulanmış PayTR callback''inden gelen sipariş ödemesini işler.
   Fail-closed (tutar uyuşmazsa AMOUNT_MISMATCH), idempotent (tekrar
   gelen callback ikinci kez işlemez). Yalnız service_role çağırabilir.';

revoke execute on function public.record_store_order_payment(text, text, integer, text)
  from public, anon, authenticated;
grant execute on function public.record_store_order_payment(text, text, integer, text)
  to service_role;

notify pgrst, 'reload schema';
