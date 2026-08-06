-- Faz 11 — çalışma taslağını yayınla / taslaktan vazgeç.
--
-- implementation_plan.md Commit 11:
--   - Yayınlamada mevcut yasal ve zorunlu alan doğrulamaları çalışır.
--   - Başarılı yayınlama atomiktir.
--   - Başarısız yayınlamada canlı vitrin ve çalışma taslağı KORUNUR.
--   - Vazgeçmede yalnız çalışma taslağı kalkar; canlı veriye dokunulmaz.
--
-- YASAL KONTROL BURADA TEKRARLANMAZ.
-- public.stores üzerinde trg_validate_store_legal_acceptance tetikleyicisi
-- var; is_published true olduğunda PRIVACY_NOTICE_REQUIRED,
-- TERMS_ACCEPTANCE_REQUIRED, PUBLICATION_CONSENT_REQUIRED ve sürüm
-- geçersizliği hatalarını kendisi fırlatır. Fırlattığında fonksiyon
-- gövdesi tek bir işlem olduğu için her şey geri sarar: canlı satır
-- değişmez ve taslak silinmemiş olur. "Başarısızlıkta ikisini de koru"
-- şartı bu yüzden ayrı kodla değil, işlem bütünlüğüyle sağlanır.
--
-- Yasal kontrolü buraya kopyalamak iki ayrı doğruluk kaynağı yaratırdı;
-- biri güncellenip diğeri unutulduğunda onaysız vitrin yayına çıkardı.

-- ────────────────────────────────────────────────────────────────────────
-- Yayınla
-- ────────────────────────────────────────────────────────────────────────
create or replace function public.publish_working_draft(p_session_token text)
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
  v_live_version bigint;
  v_base_live_version bigint;
  v_draft_data jsonb;
  v_guvenli jsonb := '{}'::jsonb;
  v_anahtar text;
  v_kolonlar text;
  v_mevcut jsonb;
begin
  -- 1) Oturum doğrulaması — update_working_draft_field ile birebir aynı.
  --    Aynı olması şart: iki uç farklı davranırsa biri diğerinin
  --    kapatmadığı bir yol açar.
  if p_session_token is null or pg_catalog.length(pg_catalog.btrim(p_session_token)) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  v_token_hash := encode(sha256(pg_catalog.btrim(p_session_token)::bytea), 'hex');

  select s.store_id, st.slug, st.is_demo, st.version
  into v_store_id, v_slug, v_is_demo, v_live_version
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

  -- 2) Taslağı al.
  select draft_data, base_live_version
  into v_draft_data, v_base_live_version
  from public.store_working_drafts
  where store_id = v_store_id;

  if v_draft_data is null then
    raise exception 'WORKING_DRAFT_NOT_FOUND';
  end if;

  -- 3) Çakışma kontrolü. Taslak alındıktan sonra canlı satır başka bir
  --    yoldan değiştiyse (Flutter manuel panel, yönetici düzeltmesi),
  --    yayınlamak o değişikliği sessizce ezerdi.
  if v_live_version is distinct from v_base_live_version then
    raise exception 'DRAFT_STALE';
  end if;

  -- 4) Yalnız yazılabilir sütunları süz.
  --
  --    Çalışma taslağı, mağaza satırının TAM KOPYASIDIR (90 alan). İçinde
  --    id, slug, version, yayın durumu ve yasal onay alanları da bulunur —
  --    bunlar sahibin yazdığı değerler değil, anlık görüntünün parçasıdır.
  --    Bu yüzden yasaklı anahtar görmek bir hata değildir; hata olsaydı
  --    hiçbir taslak yayınlanamazdı.
  --
  --    Kritik olan şu: yasaklı alanlar canlı satıra GERİ YAZILMAZ. Özellikle
  --    yasal onaylar — taslaktan geri yazılabilseydi, eski bir anlık görüntü
  --    geri alınmış bir onayı yeniden geçerli kılabilirdi.
  --
  --    stores'ta karşılığı olmayan anahtar da atlanır: sütun sonradan
  --    kaldırılmışsa eski taslak yüzünden yayınlama tıkanmamalıdır. Sahibin
  --    yazdığı değerler zaten update_working_draft_field'de denetleniyor;
  --    oradan uydurma anahtar geçemez.
  for v_anahtar in select jsonb_object_keys(v_draft_data)
  loop
    if v_anahtar = any (public.owner_forbidden_draft_keys()) then
      continue;
    end if;

    if not exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'stores'
        and column_name = v_anahtar
        and is_generated = 'NEVER'
        and is_updatable = 'YES'
    ) then
      continue;
    end if;

    v_guvenli := v_guvenli || jsonb_build_object(v_anahtar, v_draft_data -> v_anahtar);
  end loop;

  -- 5) Canlı satıra uygula.
  --    Taslak boş olsa bile yayınlama anlamlıdır: "olduğu gibi yayınla".
  if v_guvenli <> '{}'::jsonb then
    -- Sütun listesi yalnız doğrulanmış anahtarlardan kurulur ve %I ile
    -- tırnaklanır; jsonb_populate_record tip dönüşümünü kendisi yapar.
    -- Böylece her sütun tipi için elle dönüşüm yazılmaz.
    select string_agg(format('%I', anahtar), ', ' order by anahtar)
    into v_kolonlar
    from jsonb_object_keys(v_guvenli) as t(anahtar);

    select to_jsonb(st) into v_mevcut from public.stores st where st.id = v_store_id;

    execute format(
      'update public.stores set (%s) = (select %s from jsonb_populate_record(null::public.stores, $1)) where id = $2',
      v_kolonlar, v_kolonlar
    ) using (v_mevcut || v_guvenli), v_store_id;
  end if;

  -- 6) Yayına al. Yasal tetikleyici burada devreye girer; şart
  --    sağlanmazsa exception fırlatır ve 5. adım dahil her şey geri sarar.
  update public.stores
  set is_published = true
  where id = v_store_id;

  -- 7) Taslağı kaldır. Buraya ancak yasal kontrol geçtiyse gelinir.
  delete from public.store_working_drafts where store_id = v_store_id;

  select version into v_live_version from public.stores where id = v_store_id;

  return jsonb_build_object(
    'store_id', v_store_id,
    'slug', v_slug,
    'published', true,
    'live_version', v_live_version
  );
end;
$$;

comment on function public.publish_working_draft is
  'Sahip çalışma taslağını canlı vitrine yayınlar. Yasal onay kontrolü stores tetikleyicisindedir; başarısızlıkta işlem geri sarar ve taslak korunur.';

revoke all on function public.publish_working_draft(text) from public;
grant execute on function public.publish_working_draft(text) to anon, authenticated;

-- ────────────────────────────────────────────────────────────────────────
-- Vazgeç
-- ────────────────────────────────────────────────────────────────────────
create or replace function public.discard_working_draft(p_session_token text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_token_hash text;
  v_store_id uuid;
  v_slug text;
  v_silindi boolean := false;
begin
  if p_session_token is null or pg_catalog.length(pg_catalog.btrim(p_session_token)) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  v_token_hash := encode(sha256(pg_catalog.btrim(p_session_token)::bytea), 'hex');

  select s.store_id, st.slug
  into v_store_id, v_slug
  from public.owner_sessions s
  join public.stores st on st.id = s.store_id
  where s.session_token_hash = v_token_hash
    and s.consumed_at is not null
    and s.expires_at > now();

  if v_store_id is null then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  -- YALNIZ taslak satırı silinir. public.stores'a tek bir yazma yoktur;
  -- "vazgeç" düğmesinin canlı vitrini bozması mümkün olmamalıdır.
  delete from public.store_working_drafts where store_id = v_store_id;
  v_silindi := found;

  return jsonb_build_object(
    'store_id', v_store_id,
    'slug', v_slug,
    'discarded', v_silindi
  );
end;
$$;

comment on function public.discard_working_draft is
  'Sahip çalışma taslağını siler. Canlı vitrine dokunmaz.';

revoke all on function public.discard_working_draft(text) from public;
grant execute on function public.discard_working_draft(text) to anon, authenticated;

notify pgrst, 'reload schema';
