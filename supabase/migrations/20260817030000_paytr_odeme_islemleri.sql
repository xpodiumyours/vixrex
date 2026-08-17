-- ============================================================================
-- PayTR ödeme akışı — sipariş oluşturma + doğrulanmış ödemeyi premium'a işleme
-- ============================================================================
-- NEDEN VAR
-- Spec (2026-08-17): "Kiralık Vitrin = Premium" — aylık 299 TL. Ödeme yalnız
-- PayTR callback'i üzerinden işlenir; istemci kendi kendine premium yazamaz
-- (Flutter'daki purchasePremium iskeletinin açığı kapanır, VIXREX_RULES §9).
--
-- NE YAPAR
--   A) create_premium_order(): yayın kapısındaki "Aylık 299 TL ile yayınla"
--      akışı /api/paytr/create-link rotası tarafından çağrılır. Bekleyen
--      (pending) sipariş satırı açar; merchant_oid unique — aynı sipariş
--      iki kez açılamaz (20260817000000_premium_sema.sql).
--   B) record_premium_payment(): YALNIZ imzası doğrulanmış PayTR callback'i
--      (service_role) çağırır. Fail-closed: tutar uyuşmazsa AMOUNT_MISMATCH,
--      bilinmeyen siparişte UNKNOWN_ORDER. İdempotent: aynı merchant_oid
--      tekrar gelirse süre İKİNCİ KEZ uzatılmaz (replay güvenli).
--      Başarıda stores.premium_expires_at, mevcut sürenin üstüne 30 gün
--      eklenir — erken yenilemede kalan gün kaybolmaz.
--
-- GÜVENLİK
-- Her iki fonksiyon da security definer; public/anon/authenticated'e açıkça
-- revoke — yalnız service_role (Next.js route) çağırabilir. İstemcinin
-- premium'a dolaylı yazma yolu kalmaz.
-- ============================================================================

-- ── A) Bekleyen sipariş oluştur ────────────────────────────────────────────
create or replace function public.create_premium_order(
  p_store_id uuid,
  p_merchant_oid text,
  p_amount_kurus integer,
  p_currency text default 'TRY'
)
returns public.premium_orders
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_merchant_oid text := pg_catalog.btrim(coalesce(p_merchant_oid, ''));
  v_currency text := pg_catalog.upper(pg_catalog.btrim(coalesce(p_currency, 'TRY')));
  v_allowed boolean;
  v_retry_after integer;
begin
  if v_merchant_oid = '' then
    raise exception 'INVALID_MERCHANT_OID';
  end if;
  if p_amount_kurus is null or p_amount_kurus <= 0 then
    raise exception 'INVALID_AMOUNT';
  end if;
  if v_currency in ('', 'TL') then
    v_currency := 'TRY';
  end if;
  if not exists (select 1 from public.stores where id = p_store_id) then
    raise exception 'STORE_NOT_FOUND';
  end if;

  -- Aynı mağazadan saatlik sipariş patlamasını durdurur (defense in depth —
  -- rota zaten sahip oturumu ister; bu ikinci katman, rent-demo deseni).
  select allowed, retry_after_seconds
  into v_allowed, v_retry_after
  from public.consume_assistant_request('paytr:order:' || p_store_id::text, 5, 3600);
  if not v_allowed then
    raise exception 'RATE_LIMITED'
      using errcode = 'P0001', detail = v_retry_after::text;
  end if;

  insert into public.premium_orders (
    store_id, merchant_oid, status, amount_kurus, currency
  )
  values (p_store_id, v_merchant_oid, 'pending', p_amount_kurus, v_currency)
  on conflict (merchant_oid) do nothing;

  return (select po from public.premium_orders po
          where po.merchant_oid = v_merchant_oid limit 1);
end;
$$;

comment on function public.create_premium_order(uuid, text, integer, text) is
  'PayTR Link API akışında bekleyen premium siparişini açar. merchant_oid
   unique — aynı sipariş iki kez açılamaz. Yalnız service_role çağırabilir;
   public/anon/authenticated KAPALI.';

revoke execute on function public.create_premium_order(uuid, text, integer, text)
  from public, anon, authenticated;
grant execute on function public.create_premium_order(uuid, text, integer, text)
  to service_role;

-- ── B) Doğrulanmış ödemeyi premium'a işle ──────────────────────────────────
create or replace function public.record_premium_payment(
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
  v_merchant_oid text := pg_catalog.btrim(coalesce(p_merchant_oid, ''));
  v_currency text := pg_catalog.upper(pg_catalog.btrim(coalesce(p_currency, 'TRY')));
  v_order public.premium_orders;
  v_new_expiry timestamptz;
begin
  if v_merchant_oid = '' then
    raise exception 'INVALID_MERCHANT_OID';
  end if;
  if v_currency in ('', 'TL') then
    v_currency := 'TRY';
  end if;

  -- Not: 'select po into v_order' (tüm-satır referansı) PL/pgSQL'de
  -- "invalid input syntax for type uuid" ile kırılır (2026-08-17, canlı
  -- testte yakalandı) — scalar subquery ataması satır yoksa null, varsa
  -- composite döndürür, kolon sırasına bağımlı değildir.
  v_order := (
    select po from public.premium_orders po
    where po.merchant_oid = v_merchant_oid
    limit 1
  );

  if v_order.merchant_oid is null then
    raise exception 'UNKNOWN_ORDER';
  end if;

  -- İdempotent: PayTR yeniden dener veya aynı callback tekrar gönderilir —
  -- süre İKİNCİ KEZ uzatılmaz. merchant_oid tek kullanımlıktır.
  if v_order.status = 'paid' then
    select premium_expires_at into v_new_expiry
    from public.stores where id = v_order.store_id;
    return jsonb_build_object(
      'already_paid', true,
      'store_id', v_order.store_id,
      'premium_expires_at', v_new_expiry
    );
  end if;

  -- Fail-closed: callback'ten gelen tutar asla doğrudan güvenilmez;
  -- siparişte saklanan tutarla karşılaştırılır. Uyuşmazsa işlenmez.
  if p_amount_kurus is null or p_amount_kurus <> v_order.amount_kurus then
    raise exception 'AMOUNT_MISMATCH'
      using errcode = 'P0001',
            detail = 'beklenen=' || v_order.amount_kurus ||
                     ', gelen=' || coalesce(p_amount_kurus, 0);
  end if;

  if v_currency <> v_order.currency then
    raise exception 'CURRENCY_MISMATCH';
  end if;

  update public.premium_orders
  set status = 'paid', paid_at = now()
  where merchant_oid = v_merchant_oid;

  -- Erken yenilemede kalan gün kaybolmaz: mevcut sürenin (veya bugünün)
  -- üstüne 30 gün eklenir. stores UPDATE'i bump_store_version tetikleyicisini
  -- ateşler — taslak-sürüm çakışması koruması premium değişiminde de işler.
  update public.stores
  set premium_expires_at =
      greatest(coalesce(premium_expires_at, now()), now()) + interval '30 days'
  where id = v_order.store_id
  returning premium_expires_at into v_new_expiry;

  return jsonb_build_object(
    'already_paid', false,
    'store_id', v_order.store_id,
    'premium_expires_at', v_new_expiry
  );
end;
$$;

comment on function public.record_premium_payment(text, integer, text) is
  'Doğrulanmış PayTR callback''inden gelen ödemeyi premium süresine işler.
   Yalnız service_role çağırabilir. Fail-closed (tutar uyuşmazlığı işlenmez),
   idempotent (aynı merchant_oid tekrar gelirse süre uzatılmaz).';

revoke execute on function public.record_premium_payment(text, integer, text)
  from public, anon, authenticated;
grant execute on function public.record_premium_payment(text, integer, text)
  to service_role;
