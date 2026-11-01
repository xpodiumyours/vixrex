-- R-02 / KVKK-03 (candidate only). Preserve all historic consent records.
-- Publication is a conscious action requested by the store owner and does not
-- itself certify an all-purpose KVKK explicit consent for international transfers.
-- IMPORTANT: deploy only after KVKK Art.9 cross-border legal basis is verified.
CREATE OR REPLACE FUNCTION public.assert_store_legal_acceptance_ready(p_store jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
begin
  if coalesce((p_store ->> 'privacy_notice_acknowledged')::boolean, false) is not true then
    raise exception 'PRIVACY_NOTICE_REQUIRED';
  end if;
  if coalesce((p_store ->> 'terms_accepted')::boolean, false) is not true then
    raise exception 'TERMS_ACCEPTANCE_REQUIRED';
  end if;
  if not exists (
    select 1
    from public.legal_documents d
    where d.document_type = 'privacy'
      and d.is_active = true
      and d.version = p_store ->> 'privacy_notice_version'
      and d.content_hash = p_store ->> 'privacy_notice_hash'
  ) then
    raise exception 'PRIVACY_NOTICE_VERSION_INVALID';
  end if;

  if not exists (
    select 1
    from public.legal_documents d
    where d.document_type = 'terms'
      and d.is_active = true
      and d.version = p_store ->> 'terms_version'
      and d.content_hash = p_store ->> 'terms_hash'
  ) then
    raise exception 'TERMS_VERSION_INVALID';
  end if;

end;
$function$

CREATE OR REPLACE FUNCTION public.accept_store_legal_consent(p_session_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'extensions'
AS $function$
declare
  v_token_hash text;
  v_store_id uuid;
  v_slug text;
  v_is_demo boolean;
  v_privacy_version text;
  v_privacy_hash text;
  v_terms_version text;
  v_terms_hash text;
  v_new_live_version bigint;
begin
  -- 1) Oturum doğrulaması — update_working_draft_field / publish_working_draft
  --    ile birebir aynı. Aynı olması şart: iki uç farklı davranırsa biri
  --    diğerinin kapatmadığı bir yol açar.
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

  -- 2) Yalnız hizmet için gereken aydınlatma ve sözleşme belgelerini oku. Biri eksikse (aktif
  --    işaretlenmemiş/silinmiş) onay veremeyiz — sessizce eski/boş bir
  --    sürüm damgalamak yerine açıkça durur.
  select version, content_hash into v_privacy_version, v_privacy_hash
  from public.legal_documents
  where document_type = 'privacy' and is_active = true
  limit 1;

  select version, content_hash into v_terms_version, v_terms_hash
  from public.legal_documents
  where document_type = 'terms' and is_active = true
  limit 1;

  if v_privacy_version is null or v_terms_version is null then
    raise exception 'LEGAL_DOCUMENT_MISSING';
  end if;

  -- 3) Doğrudan `stores`a yaz (yukarıdaki NEDEN VAR notuna bakın).
  --    trg_validate_store_legal_acceptance ve trg_record_store_legal_events
  --    bu UPDATE üzerinde kendiliğinden çalışır (denetim kaydı burada
  --    tekrarlanmaz) — is_published burada değişmediği için yasal alan
  --    zorunluluğu bu adımda TETİKLENMEZ, yalnız yayınlarken tetiklenir.
  update public.stores
  set privacy_notice_acknowledged = true,
      privacy_notice_acknowledged_at = now(),
      privacy_notice_version = v_privacy_version,
      privacy_notice_hash = v_privacy_hash,
      terms_accepted = true,
      terms_accepted_at = now(),
      terms_version = v_terms_version,
      terms_hash = v_terms_hash
  where id = v_store_id
  returning version into v_new_live_version;

  -- 4) İki yan etki var, ikisi de yerelde tarayıcıda test edilip bulundu
  --    (2026-08-20) — biri arayüz, biri yayınlama engeliydi:
  --
  --    a) Sahip taslağı `get_working_draft_for_session` ile görüyor, o RPC
  --       `stores`i DEĞİL, ilk açılışta alınmış donmuş bir kopyayı
  --       (`store_working_drafts.draft_data`) döner. Yalnız `stores`a
  --       yazmak arayüzde "onay yok" göstermeye devam ediyordu. O kopyayı
  --       da güncelliyoruz — güvenlik notu hâlâ geçerli:
  --       `publish_working_draft` yayınlarken bu üç alanı draft_data'DAN
  --       GERİ OKUMUYOR, yalnız `stores`ın o anki değerine bakıyor; burada
  --       güncellemek eski bir taslağın geri alınmış onayı diriltmesi
  --       riskini AÇMAZ.
  --
  --    b) `trg_stores_bump_version` HER `stores` UPDATE'inde (koşulsuz)
  --       `version`'ı artırıyor — 3. adım bunu tetikledi. Taslağın
  --       `base_live_version`'ı güncellenmezse bir SONRAKİ yayınlama
  --       denemesi `publish_working_draft`'ın DRAFT_STALE kontrolüne
  --       takılıp "vitrin başka yerden değişmiş" diye yanlışça reddederdi
  --       — hiçbir şey gerçekten değişmemişken. `base_live_version`'ı da
  --       eşitliyoruz.
  update public.store_working_drafts
  set draft_data = draft_data || jsonb_build_object(
        'privacy_notice_acknowledged', true,
        'terms_accepted', true
      ),
      base_live_version = coalesce(v_new_live_version, base_live_version),
      updated_at = now()
  where store_id = v_store_id;

  return jsonb_build_object(
    'store_id', v_store_id,
    'slug', v_slug,
    'accepted', true
  );
end;
$function$

-- Permission boundaries remain unchanged for the existing owner-token RPC.
REVOKE ALL ON FUNCTION public.accept_store_legal_consent(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.accept_store_legal_consent(text) TO anon, authenticated;
COMMENT ON FUNCTION public.accept_store_legal_consent(text) IS
  'KVKK-03: records privacy notice acknowledgement and terms acceptance only; preserves older publication consent grants/withdrawals and version/hash histories.';
