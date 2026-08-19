-- ============================================================================
-- PayTR callback çift işlenme kilidi (TOCTOU) — V-20
-- ============================================================================
-- NEDEN: record_premium_payment paralel callback'lerde (PayTR aynı bildirimi
-- tekrar gönderebilir) yarışa açıktı: kilitsiz `select po ... limit 1` ile
-- okuyup sonra `update ... set status='paid'` yapıyordu. İki eşzamanlı istek
-- aynı anda 'pending' okursa, her ikisi de erken-dönüş korumasını
-- (status='paid' kontrolü) atlar ve stores'a 2 kez +30 gün ekler — mağazaya
-- bedavaya 60 gün premium.
--
-- NE YAPILIR:
--   (1) Satır `SELECT ... FOR UPDATE` ile kilitlenir — eşzamanlı callback'ler
--       serileşir; ikincisi ilk callback commit'ledikten sonra satırı 'paid'
--       görür ve erken döner (already_paid=true).
--   (2) `update premium_orders` tepesine `WHERE status = 'pending'` koşulu
--       eklenir — zaten 'paid' olan satır bir daha işlenmez.
--
-- DOKUNULMAYANLAR: İmza doğrulama (Next.js rotasındaki timingSafeEqual) ve
-- tutar/tutar kontrolü (aşağıdaki AMOUNT_MISMATCH / CURRENCY_MISMATCH) aynen
-- korunur; yalnız kilit + koşul eksikliği kapatılır.
-- ============================================================================

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

  -- TOCTOU kilidi (V-20): aynı merchant_oid için paralel callback'leri serileştir.
  -- NOT: `select po into v_order` composite atama PL/pgSQL'de uuid hatası verdiği
  -- için (20260817030000 yorumu) satırı ayrıca FOR UPDATE ile kilitliyoruz;
  -- v_order değeri skaler alt-sorgu ile okunur (o atama biçimi güvenli).
  perform 1
  from public.premium_orders po
  where po.merchant_oid = v_merchant_oid
  limit 1
  for update;

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

  -- Yalnız 'pending' olan satır 'paid' yapılır; FOR UPDATE kilidi ve bu koşul
  -- sayesinde ikinci eşzamanlı callback satırı tekrar işleyemez.
  update public.premium_orders
  set status = 'paid', paid_at = now()
  where merchant_oid = v_merchant_oid
    and status = 'pending';

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
   idempotent (aynı merchant_oid tekrar gelirse süre uzatılmaz). TOCTOU kilidi:
   satır FOR UPDATE ile kilitlenir, update yalnız pending satıra uygulanır.';

revoke execute on function public.record_premium_payment(text, integer, text)
  from public, anon, authenticated;
grant execute on function public.record_premium_payment(text, integer, text)
  to service_role;
