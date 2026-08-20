-- Sahip oturumundan yasal onay — Vixrex Asistan (Next.js) için.
--
-- NEDEN VAR
-- `publish_working_draft` yayınlarken gizlilik/şartlar/yayın izni onayını
-- ZORUNLU kılıyor (trg_validate_store_legal_acceptance, stores tetikleyicisi)
-- ama onu VERECEK bir yol yalnız Flutter'daki üyelik panelinde vardı
-- (owner-publish/route.ts'teki HATA_METNI: "Bu onay üyelik panelinden
-- verilir"). Kiralık şablon üzerinden gelen sahip, Next.js'ten hiç
-- çıkmadan yayınlayamıyordu.
--
-- Bu fonksiyon `owner_forbidden_draft_keys()` listesine veya genel taslak
-- alan düzenleme yoluna (`update_working_draft_field`) DOKUNMAZ — yasal
-- alanlar o listede kalmaya devam eder (docs/vitrin-alan-semasi.md §7).
-- Onay, `publish_working_draft`'ın `is_published`'i değiştirmesiyle aynı
-- desende: genel düzenlemeye kapalı bir alan için amaca özel, dar bir
-- fonksiyon. `publish_working_draft`'ın taslağı canlıya yazarken yasaklı
-- anahtarları BİLEREK atladığını unutma (eski bir taslak anlık görüntüsü
-- geri alınmış bir onayı diriltmesin diye) — bu yüzden onay
-- `store_working_drafts`'a değil, doğrudan `stores`'a yazılır; aksi halde
-- publish_working_draft bu yazımı sessizce yok sayardı.
--
-- Sürüm/hash istemciden ALINMAZ — `legal_documents`'taki AKTİF sürüm
-- burada sunucu tarafında okunur. Flutter tarafı (StoreLegalStampingService)
-- aynı satırları istemcide okuyup damgalıyor; burada sunucu tarafında aynı
-- işi tek adımda yapıyoruz, ayrıca güvenli.
--
-- Üç onay (gizlilik/şartlar/yayın izni) TEK çağrıda birlikte verilir —
-- Flutter'daki LegalConsentSection de tek ana onay kutusu, ayrı ayrı
-- sorulmuyor (lib/widgets/editor/legal_consent_section.dart).
--
-- Geri çekme (withdraw) burada YOK — kapsam dışı, mevcut
-- withdraw_store_publication_consent RPC'si (Flutter) değişmedi.

create or replace function public.accept_store_legal_consent(p_session_token text)
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
  v_privacy_version text;
  v_privacy_hash text;
  v_terms_version text;
  v_terms_hash text;
  v_consent_version text;
  v_consent_hash text;
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

  -- 2) Aktif yasal belgeleri sunucu tarafında oku. Biri eksikse (aktif
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

  select version, content_hash into v_consent_version, v_consent_hash
  from public.legal_documents
  where document_type = 'consent' and is_active = true
  limit 1;

  if v_privacy_version is null or v_terms_version is null or v_consent_version is null then
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
      terms_hash = v_terms_hash,
      publication_consent_accepted = true,
      publication_consent_accepted_at = now(),
      publication_consent_withdrawn_at = null,
      publication_consent_version = v_consent_version,
      publication_consent_hash = v_consent_hash
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
        'terms_accepted', true,
        'publication_consent_accepted', true
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
$$;

comment on function public.accept_store_legal_consent is
  'Sahip oturumundan gizlilik/şartlar/yayın izni onayını doğrudan stores satırına yazar (Vixrex Asistan). Sürüm/hash sunucu tarafında aktif legal_documents''tan okunur, istemciden alınmaz. Genel taslak alan düzenlemesine (owner_forbidden_draft_keys) dokunmaz.';

revoke all on function public.accept_store_legal_consent(text) from public;
grant execute on function public.accept_store_legal_consent(text) to anon, authenticated;

notify pgrst, 'reload schema';
