-- Faturadaki birim ALIŞ fiyatını saklar. Yalnız esnaf görür.
--
-- NEDEN AYRI TABLO (2026-09-26 ölçümü):
-- `public.products` üzerinde anon rolünün TABLO DÜZEYİNDE select yetkisi var
-- (information_schema.table_privileges ile ölçüldü). Bu yüzden o tabloya
-- eklenen HER yeni kolon anonim istemciye kendiliğinden açılır. Alış fiyatı
-- oraya konulsaydı, kodumuz hiç göstermese bile müşteri ya da rakip veriyi
-- doğrudan çekebilirdi. Mevcut yetkileri daraltmak canlı vitrini kırma riski
-- taşıdığı için tercih edilmedi; alış fiyatı kendi kilitli tablosunda durur.
--
-- Alış fiyatı hiçbir koşulda satış fiyatına (price_amount / price_text)
-- kopyalanmaz.

create table if not exists public.product_purchase_prices (
  product_id uuid primary key references public.products(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  amount numeric not null check (amount >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.product_purchase_prices is
  'Faturadaki birim alış fiyatı. Yalnız esnafa görünür, müşteriye gösterilmez, satış fiyatı yerine geçmez.';

create index if not exists product_purchase_prices_store_id_idx
  on public.product_purchase_prices (store_id);

alter table public.product_purchase_prices enable row level security;

-- Kilit: anon ve authenticated bu tabloya hiç erişemez. Okuma/yazma yalnız
-- sunucu tarafındaki service_role ile, esnaf oturumu doğrulandıktan sonra
-- yapılır. RLS politikası bilerek TANIMLANMAZ — politika yoksa erişim yoktur.
revoke all on public.product_purchase_prices from anon;
revoke all on public.product_purchase_prices from authenticated;
revoke all on public.product_purchase_prices from public;
