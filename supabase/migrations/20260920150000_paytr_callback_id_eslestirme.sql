alter table public.premium_orders add column if not exists callback_id text;

update public.premium_orders set callback_id = merchant_oid where callback_id is null;

alter table public.premium_orders alter column callback_id set not null;
alter table public.premium_orders alter column merchant_oid drop not null;

alter table public.premium_orders
  add constraint premium_orders_callback_id_key unique (callback_id);

create or replace function public.create_premium_order(
  p_store_id uuid,
  p_callback_id text,
  p_amount_kurus integer,
  p_currency text default 'TRY'::text
)
returns premium_orders
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_callback_id text := pg_catalog.btrim(coalesce(p_callback_id, ''));
  v_currency text := pg_catalog.upper(pg_catalog.btrim(coalesce(p_currency, 'TRY')));
  v_allowed boolean;
  v_retry_after integer;
begin
  if v_callback_id = '' then
    raise exception 'INVALID_CALLBACK_ID';
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

  select allowed, retry_after_seconds
  into v_allowed, v_retry_after
  from public.consume_assistant_request('paytr:order:' || p_store_id::text, 5, 3600);
  if not v_allowed then
    raise exception 'RATE_LIMITED'
      using errcode = 'P0001', detail = v_retry_after::text;
  end if;

  insert into public.premium_orders (
    store_id, callback_id, status, amount_kurus, currency
  )
  values (p_store_id, v_callback_id, 'pending', p_amount_kurus, v_currency)
  on conflict (callback_id) do nothing;

  return (select po from public.premium_orders po
          where po.callback_id = v_callback_id limit 1);
end;
$$;

revoke execute on function public.create_premium_order(uuid, text, integer, text) from public;
grant execute on function public.create_premium_order(uuid, text, integer, text) to service_role;

create or replace function public.record_premium_payment(
  p_callback_id text,
  p_merchant_oid text,
  p_amount_kurus integer,
  p_currency text default 'TRY'::text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_callback_id text := pg_catalog.btrim(coalesce(p_callback_id, ''));
  v_merchant_oid text := pg_catalog.btrim(coalesce(p_merchant_oid, ''));
  v_currency text := pg_catalog.upper(pg_catalog.btrim(coalesce(p_currency, 'TRY')));
  v_order public.premium_orders;
  v_new_expiry timestamptz;
begin
  if v_callback_id = '' then
    raise exception 'INVALID_CALLBACK_ID';
  end if;
  if v_merchant_oid = '' then
    raise exception 'INVALID_MERCHANT_OID';
  end if;
  if v_currency in ('', 'TL') then
    v_currency := 'TRY';
  end if;

  perform 1
  from public.premium_orders po
  where po.callback_id = v_callback_id
  limit 1
  for update;

  v_order := (
    select po from public.premium_orders po
    where po.callback_id = v_callback_id
    limit 1
  );

  if v_order.callback_id is null then
    raise exception 'UNKNOWN_ORDER';
  end if;

  if v_order.status = 'paid' then
    select premium_expires_at into v_new_expiry
    from public.stores where id = v_order.store_id;
    return jsonb_build_object(
      'already_paid', true,
      'store_id', v_order.store_id,
      'premium_expires_at', v_new_expiry
    );
  end if;

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
  set status = 'paid', paid_at = now(), merchant_oid = v_merchant_oid
  where callback_id = v_callback_id
    and status = 'pending';

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

revoke execute on function public.record_premium_payment(text, text, integer, text) from public;
grant execute on function public.record_premium_payment(text, text, integer, text) to service_role;

drop function if exists public.record_premium_payment(text, integer, text);

notify pgrst, 'reload schema';
