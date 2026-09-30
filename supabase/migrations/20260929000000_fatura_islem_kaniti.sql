create table if not exists public.invoice_jobs (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  document_fingerprint text not null,
  status text not null default 'inceleme'
    check (status in ('eslestirme', 'inceleme', 'tamam')),
  supplier_name text not null default '',
  supplier_tax_id text not null default '',
  supplier_address text not null default '',
  supplier_site text not null default '',
  supplier_trace jsonb,
  document_adet numeric,
  document_total numeric,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists invoice_jobs_store_dokuman_uq
  on public.invoice_jobs (store_id, document_fingerprint);

create index if not exists invoice_jobs_store_id_idx
  on public.invoice_jobs (store_id);

comment on table public.invoice_jobs is
  'Fatura isleminin durumu ve belge ustu tedarikci kimligi. Yalniz vixrex sunucusu (service_role) yazar; anon ve authenticated okuyamaz.';
comment on column public.invoice_jobs.document_fingerprint is
  'Fatura fotografinin sha256 ozeti. Ayni fotograf yeniden yuklenince ayni is acilir; ikinci bir is kaydi olusmaz.';

create table if not exists public.invoice_job_lines (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.invoice_jobs(id) on delete cascade,
  line_index integer not null,
  raw_line text not null default '',
  model text not null default '',
  product_name text not null default '',
  barcode text not null default '',
  variant_name text not null default '',
  size_text text not null default '',
  qty numeric,
  unit_price numeric,
  line_total numeric,
  confidence numeric not null default 0,
  outcome text not null
    check (outcome in ('kanitli', 'eksik', 'celiski', 'iz-yok')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (job_id, line_index)
);

create index if not exists invoice_job_lines_job_id_idx
  on public.invoice_job_lines (job_id);

comment on table public.invoice_job_lines is
  'Faturanin her satiri, ham metni ve dordu bir sonuctan biri. Okunamayan satir silinmez, eksik/celiski olarak kalir.';
comment on column public.invoice_job_lines.unit_price is
  'Faturadaki ALIS fiyatidir. Satis fiyatina kopyalanmaz, musteriye gosterilmez.';

create table if not exists public.invoice_line_evidence (
  id uuid primary key default gen_random_uuid(),
  line_id uuid not null references public.invoice_job_lines(id) on delete cascade,
  field_name text not null,
  value_text text not null,
  source text not null,
  strength text not null check (strength in ('strong', 'partial', 'weak')),
  checked_at timestamptz not null default now(),
  unique (line_id, field_name, source)
);

create index if not exists invoice_line_evidence_line_id_idx
  on public.invoice_line_evidence (line_id);

comment on table public.invoice_line_evidence is
  'Alan bazinda kanit: deger + nereden geldigi + kanit gucu + kontrol zamanı.';

create table if not exists public.invoice_line_candidates (
  id uuid primary key default gen_random_uuid(),
  line_id uuid not null references public.invoice_job_lines(id) on delete cascade,
  url text not null,
  platform text not null default '',
  found_at timestamptz not null default now(),
  unique (line_id, url)
);

create index if not exists invoice_line_candidates_line_id_idx
  on public.invoice_line_candidates (line_id);

comment on table public.invoice_line_candidates is
  'Satir icin arastirilan aday kaynak baglantilari. Kesinlesmeden tuketici urunune gecmez.';

create table if not exists public.invoice_image_rights (
  id uuid primary key default gen_random_uuid(),
  line_id uuid not null references public.invoice_job_lines(id) on delete cascade,
  image_url text not null,
  usage_status text not null
    check (usage_status in (
      'verified_supplier_permission',
      'verified_feed_terms',
      'merchant_owned_media',
      'merchant_attestation',
      'unknown',
      'denied'
    )),
  source text not null default '',
  checked_at timestamptz not null default now(),
  unique (line_id, image_url)
);

create index if not exists invoice_image_rights_line_id_idx
  on public.invoice_image_rights (line_id);

comment on table public.invoice_image_rights is
  'Gorsel adayi ve kullanim izni durumu. Yalnizca acikca "denied" isaretli gorsel tuketici kartina girmez; "unknown" (izin henuz sorulmadi) GIRER — izin turu calisan sistemi durdurmaz, sonra yurur. Kilitli kapsam: docs/FATURADAN-VITRINE-MASTER-PLAN.md F1 ve AGENTS.md.';

alter table public.invoice_jobs enable row level security;
alter table public.invoice_job_lines enable row level security;
alter table public.invoice_line_evidence enable row level security;
alter table public.invoice_line_candidates enable row level security;
alter table public.invoice_image_rights enable row level security;

revoke all on public.invoice_jobs from anon;
revoke all on public.invoice_jobs from authenticated;
revoke all on public.invoice_jobs from public;
revoke all on public.invoice_job_lines from anon;
revoke all on public.invoice_job_lines from authenticated;
revoke all on public.invoice_job_lines from public;
revoke all on public.invoice_line_evidence from anon;
revoke all on public.invoice_line_evidence from authenticated;
revoke all on public.invoice_line_evidence from public;
revoke all on public.invoice_line_candidates from anon;
revoke all on public.invoice_line_candidates from authenticated;
revoke all on public.invoice_line_candidates from public;
revoke all on public.invoice_image_rights from anon;
revoke all on public.invoice_image_rights from authenticated;
revoke all on public.invoice_image_rights from public;
