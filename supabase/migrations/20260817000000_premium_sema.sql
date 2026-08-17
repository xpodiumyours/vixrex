-- ============================================================================
-- Premium şeması — "Kiralık Vitrin = Premium" modeli (PR #1)
-- ============================================================================
-- NEDEN VAR
-- İş modeli (2026-08-17, Casper kararları): esnaf hazır şablonu kiralayıp
-- 14 gün denedikten sonra aylık 299 TL premium ile sahiplenir. Premium
-- VİTRİNE bağlıdır — esnaf hesap açmaz (kiralanan vitrinin user_id'si
-- null'dur, sahiplik edit_token + sahip oturumu üzerindendir, bkz.
-- clone_demo_store_as_draft deny-list'i). Bu yüzden premium süresi
-- profiles'ta DEĞİL, stores satırında tutulur.
--
-- NE EKLER
-- 1) stores.premium_expires_at: vitrinin premium süresinin bittiği an.
--    null = hiç premium olmamış / süre yok. Bu alan YALNIZCA doğrulanmış
--    PayTR callback'i (servis rolü) tarafından yazılır — istemci asla.
-- 2) premium_orders: PayTR ödeme siparişlerinin kaydı. merchant_oid
--    benzersizdir (aynı sipariş iki kez onaylanamaz — tek kullanımlık
--    garantisi). status: pending → paid/failed; paid yalnız imzası
--    doğrulanmış callback'ten gelir.
--
-- GÜVENLİK (VIXREX_RULES §9)
-- - premium_orders'ta RLS AÇIK ve politika YOK: anon/authenticated
--   doğrudan SELECT/INSERT/UPDATE/DELETE YAPAMAZ. Tüm erişim service_role
--   (Next.js API route, server-only) veya SECURITY DEFINER fonksiyonundan.
-- - stores.premium_expires_at için anon/authenticated'e SELECT grant'ı
--   VERİLMEZ: müşteri vitrini premium alanını göremez (gerekirse ileride
--   bilinçli bir kararla ayrı grant eklenir).
-- - owner_forbidden_draft_keys ZATEN 'is_premium','premium_plan',
--   'premium_expires_at' içeriyor (20260805100000) — esnaf çalışma
--   taslağı üzerinden premium alanlarına yazamaz. Bu koruma burada
--   TEKRARLANMAZ, var olana güvenilir.
-- ============================================================================

-- ── 1) stores.premium_expires_at ──────────────────────────────────────────
alter table public.stores
  add column if not exists premium_expires_at timestamptz;

comment on column public.stores.premium_expires_at is
  'Vitrinin premium süresinin bittiği an (null = premium yok). YALNIZCA
   doğrulanmış PayTR callback''i yazar; istemci ve çalışma taslağı
   yazamaz (owner_forbidden_draft_keys).';

-- ── 2) premium_orders ─────────────────────────────────────────────────────
create table if not exists public.premium_orders (
  id uuid primary key default gen_random_uuid(),
  merchant_oid text not null unique,
  store_id uuid not null references public.stores(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'paid', 'failed')),
  amount_kurus integer not null,
  currency text not null default 'TRY',
  created_at timestamptz not null default now(),
  paid_at timestamptz
);

comment on table public.premium_orders is
  'PayTR premium ödeme siparişleri. merchant_oid benzersiz — aynı sipariş
   iki kez onaylanamaz. RLS açık ve politika yok: yalnız service_role
   (Next.js server-only) erişir.';

comment on column public.premium_orders.merchant_oid is
  'PayTR sipariş kimliği (bizim ürettiğimiz). Tek kullanımlık: paid
   durumuna yalnız imzası doğrulanmış callback geçirir.';

comment on column public.premium_orders.amount_kurus is
  'Tutar kuruş cinsinden (PayTR payment_amount tutarı ×100 taşır).';

alter table public.premium_orders enable row level security;

-- anon/authenticated/public: tablo üzerinde hiçbir yetki yok. Yeni
-- tablolara PostgreSQL varsayılan olarak PUBLIC'e yetki vermez, ama
-- 20260815210000_default_privileges_ve_audit_log.sql sonrası disiplin
-- gereği açıkça güvence altına alınır (grant satırı yok ≠ kapalı değildir).
revoke all on table public.premium_orders from public, anon, authenticated;
grant all on table public.premium_orders to service_role;

-- stores.premium_expires_at: istemcilere KAPALI (hem SELECT hem UPDATE).
--
-- SELECT: kolon bazlı yetki temel şemada tek tek veriliyor; bu kolona
-- SELECT grant'ı yok → anon/authenticated okuyamaz.
--
-- UPDATE: tablo düzeyinde anon/authenticated'e UPDATE izni VAR (temel
-- şema) ve "Owners can update their stores" RLS politikası kolon ayırt
-- etmez. Kolon-bazlı revoke burada İŞE YARAMAZ (PostgreSQL'de tablo
-- düzeyindeki grant'ı ezmiyor — 2026-08-17 canlı testte UPDATE 1 ile
-- kanıtlandı). Gerçek koruma tetikleyicidir: premium_expires_at değiştiği
-- UPDATE'lerde çağıran service_role/postgres (doğrulanmış PayTR callback'i,
-- security definer fonksiyonlar) değilse reddedilir. Böylece esnaf kendi
-- süresini HİÇBİR istemci yolundan uzatamaz.
create or replace function public.protect_premium_expires_at()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
begin
  -- DİKKAT: security definer fonksiyonda current_user HER ZAMAN fonksiyon
  -- sahibi (postgres) döner — kontrol işe yaramazdı (2026-08-17 canlı
  -- testte kanıtlandı). Gerçek çağıran rolü SET ROLE'un koyduğu 'role'
  -- GUC'undan okunur; PostgREST her istekte rolü buna yazar
  -- (anon/authenticated/service_role). Doğrudan postgres bağlantısı
  -- 'none' döner (migration/admin — güvenilir, izin verilir).
  if new.premium_expires_at is distinct from old.premium_expires_at
     and coalesce(nullif(current_setting('role', true), ''), 'postgres')
         not in ('service_role', 'postgres', 'none') then
    raise exception 'PREMIUM_EXPIRES_AT_RESTRICTED'
      using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists protect_premium_expires_at on public.stores;
create trigger protect_premium_expires_at
  before update of premium_expires_at on public.stores
  for each row execute function public.protect_premium_expires_at();

comment on function public.protect_premium_expires_at() is
  'premium_expires_at''i yalnız service_role/postgres yazabilir. İstemci
   (anon/authenticated, RLS politikası üzerinden bile) değiştirmeye
   kalkarsa PREMIUM_EXPIRES_AT_RESTRICTED. Rol, security definer içinde
   current_user''dan DEĞİL current_setting(''role'') GUC''undan okunur
   (set role her istekte PostgREST tarafından yazılır). Kolon-bazlı revoke
   tek başına yetmez (tablo grant''ını ezmez) — tetikleyici asıl kapıdır.';
