-- Faz F (Tek Asistan planı, 2026-09-02) — geliştirme modu: WhatsApp/telefon/
-- konum tıklamaları ve ürün görüntülemeleri bugüne kadar yalnız Google
-- Analytics'e gidiyordu (TrackedWhatsAppLink/TrackedContactLink — yalnız
-- gtag()), Supabase'de hiç yoktu. Asistan bunu okuyamazdı. Aynı desen:
-- record_vitrin_view / vitrin_views (session_key>=16, is_published=true).

create table if not exists public.vitrin_engagement_events (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  event_type text not null check (
    event_type in ('whatsapp_click', 'phone_click', 'directions_click', 'product_view')
  ),
  product_id uuid references public.products(id) on delete set null,
  session_key text not null check (pg_catalog.length(pg_catalog.btrim(session_key)) >= 16),
  created_at timestamptz not null default now()
);

create index if not exists idx_vitrin_engagement_events_store_created
  on public.vitrin_engagement_events (store_id, created_at desc);

comment on table public.vitrin_engagement_events is
  'WhatsApp/telefon/konum tıklamaları + ürün görüntülemeleri — Faz F geliştirme
   modu için. GA''ya giden gtag() çağrılarının yanına, çift yazım olarak eklendi.';

-- ── Yazma: herkese açık, session_key + yayında olan mağaza şartıyla ────────
create or replace function public.record_vitrin_engagement(
  p_store_slug text,
  p_event_type text,
  p_session_key text,
  p_product_slug text default null
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_store_id uuid;
  v_session_key text := pg_catalog.btrim(coalesce(p_session_key, ''));
  v_event_type text := lower(pg_catalog.btrim(coalesce(p_event_type, '')));
  v_product_id uuid;
begin
  if pg_catalog.length(v_session_key) < 16 then
    return;
  end if;
  if v_event_type not in ('whatsapp_click', 'phone_click', 'directions_click', 'product_view') then
    return;
  end if;

  select id into v_store_id
  from public.stores
  where slug = pg_catalog.btrim(coalesce(p_store_slug, ''))
    and is_published = true
  limit 1;

  if v_store_id is null then
    return;
  end if;

  if p_product_slug is not null then
    select id into v_product_id
    from public.products
    where store_id = v_store_id and slug = pg_catalog.btrim(p_product_slug)
    limit 1;
  end if;

  insert into public.vitrin_engagement_events (store_id, event_type, product_id, session_key)
  values (v_store_id, v_event_type, v_product_id, v_session_key);
end;
$$;

revoke all on function public.record_vitrin_engagement(text, text, text, text) from public;
grant execute on function public.record_vitrin_engagement(text, text, text, text) to anon, authenticated;

comment on function public.record_vitrin_engagement(text, text, text, text) is
  'Tıklama/görüntüleme olayı kaydeder. record_vitrin_view ile aynı güvenlik
   deseni: yalnız yayında olan mağaza, session_key>=16, ham veri döndürmez.';

-- ── Okuma: yalnız sahip, sahip oturum token''ıyla (get_working_draft_for_
-- session ile aynı desen) — haftalık özet.
create or replace function public.get_haftalik_performans(p_session_token text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_token text := pg_catalog.btrim(coalesce(p_session_token, ''));
  v_token_hash text;
  v_store_id uuid;
  v_baslangic timestamptz := now() - interval '7 days';
  v_goruntuleme_baslangic date := ((now() at time zone 'Europe/Istanbul')::date) - 7;
begin
  if pg_catalog.length(v_token) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;
  v_token_hash := encode(sha256(v_token::bytea), 'hex');

  select s.store_id into v_store_id
  from public.owner_sessions s
  where s.session_token_hash = v_token_hash
    and s.consumed_at is not null
    and s.expires_at > now();

  if v_store_id is null then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  return jsonb_build_object(
    'goruntuleme', (
      select count(*) from public.vitrin_views
      where store_id = v_store_id and viewed_date >= v_goruntuleme_baslangic
    ),
    'whatsapp_tiklama', (
      select count(*) from public.vitrin_engagement_events
      where store_id = v_store_id and event_type = 'whatsapp_click' and created_at >= v_baslangic
    ),
    'telefon_tiklama', (
      select count(*) from public.vitrin_engagement_events
      where store_id = v_store_id and event_type = 'phone_click' and created_at >= v_baslangic
    ),
    'konum_tiklama', (
      select count(*) from public.vitrin_engagement_events
      where store_id = v_store_id and event_type = 'directions_click' and created_at >= v_baslangic
    ),
    'en_cok_goruntulenen_urun', (
      select p.name
      from public.vitrin_engagement_events e
      join public.products p on p.id = e.product_id
      where e.store_id = v_store_id and e.event_type = 'product_view' and e.created_at >= v_baslangic
      group by p.id, p.name
      order by count(*) desc
      limit 1
    )
  );
end;
$$;

revoke all on function public.get_haftalik_performans(text) from public;
grant execute on function public.get_haftalik_performans(text) to anon, authenticated;

comment on function public.get_haftalik_performans(text) is
  'Faz F: son 7 günün görüntüleme/tıklama özeti. get_working_draft_for_session
   ile aynı sahip-oturum doğrulaması — yalnız vitrinin sahibi okuyabilir.';

notify pgrst, 'reload schema';
