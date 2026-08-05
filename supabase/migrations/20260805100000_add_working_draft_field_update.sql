-- Commit 8: sahip çalışma taslağında tek alan güncelleme.
--
-- Doğrulama (tip, uzunluk, biçim) TypeScript tarafındadır:
--   public_web/src/lib/vitrinFieldSchema.ts + vitrinFieldValidation.ts
-- Kuralları iki dile kopyalamamak için burada tekrar edilmez.
--
-- Fakat veritabanı KENDİ BAĞIMSIZ yetki kontrolünü yapar. Sunucu katmanı
-- atlansa veya bir hata olsa bile buradan edit_token, user_id, yayın durumu
-- veya yasal onay alanlarına yazılamaz. Savunma iki katmanlıdır.

-- Sahibin ASLA yazamayacağı alanlar (docs/vitrin-alan-semasi.md §7).
create or replace function public.owner_forbidden_draft_keys()
returns text[]
language sql
immutable
set search_path = pg_catalog, public
as $$
  select array[
    'id', 'slug', 'edit_token', 'user_id',
    'is_published', 'status', 'published_at',
    'is_demo', 'is_premium', 'premium_plan', 'premium_expires_at',
    'version', 'created_at', 'updated_at',
    'rating_score', 'review_count',
    'is_blog_trusted',
    'location_source', 'location_accuracy_meters', 'location_consent_at',
    'privacy_notice_acknowledged', 'privacy_notice_acknowledged_at',
    'privacy_notice_version', 'privacy_notice_hash',
    'terms_accepted', 'terms_accepted_at', 'terms_version', 'terms_hash',
    'publication_consent_accepted', 'publication_consent_accepted_at',
    'publication_consent_withdrawn_at', 'publication_consent_version',
    'publication_consent_hash',
    'product_storage_version'
  ]::text[];
$$;

comment on function public.owner_forbidden_draft_keys is
  'Sahibin çalışma taslağında değiştiremeyeceği alanlar. Yetki, yayın durumu, yasal onay ve sistem alanları.';

-- Tek alan güncelle. p_value jsonb'dir; null gönderilirse alan temizlenir.
create or replace function public.update_working_draft_field(
  p_session_token text,
  p_key text,
  p_value jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_token_hash text;
  v_store_id uuid;
  v_slug text;
  v_is_demo boolean;
  v_key text := pg_catalog.btrim(coalesce(p_key, ''));
  v_draft_version bigint;
begin
  -- 1) Oturum doğrulaması — okuma yoluyla birebir aynı.
  if p_session_token is null or pg_catalog.length(pg_catalog.btrim(p_session_token)) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  v_token_hash := encode(sha256(pg_catalog.btrim(p_session_token)::bytea), 'hex');

  select s.store_id, st.slug, st.is_demo
  into v_store_id, v_slug, v_is_demo
  from public.owner_sessions s
  join public.stores st on st.id = s.store_id
  where s.session_token_hash = v_token_hash
    and s.consumed_at is not null
    and s.expires_at > now();

  if v_store_id is null then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE';
  end if;

  -- 2) Alan adı kontrolü — bağımsız izin listesi.
  if v_key = '' then
    raise exception 'INVALID_FIELD_KEY';
  end if;

  if v_key = any (public.owner_forbidden_draft_keys()) then
    raise exception 'FIELD_NOT_EDITABLE';
  end if;

  -- Alan gerçekten stores tablosunda var mı? Uydurma anahtar taslağa
  -- yazılamaz; yayınlama sırasında karşılığı olmayan veri oluşmaz.
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'stores' and column_name = v_key
  ) then
    raise exception 'UNKNOWN_FIELD';
  end if;

  -- 3) Taslak yoksa hata ver — taslak get_working_draft_for_session ile
  --    oluşturulur. Buradan taslak yaratmak sessiz yan etki olurdu.
  select draft_version into v_draft_version
  from public.store_working_drafts
  where store_id = v_store_id;

  if v_draft_version is null then
    raise exception 'WORKING_DRAFT_NOT_FOUND';
  end if;

  -- 4) Yaz.
  update public.store_working_drafts
  set draft_data = case
        when p_value is null or jsonb_typeof(p_value) = 'null'
          then draft_data - v_key
        else draft_data || jsonb_build_object(v_key, p_value)
      end,
      draft_version = draft_version + 1,
      updated_at = now()
  where store_id = v_store_id;

  return jsonb_build_object(
    'store_id', v_store_id,
    'slug', v_slug,
    'key', v_key,
    'draft_version', v_draft_version + 1
  );
end;
$$;

comment on function public.update_working_draft_field is
  'Sahip çalışma taslağında tek alan günceller. Oturum tokenıyla yetkilendirir, yasak alanları reddeder. Tip/uzunluk doğrulaması TypeScript tarafındadır.';

revoke all on function public.update_working_draft_field(text, text, jsonb) from public;
grant execute on function public.update_working_draft_field(text, text, jsonb) to anon, authenticated;

notify pgrst, 'reload schema';
