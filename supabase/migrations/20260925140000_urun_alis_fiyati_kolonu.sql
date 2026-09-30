-- Faturadan gelen birim alış fiyatını ürün kaydında tutar.
--
-- Neden ayrı kolon: `metadata` alanı herkese açık vitrin sorgusunda seçiliyor
-- (public_web/src/app/v/[slug]/page.tsx). Alış fiyatı oraya konulsaydı
-- müşteriye sızardı. Bu kolon o seçim listesinde yok; yalnız esnafın kendi
-- paneli okur.
--
-- Alış fiyatı hiçbir koşulda satış fiyatına (price_amount / price_text)
-- kopyalanmaz.

alter table public.products
  add column if not exists purchase_price_amount numeric;

comment on column public.products.purchase_price_amount is
  'Faturadaki birim alış fiyatı. Yalnız esnafa görünür, müşteriye gösterilmez, satış fiyatı yerine geçmez.';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'products_purchase_price_amount_check'
  ) then
    alter table public.products
      add constraint products_purchase_price_amount_check
      check (purchase_price_amount is null or purchase_price_amount >= 0);
  end if;
end $$;
