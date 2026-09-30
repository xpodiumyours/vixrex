alter table public.invoice_job_lines
  add column if not exists product_id uuid references public.products(id) on delete set null,
  add column if not exists product_linked_at timestamptz;

create index if not exists invoice_job_lines_product_id_idx
  on public.invoice_job_lines (product_id)
  where product_id is not null;

comment on column public.invoice_job_lines.product_id is
  'Bu fatura satirindan olusan ya da bu satirin baglandigi urun. Ayni satir yeniden kaydedilince ayni urun guncellenir; ikinci urun olusmaz.';
