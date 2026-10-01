alter table public.invoice_job_lines
  add column if not exists brand text not null default '',
  add column if not exists warning text not null default '',
  add column if not exists catalog_snapshot jsonb,
  add column if not exists conflict_snapshot jsonb,
  add column if not exists owner_state jsonb,
  add column if not exists owner_state_updated_at timestamptz;

alter table public.invoice_jobs
  add column if not exists document_warning text not null default '',
  add column if not exists supplier_trace_snapshot jsonb;

comment on column public.invoice_job_lines.catalog_snapshot is
  'Satirin resmi kaynaktan eslesen urun ozeti (KatalogBilgisi). Islem kapatilip acildiginda kart ayni haliyle geri yuklenir.';
comment on column public.invoice_job_lines.owner_state is
  'Esnafin bu satirda girdikleri: satis fiyati, stok ve stok onayi, kategori, kart onayi, kendi fotograflari. Baska cihazdan devam icin.';
