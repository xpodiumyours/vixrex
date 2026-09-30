-- ============================================================================
-- VIXREX — FATURA AKIŞI VERİTABANI KURULUMU (TEK DOSYA)
-- ============================================================================
-- Tarih: 01.10.2026
-- Bu dosya supabase/migrations altındaki 6 dosyanın birleşimidir:
--   20260930000000_fatura_yayin_kapisi.sql
--   20260930100000_fatura_belge_kimligi.sql
--   20260930110000_fatura_satir_urun_baglantisi.sql
--   20260930120000_fatura_islem_geri_acma.sql
--   20260930130000_fatura_firma_izni.sql
--   20260930140000_fatura_yayin_kapisi_sertlestirme.sql
--
-- 20260929000000 (5 temel tablo) KANLIDA ZATEN VAR — o yüzden burada yok.
--
-- NASIL KULLANILIR
--   Supabase Dashboard -> SQL Editor -> New query -> bu dosyanin tamamini
--   yapistir -> Run. Tek islem, tek sonuc.
--
-- GUVENLIK
--   * Veri SILMEZ. Mevcut tabloyu BOSALTMaz. Sadece yeni nesne ekler.
--   * Her ifade tekrar calistirilabilir (if not exists / create or replace).
--   * Mevcut 273 urun, 44 vitrin, 3483 vitrin goruntulenmesi DEGISTIRILMEZ.
-- ============================================================================

begin;

-- ═══════════════════════════════════════════════════════════════════════════
-- 1) YAYINLAMA KAPISI
--    - products tablosuna kanit alani
--    - fatura kaynakli urun otomatik gizli baslar
--    - yayinlama fonksiyonu (yalnizca sunucudan cagrilir)
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.products
  add column if not exists fatura_kanit jsonb;

comment on column public.products.fatura_kanit is
  'Fatura satiri kaniti. tur=invoice olan urun icin kaynak/eşleşme/izin kaydi. Alici sayfasina gosterilmez.';

create or replace function public.fatura_yayin_kilidi()
returns trigger
language plpgsql
as $$
begin
  -- Fatura kaynakli urun, yayin kapisi gecmeden gorunur olamaz.
  if new.source_type = 'invoice' and coalesce(new.is_visible, false) then
    if not exists (
      select 1 from public.products p
      where p.id = new.id
        and p.fatura_kanit is not null
        and p.price_amount is not null and p.price_amount > 0
        and p.stock_quantity is not null
        and jsonb_array_length(coalesce(p.image_urls, '[]'::jsonb)) >= 1
        and p.fatura_kanit->>'kartDurumu' = 'kanitli'
        and p.fatura_kanit->>'stokOnaylandi' = 'true'
    ) then
      new.is_visible := false;
    end if;
  end if;
  return new;
end;
$$;

alter function public.fatura_yayin_kilidi() set search_path = pg_catalog, public;
alter function public.fatura_yayin_kilidi() owner to postgres;

drop trigger if exists fatura_yayin_kilidi on public.products;
create trigger fatura_yayin_kilidi
  before insert or update on public.products
  for each row execute function public.fatura_yayin_kilidi();

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
  v_store uuid;
  v_sonuc jsonb;
begin
  select s.id into v_store
  from public.stores s
  where s.edit_token = p_edit_token;

  if v_store is null then
    raise exception 'Yetkisiz'
      using errcode = 'P0001';
  end if;

  update public.products p
  set is_visible = true
  where p.id = p_product_id
    and p.store_id = v_store
    and p.source_type = 'invoice'
    and p.price_amount is not null and p.price_amount > 0
    and jsonb_array_length(coalesce(p.image_urls, '[]'::jsonb)) >= 1
    and p.stock_quantity is not null
    and p.fatura_kanit is not null
    and p.fatura_kanit->>'kartDurumu' = 'kanitli'
    and p.fatura_kanit->>'stokOnaylandi' = 'true'
  returning jsonb_build_object(
    'id', p.id,
    'slug', p.slug,
    'durum', 'yayinda'
  ) into v_sonuc;

  if v_sonuc is null then
    raise exception 'Yayin kapilari saglanmadi'
      using errcode = 'P0001';
  end if;

  return v_sonuc;
end;
$$;

alter function public.publish_invoice_product(uuid, text) owner to postgres;

-- DIKKAT: Once anon/authenticated acikti, bu dosya kapatiyor.
-- Yayinlama yalnizca sunucudan (/api/fatura-yayinla) yapilir.
revoke execute on function public.publish_invoice_product(uuid, text) from public;
revoke execute on function public.publish_invoice_product(uuid, text) from anon;
revoke execute on function public.publish_invoice_product(uuid, text) from authenticated;
grant execute on function public.publish_invoice_product(uuid, text) to service_role;

comment on function public.publish_invoice_product(uuid, text) is
  'Fatura taslagini gorunur yapan TEK yol. Fiyat, fotograf, stok ve kanit kapilari yeniden okunur.';


-- ═══════════════════════════════════════════════════════════════════════════
-- 2) BELGE KIMLIGI + AYNI ALISVERIS KORUMASI
--    Bilgi fişi + e-Arşiv faturası aynı alışveriş sayılır; adet ikiye katlanmaz.
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.invoice_jobs
  add column if not exists document_type text,
  add column if not exists document_no text,
  add column if not exists document_date date,
  add column if not exists goods_total numeric,
  add column if not exists vat_total numeric,
  add column if not exists discount_total numeric,
  add column if not exists payable_total numeric,
  add column if not exists same_purchase_of uuid references public.invoice_jobs(id) on delete set null,
  add column if not exists same_purchase_confirmed_at timestamptz;


-- ═══════════════════════════════════════════════════════════════════════════
-- 3) SATIR -> URUN KALICI BAGLANTI
--    Esnaf her onayda yeni urun acmaz; ayni satir ayni urune baglanir.
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.invoice_job_lines
  add column if not exists product_id uuid references public.products(id) on delete set null,
  add column if not exists product_linked_at timestamptz;

create index if not exists invoice_job_lines_product_id_idx
  on public.invoice_job_lines (product_id);


-- ═══════════════════════════════════════════════════════════════════════════
-- 4) ISLEMI KAPAT-AÇ + ESNAF DUZENLEMESI
--    Esnaf ekrani kapatip acabilir, baska cihazda devam edebilir.
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.invoice_job_lines
  add column if not exists brand text,
  add column if not exists warning text,
  add column if not exists catalog_snapshot jsonb,
  add column if not exists conflict_snapshot jsonb,
  add column if not exists owner_state jsonb,
  add column if not exists owner_state_updated_at timestamptz;

alter table public.invoice_jobs
  add column if not exists document_warning text,
  add column if not exists supplier_trace_snapshot jsonb;


-- ═══════════════════════════════════════════════════════════════════════════
-- 5) FIRMA IZNI
--    Esnaf "ben isteyecegim" / "VixRex istesin" secimi; talep ve cevap takibi.
-- ═══════════════════════════════════════════════════════════════════════════

create table if not exists public.supplier_permissions (
  id uuid primary key default gen_random_uuid(),
  supplier_key text not null,
  supplier_name text not null default '',
  scope text not null check (scope in ('data', 'images', 'data_and_images')),
  status text not null check (status in ('izin_yok', 'soruldu', 'verildi', 'reddedildi', 'geri_cekildi')),
  valid_until date,
  responded_at timestamptz,
  response_note text,
  verified_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (supplier_key, scope)
);

create table if not exists public.supplier_permission_requests (
  id uuid primary key default gen_random_uuid(),
  supplier_key text not null,
  supplier_name text not null default '',
  scope text not null check (scope in ('data', 'images', 'data_and_images')),
  store_id uuid references public.stores(id) on delete set null,
  job_id uuid references public.invoice_jobs(id) on delete set null,
  status text not null default 'hazirlandi'
    check (status in ('hazirlandi', 'gonderim_bekliyor', 'gonderildi', 'cevaplandi', 'kapandi')),
  channel text check (channel in ('esnaf', 'vixrex')),
  contact text,
  sample_note text,
  sent_at timestamptz,
  answered_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.supplier_permission_products (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.supplier_permission_requests(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (request_id, product_id)
);

create index if not exists supplier_permission_requests_key_idx
  on public.supplier_permission_requests (supplier_key, scope);
create index if not exists supplier_permission_products_request_idx
  on public.supplier_permission_products (request_id);

alter table public.supplier_permissions enable row level security;
alter table public.supplier_permission_requests enable row level security;
alter table public.supplier_permission_products enable row level security;

revoke all on public.supplier_permissions from anon, authenticated, public;
revoke all on public.supplier_permission_requests from anon, authenticated, public;
revoke all on public.supplier_permission_products from anon, authenticated, public;

grant all on public.supplier_permissions to service_role;
grant all on public.supplier_permission_requests to service_role;
grant all on public.supplier_permission_products to service_role;


-- ═══════════════════════════════════════════════════════════════════════════
-- 6) POSTGREST ONBELLEGINI TAZELE
-- ═══════════════════════════════════════════════════════════════════════════

notify pgrst, 'reload schema';

commit;
