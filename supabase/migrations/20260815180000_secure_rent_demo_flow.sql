-- ============================================================================
-- "Bu vitrini kirala" — güvenlik sınırını tarayıcıdan sunucu+DB'nin arkasına taşı
-- ============================================================================
-- NEDEN VAR
-- Casper (2026-08-15): rent-demo → clone RPC → sınırsız veri üretimi zinciri
-- bulundu. Kanıtlanmış açık:
--   1) GET /api/rent-demo hiçbir kimlik/oran sınırlaması olmadan veritabanı
--      yazıyordu (Next.js route, kimlik kontrolü yok).
--   2) clone_demo_store_as_draft VE create_owner_session `anon` rolüne açıktı
--      — saldırgan Next.js'i tamamen atlayıp herkese açık Supabase anon
--      anahtarıyla RPC'yi doğrudan çağırabilir, kendi edit_token'ını seçip
--      tam kontrollü sınırsız kopya üretebilirdi.
--   3) clone_demo_store_as_draft artık yalnız stores değil, product_categories
--      ve products'ı da kopyalıyor (20260815000000) — saldırı maliyeti büyüdü.
--   4) cleanup_expired_trial_clones hiç `revoke` almamıştı; yorum "anon'a
--      yetki verilmez" diyordu ama PostgreSQL'de yeni fonksiyonlara varsayılan
--      olarak PUBLIC execute yetkisi verilir — bu iddia doğrulanmamış bir
--      varsayımdı, gerçekte açık olabilirdi.
--
-- NE YAPAR
--   A) consume_assistant_request'i genelleştirir (p_window_seconds eklenir,
--      varsayılan 60 — mevcut çağıran hiç etkilenmez). rent_demo limitleri
--      için İKİNCİ bir tablo/fonksiyon AÇMAZ, var olan assistant_rate_limits
--      deseni yeniden kullanılır.
--   B) start_demo_trial(): tek giriş noktası. Sırayla: 3 katmanlı oran
--      sınırı → kaynağı doğrula → slug/token üret (çakışmada içeride retry)
--      → clone_demo_store_as_draft → _create_owner_session_core. Hepsi TEK
--      fonksiyon çağrısı = TEK transaction; ara adım başarısız olursa hiçbir
--      şey commit edilmez (önceki iki-RPC zincirinde ikinci adım
--      başarısız olursa sahipsiz bir klon kalıyordu — artık kalmaz).
--   C) clone_demo_store_as_draft, cleanup_expired_trial_clones: anon/
--      authenticated/PUBLIC'ten yetki açıkça çekilir. start_demo_trial
--      yalnız service_role'e açılır — yalnız sunucu tarafı (Next.js API
--      route, service-role anahtarıyla) çağırabilir.
--
-- DOKUNULMAYAN
--   create_owner_session / create_owner_session_with_handoff: anon'a açık
--   kalır — BAŞKA bir amaç için var (kendi vitrinine edit_token'ıyla geri
--   dönme, bkz. owner_preview_service.dart). Orada çağıran zaten geçerli bir
--   mağazanın gizli edit_token'ını bilmek zorunda — rent-demo'daki "bedava
--   sınırsız yeni satır" riskiyle aynı kategori değil, bilerek dokunulmadı.
-- ============================================================================

-- ── A) Rate-limit fonksiyonunu genelleştir ─────────────────────────────────
-- Eski çağıranlar (vixrex-assistant-nlu Edge Function) p_window_seconds
-- geçmiyor, varsayılan 60 ile eski davranışı birebir korur.
create or replace function public.consume_assistant_request(
  p_client_key text,
  p_max_requests integer default 6,
  p_window_seconds integer default 60
)
returns table("allowed" boolean, "retry_after_seconds" integer)
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_window_started_at timestamptz;
  v_request_count integer;
  v_window interval := make_interval(secs => p_window_seconds);
begin
  insert into public.assistant_rate_limits as limits (
    client_key,
    window_started_at,
    request_count,
    updated_at
  )
  values (p_client_key, now(), 1, now())
  on conflict (client_key) do update
  set
    window_started_at = case
      when limits.window_started_at <= now() - v_window then now()
      else limits.window_started_at
    end,
    request_count = case
      when limits.window_started_at <= now() - v_window then 1
      else limits.request_count + 1
    end,
    updated_at = now()
  returning window_started_at, request_count
  into v_window_started_at, v_request_count;

  return query select
    v_request_count <= p_max_requests,
    greatest(
      0,
      ceil(extract(epoch from (v_window_started_at + v_window - now())))::integer
    );
end;
$$;

comment on function public.consume_assistant_request(text, integer, integer) is
  'Kayan pencereli genel amaçlı oran sınırlayıcı. p_window_seconds varsayılan
   60 — eski çağıranlar (vixrex-assistant-nlu) etkilenmez. start_demo_trial
   bunu 3 farklı pencere/anahtar ile 3 kez çağırarak katmanlı limit uygular,
   ikinci bir rate-limit tablosu açmaz.';

-- client_key farklı önekler taşıyabildiği için (assistant: ham client_key,
-- rent_demo: 'rent_demo:ip:'/'rent_demo:global' önekli) satır sayısı
-- büyüyebilir — eski satırları temizlemek cleanup_expired_trial_clones'un
-- işi değil, ayrı ve düşük öncelikli bir iş; burada kapsam dışı bırakıldı.

-- ── B) Tek giriş noktası: start_demo_trial ─────────────────────────────────
create or replace function public.start_demo_trial(
  p_source_slug text,
  p_client_key text
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
begin
  if v_source_slug = '' then
    raise exception 'INVALID_SLUG';
  end if;
  if v_client_key = '' then
    raise exception 'INVALID_CLIENT_KEY';
  end if;

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

  -- Katman 3: TÜM Vixrex, saatlik — IP değiştiren bot bile bu duvara çarpar.
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

comment on function public.start_demo_trial(text, text) is
  '"Bu vitrini kirala" — TEK güvenli giriş noktası. Oran sınırı + klonlama +
   sahip oturumu tek transaction''da. Yalnız service_role çağırabilir; anon/
   authenticated/PUBLIC''e KAPALI — /api/rent-demo dışında dışarıdan
   tetiklenemez.';

revoke execute on function public.start_demo_trial(text, text)
  from public, anon, authenticated;
grant execute on function public.start_demo_trial(text, text)
  to service_role;

-- ── C) Eski dolaylı yolları kapat ──────────────────────────────────────────
-- clone_demo_store_as_draft artık yalnız start_demo_trial içinden (aynı
-- transaction, owner rolüyle) çağrılır — dışarıdan tetiklenemez.
revoke execute on function public.clone_demo_store_as_draft(text, text, text)
  from public, anon, authenticated;

-- cleanup_expired_trial_clones: önceki migration'da hiç `revoke` almamıştı,
-- yorumdaki "yetki verilmez" iddiası doğrulanmamıştı. Şimdi açıkça kapatılıyor.
revoke execute on function public.cleanup_expired_trial_clones()
  from public, anon, authenticated;
