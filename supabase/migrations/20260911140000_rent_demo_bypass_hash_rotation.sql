create or replace function public.vixrex_rent_demo_bypass_hashes()
returns text[]
language sql
immutable
set search_path = pg_catalog, public
as $$
  select array[
    '350033cd5859723394067a03210377a3668f95b33ffc708974d9456aee1a84c6',
    '8340515c3f769a2ecd3639c58fee81c54e7219b86e25731e706b73e935bc361a'
  ]::text[];
$$;

revoke execute on function public.vixrex_rent_demo_bypass_hashes() from public, anon, authenticated;

create or replace function public.start_demo_trial(
  p_source_slug text,
  p_client_key text,
  p_bypass_secret text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_source_slug text := pg_catalog.btrim(coalesce(p_source_slug, ''));
  v_client_key text := pg_catalog.btrim(coalesce(p_client_key, ''));
  v_new_slug text;
  v_edit_token text;
  v_attempt integer := 0;
  v_cloned boolean := false;
  v_allowed boolean;
  v_retry_after integer;
  v_session jsonb;
  v_bypass boolean := false;
begin
  if v_source_slug = '' then
    raise exception 'INVALID_SLUG';
  end if;
  if v_client_key = '' then
    raise exception 'INVALID_CLIENT_KEY';
  end if;

  if p_bypass_secret is not null
     and pg_catalog.length(p_bypass_secret) > 0
     and encode(sha256(p_bypass_secret::bytea), 'hex')
       = any (public.vixrex_rent_demo_bypass_hashes())
  then
    v_bypass := true;
  end if;

  if not v_bypass then
    -- Katman 1: aynı IP, kısa pencere — hızlı bot patlamasını durdurur.
    select allowed, retry_after_seconds
    into v_allowed, v_retry_after
    from public.consume_assistant_request(
      'rent_demo:ip:short:' || v_client_key, 3, 600
    );
    if not v_allowed then
      raise exception 'RATE_LIMITED'
        using errcode = 'P0001', detail = v_retry_after::text;
    end if;

    -- Katman 2: aynı IP, günlük pencere — yavaş/dağıtık denemeyi durdurur.
    select allowed, retry_after_seconds
    into v_allowed, v_retry_after
    from public.consume_assistant_request(
      'rent_demo:ip:day:' || v_client_key, 10, 86400
    );
    if not v_allowed then
      raise exception 'RATE_LIMITED'
        using errcode = 'P0001', detail = v_retry_after::text;
    end if;
  end if;

  -- Katman 3: TÜM Vixrex, saatlik — bypass'tan MUAF DEĞİL, IP değiştiren
  -- bot (veya sızmış iç sır) bile bu duvara çarpar.
  select allowed, retry_after_seconds
  into v_allowed, v_retry_after
  from public.consume_assistant_request(
    'rent_demo:global', 100, 3600
  );
  if not v_allowed then
    raise exception 'RATE_LIMITED'
      using errcode = 'P0001', detail = v_retry_after::text;
  end if;

  -- Kaynağın gerçekten kiralanabilir bir demo olduğunu erkenden doğrula —
  -- clone_demo_store_as_draft da aynı kontrolü yapar ama burada erken
  -- başarısız olmak slug/token üretimini boşa harcamayı önler.
  if not exists (
    select 1 from public.stores
    where slug = v_source_slug and is_demo = true and is_published = true
  ) then
    raise exception 'SOURCE_NOT_FOUND';
  end if;

  -- Slug çakışması (astronomik derecede düşük ama olabilir) — DB içinde
  -- retry. Önceki Node.js tarafındaki 2-denemelik döngüyle aynı üst sınır.
  while not v_cloned and v_attempt < 3 loop
    v_attempt := v_attempt + 1;
    v_new_slug := v_source_slug || '-' || encode(gen_random_bytes(4), 'hex');
    v_edit_token := encode(gen_random_bytes(32), 'hex');

    begin
      perform public.clone_demo_store_as_draft(
        v_source_slug, v_new_slug, v_edit_token
      );
      v_cloned := true;
    exception
      when unique_violation then
        if v_attempt >= 3 then
          raise exception 'SLUG_GENERATION_FAILED';
        end if;
        -- döngü devam eder, yeni slug denenir
    end;
  end loop;

  -- Klonlama başarılıysa oturum açılışı AYNI transaction'da — başarısız
  -- olursa yukarıdaki INSERT'ler de geri alınır, sahipsiz klon kalmaz.
  v_session := public._create_owner_session_core(v_new_slug, v_edit_token, null::jsonb);

  return jsonb_build_object(
    'slug', v_new_slug,
    'code', v_session ->> 'code',
    'expires_at', v_session -> 'expires_at'
  );
end;
$$;

comment on function public.start_demo_trial(text, text, text) is
  '"Bu vitrini kirala" — TEK güvenli giriş noktası. Oran sınırı + klonlama +
   sahip oturumu tek transaction''da. Yalnız service_role çağırabilir; anon/
   authenticated/PUBLIC''e KAPALI. p_bypass_secret yalnız iç test trafiği
   için — Katman 3 (global saatlik) ondan muaf değildir.';

revoke execute on function public.start_demo_trial(text, text, text)
  from public, anon, authenticated;
grant execute on function public.start_demo_trial(text, text, text)
  to service_role;

notify pgrst, 'reload schema';
