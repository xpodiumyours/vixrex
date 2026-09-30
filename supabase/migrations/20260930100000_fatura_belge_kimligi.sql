alter table public.invoice_jobs
  add column if not exists document_type text not null default '',
  add column if not exists document_no text not null default '',
  add column if not exists document_date date,
  add column if not exists goods_total numeric,
  add column if not exists vat_total numeric,
  add column if not exists discount_total numeric,
  add column if not exists payable_total numeric,
  add column if not exists same_purchase_of uuid references public.invoice_jobs(id) on delete set null,
  add column if not exists same_purchase_confirmed_at timestamptz;

create index if not exists invoice_jobs_store_supplier_date_idx
  on public.invoice_jobs (store_id, supplier_tax_id, document_date);

create index if not exists invoice_jobs_same_purchase_idx
  on public.invoice_jobs (same_purchase_of)
  where same_purchase_of is not null;

comment on column public.invoice_jobs.goods_total is
  'Mal bedeli (KDV ve indirim ayri). Satir tutarlari bununla karsilastirilir; odenecek toplam ile karistirilmaz.';
comment on column public.invoice_jobs.same_purchase_of is
  'Esnaf bu belgenin baska bir belgeyle AYNI alisveris oldugunu onayladiysa ilk belgenin kimligi. Iki belgenin adetleri toplanmaz.';
