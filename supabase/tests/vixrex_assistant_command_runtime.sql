-- Vixrex Assistant command/undo gerçek DB kabul testi.
--
-- AMAÇ
--   Production'a dokunmadan, production migration zincirinden oluşturulmuş
--   izole bir Supabase development branch üzerinde çalıştırılmak içindir.
--   Test kendi sahte store/session/draft verisini üretir ve SONDA ROLLBACK yapar.
--
-- KAPSAM
--   1) Çok alan tek atomik command / tek draft_version artışı
--   2) Audit + undo receipt oluşması
--   3) Aynı command + aynı payload idempotent replay
--   4) Aynı command + farklı payload reddi
--   5) Geçersiz değer ve 46-alan dışı kolon fail-closed
--   6) Command bazlı gerçek undo + tekrar undo replay
--   7) Eski/stale undo yeni değişikliği ezemez
--   8) Başka store'un session'ı başka store command'ını undo edemez
--
-- ÇALIŞTIRMA
--   psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 \
--     -f supabase/tests/vixrex_assistant_command_runtime.sql
--
-- NOT: Bu dosya migration değildir. Şema değiştirmez.

begin;

-- Test başlamadan önce gerekli PR migrationlarının gerçekten uygulanmış
-- olduğunu kanıtla. Eksikse yanlış-pozitif üretmek yerine hemen kırmızı.
do $$
begin
  if to_regprocedure('public.apply_working_draft_command(text,uuid,jsonb)') is null then
    raise exception 'TEST_PREREQUISITE_MISSING: apply_working_draft_command';
  end if;
  if to_regprocedure('public.undo_working_draft_command(text,uuid)') is null then
    raise exception 'TEST_PREREQUISITE_MISSING: undo_working_draft_command';
  end if;
  if to_regprocedure('public.vixrex_validate_assistant_draft_changes(jsonb)') is null then
    raise exception 'TEST_PREREQUISITE_MISSING: vixrex_validate_assistant_draft_changes';
  end if;
  if to_regclass('public.owner_draft_undo_operations') is null then
    raise exception 'TEST_PREREQUISITE_MISSING: owner_draft_undo_operations';
  end if;
end;
$$;

do $$
declare
  v_store_a uuid := gen_random_uuid();
  v_store_b uuid := gen_random_uuid();
  v_session_a uuid := gen_random_uuid();
  v_session_b uuid := gen_random_uuid();
  v_token_a text := repeat('a', 64);
  v_token_b text := repeat('b', 64);

  v_command_1 uuid := gen_random_uuid();
  v_command_2 uuid := gen_random_uuid();
  v_command_3 uuid := gen_random_uuid();
  v_invalid_command uuid := gen_random_uuid();
  v_result jsonb;
  v_data jsonb;
  v_version bigint;
  v_count integer;
  v_before_phone text;
  v_before_email text;
begin
  -- İki tamamen sahte vitrin. user_id NULL: test auth.users'a dokunmaz.
  insert into public.stores (
    id, slug, name, whatsapp, address, kategori,
    province_name, district_name, version, is_demo
  ) values
    (
      v_store_a,
      'assistant-runtime-a-' || substr(replace(v_store_a::text, '-', ''), 1, 10),
      'Eski A', '905321112233', 'Atatürk Cad. No:24', 'Teknik Servis',
      'İstanbul', 'Kadıköy', 1, false
    ),
    (
      v_store_b,
      'assistant-runtime-b-' || substr(replace(v_store_b::text, '-', ''), 1, 10),
      'Eski B', '905329998877', 'İnönü Cad. No:12', 'Kafe / Lokanta',
      'İstanbul', 'Beşiktaş', 1, false
    );

  insert into public.store_working_drafts (
    store_id, draft_data, draft_version, base_live_version
  ) values
    (
      v_store_a,
      jsonb_build_object(
        'name', 'Eski A',
        'phone', '02121112233',
        'email', 'eski-a@example.com',
        'whatsapp', '905321112233',
        'address', 'Atatürk Cad. No:24',
        'kategori', 'Teknik Servis'
      ),
      5,
      1
    ),
    (
      v_store_b,
      jsonb_build_object(
        'name', 'Eski B',
        'phone', '02129998877',
        'email', 'eski-b@example.com',
        'whatsapp', '905329998877',
        'address', 'İnönü Cad. No:12',
        'kategori', 'Kafe / Lokanta'
      ),
      5,
      1
    );

  insert into public.owner_sessions (
    id, store_id, code_hash, expires_at, consumed_at, session_token_hash
  ) values
    (
      v_session_a,
      v_store_a,
      'assistant-runtime-code-a',
      now() + interval '1 hour',
      now(),
      encode(sha256(v_token_a::bytea), 'hex')
    ),
    (
      v_session_b,
      v_store_b,
      'assistant-runtime-code-b',
      now() + interval '1 hour',
      now(),
      encode(sha256(v_token_b::bytea), 'hex')
    );

  -- 1) İki alan tek command: iki ayrı değişiklik ama tek version artışı.
  v_result := public.apply_working_draft_command(
    v_token_a,
    v_command_1,
    jsonb_build_object(
      'phone', '02125554433',
      'email', 'yeni-a@example.com'
    )
  );

  if coalesce((v_result ->> 'replayed')::boolean, true) then
    raise exception 'TEST_FAIL: ilk command replayed olmamalı';
  end if;
  if (v_result ->> 'changed_count')::int <> 2 then
    raise exception 'TEST_FAIL: changed_count=2 bekleniyordu, gelen=%', v_result ->> 'changed_count';
  end if;
  if (v_result ->> 'draft_version')::bigint <> 6 then
    raise exception 'TEST_FAIL: çok alan command tek version artırmalı, gelen=%', v_result ->> 'draft_version';
  end if;

  select draft_data, draft_version into v_data, v_version
  from public.store_working_drafts where store_id = v_store_a;

  if v_version <> 6
     or v_data ->> 'phone' <> '02125554433'
     or v_data ->> 'email' <> 'yeni-a@example.com'
     or v_data ->> 'name' <> 'Eski A' then
    raise exception 'TEST_FAIL: atomik command beklenen draftı üretmedi: version=%, data=%', v_version, v_data;
  end if;

  select count(*) into v_count
  from public.audit_logs
  where action = 'vixrex_assistant_storefront_command'
    and target_id = v_store_a::text
    and metadata ->> 'command_id' = v_command_1::text;
  if v_count <> 1 then
    raise exception 'TEST_FAIL: command audit receipt sayısı 1 olmalı, gelen=%', v_count;
  end if;

  select count(*) into v_count
  from public.owner_draft_undo_operations
  where store_id = v_store_a and command_id = v_command_1;
  if v_count <> 1 then
    raise exception 'TEST_FAIL: command undo receipt sayısı 1 olmalı, gelen=%', v_count;
  end if;

  -- 2) Aynı command + aynı payload: yeniden yazma YOK.
  v_result := public.apply_working_draft_command(
    v_token_a,
    v_command_1,
    jsonb_build_object(
      'phone', '02125554433',
      'email', 'yeni-a@example.com'
    )
  );
  if not coalesce((v_result ->> 'replayed')::boolean, false) then
    raise exception 'TEST_FAIL: aynı command replayed=true dönmeli';
  end if;
  select draft_version into v_version
  from public.store_working_drafts where store_id = v_store_a;
  if v_version <> 6 then
    raise exception 'TEST_FAIL: replay version artırdı, gelen=%', v_version;
  end if;

  select count(*) into v_count
  from public.audit_logs
  where action = 'vixrex_assistant_storefront_command'
    and target_id = v_store_a::text
    and metadata ->> 'command_id' = v_command_1::text;
  if v_count <> 1 then
    raise exception 'TEST_FAIL: replay ikinci audit receipt üretti';
  end if;

  -- 3) Aynı commandId farklı payload ile kullanılamaz.
  begin
    perform public.apply_working_draft_command(
      v_token_a,
      v_command_1,
      jsonb_build_object('phone', '02126667788')
    );
    raise exception 'TEST_SENTINEL: IDEMPOTENCY_KEY_REUSE bekleniyordu';
  exception when others then
    if sqlerrm like 'TEST_SENTINEL:%' then raise; end if;
    if sqlerrm <> 'IDEMPOTENCY_KEY_REUSE' then
      raise exception 'TEST_FAIL: IDEMPOTENCY_KEY_REUSE yerine %', sqlerrm;
    end if;
  end;

  -- 4) Tek command içinde bir değer bozuksa geçerli alan da KISMİ yazılamaz.
  select draft_data ->> 'phone', draft_data ->> 'email', draft_version
  into v_before_phone, v_before_email, v_version
  from public.store_working_drafts where store_id = v_store_a;

  begin
    perform public.apply_working_draft_command(
      v_token_a,
      v_invalid_command,
      jsonb_build_object(
        'phone', '02123334455',
        'whatsapp', '123'
      )
    );
    raise exception 'TEST_SENTINEL: INVALID_FIELD_VALUE bekleniyordu';
  exception when others then
    if sqlerrm like 'TEST_SENTINEL:%' then raise; end if;
    if sqlerrm <> 'INVALID_FIELD_VALUE' then
      raise exception 'TEST_FAIL: bozuk WhatsApp için INVALID_FIELD_VALUE yerine %', sqlerrm;
    end if;
  end;

  select draft_data, draft_version into v_data, v_count
  from public.store_working_drafts where store_id = v_store_a;
  if v_count <> v_version
     or v_data ->> 'phone' <> v_before_phone
     or v_data ->> 'email' <> v_before_email then
    raise exception 'TEST_FAIL: geçersiz çoklu command kısmi veri yazdı';
  end if;

  -- Aynı DB kapısı koordinat ve URL tipini de doğrudan korumalı.
  begin
    perform public.apply_working_draft_command(
      v_token_a,
      gen_random_uuid(),
      jsonb_build_object('latitude', 91)
    );
    raise exception 'TEST_SENTINEL: latitude 91 reddedilmeliydi';
  exception when others then
    if sqlerrm like 'TEST_SENTINEL:%' then raise; end if;
    if sqlerrm <> 'INVALID_FIELD_VALUE' then
      raise exception 'TEST_FAIL: latitude 91 için beklenmeyen hata=%', sqlerrm;
    end if;
  end;

  begin
    perform public.apply_working_draft_command(
      v_token_a,
      gen_random_uuid(),
      jsonb_build_object('website', '#sahte-capa')
    );
    raise exception 'TEST_SENTINEL: website # çapa reddedilmeliydi';
  exception when others then
    if sqlerrm like 'TEST_SENTINEL:%' then raise; end if;
    if sqlerrm <> 'INVALID_FIELD_VALUE' then
      raise exception 'TEST_FAIL: website çapa için beklenmeyen hata=%', sqlerrm;
    end if;
  end;

  -- 5) Assistant 46 alanı dışındaki stores kolonu yazılamaz.
  begin
    perform public.apply_working_draft_command(
      v_token_a,
      gen_random_uuid(),
      jsonb_build_object('status', 'Kapalı')
    );
    raise exception 'TEST_SENTINEL: status Assistant alanı değildir';
  exception when others then
    if sqlerrm like 'TEST_SENTINEL:%' then raise; end if;
    if sqlerrm <> 'FIELD_NOT_EDITABLE' then
      raise exception 'TEST_FAIL: status için FIELD_NOT_EDITABLE yerine %', sqlerrm;
    end if;
  end;

  -- Tüm reddedilen denemeler draftı değiştirmemiş olmalı.
  select draft_version into v_version
  from public.store_working_drafts where store_id = v_store_a;
  if v_version <> 6 then
    raise exception 'TEST_FAIL: reddedilen command version değiştirdi, gelen=%', v_version;
  end if;

  -- 6) Exact command undo, command_1 öncesindeki iki değeri birlikte geri alır.
  v_result := public.undo_working_draft_command(v_token_a, v_command_1);
  if coalesce((v_result ->> 'replayed')::boolean, true) then
    raise exception 'TEST_FAIL: ilk undo replayed olmamalı';
  end if;

  select draft_data, draft_version into v_data, v_version
  from public.store_working_drafts where store_id = v_store_a;
  if v_version <> 7
     or v_data ->> 'phone' <> '02121112233'
     or v_data ->> 'email' <> 'eski-a@example.com' then
    raise exception 'TEST_FAIL: undo önceki taslağı doğru geri getirmedi: version=%, data=%', v_version, v_data;
  end if;

  -- Aynı undo ikinci kez veri değiştirmez, receipt replay eder.
  v_result := public.undo_working_draft_command(v_token_a, v_command_1);
  if not coalesce((v_result ->> 'replayed')::boolean, false) then
    raise exception 'TEST_FAIL: ikinci undo replayed=true olmalı';
  end if;
  select draft_version into v_version
  from public.store_working_drafts where store_id = v_store_a;
  if v_version <> 7 then
    raise exception 'TEST_FAIL: replay undo version değiştirdi, gelen=%', v_version;
  end if;

  -- Undo edilmiş eski command yeniden gelirse DB onu tekrar UYGULAMAMALI.
  v_result := public.apply_working_draft_command(
    v_token_a,
    v_command_1,
    jsonb_build_object(
      'phone', '02125554433',
      'email', 'yeni-a@example.com'
    )
  );
  if not coalesce((v_result ->> 'replayed')::boolean, false) then
    raise exception 'TEST_FAIL: undo sonrası eski command replay sayılmalı';
  end if;
  select draft_data, draft_version into v_data, v_version
  from public.store_working_drafts where store_id = v_store_a;
  if v_version <> 7
     or v_data ->> 'phone' <> '02121112233'
     or v_data ->> 'email' <> 'eski-a@example.com' then
    raise exception 'TEST_FAIL: undo sonrası eski command veriyi yeniden uyguladı';
  end if;

  -- 7) Yeni command ve ardından başka bir command: eski undo STALE olmalı.
  v_result := public.apply_working_draft_command(
    v_token_a,
    v_command_2,
    jsonb_build_object('phone', '02127778899')
  );
  if (v_result ->> 'draft_version')::bigint <> 8 then
    raise exception 'TEST_FAIL: command_2 draft_version=8 olmalı';
  end if;

  -- Başka store session'ı bu command'ı undo edemez.
  begin
    perform public.undo_working_draft_command(v_token_b, v_command_2);
    raise exception 'TEST_SENTINEL: başka store undo reddedilmeliydi';
  exception when others then
    if sqlerrm like 'TEST_SENTINEL:%' then raise; end if;
    if sqlerrm <> 'UNDO_COMMAND_NOT_FOUND' then
      raise exception 'TEST_FAIL: cross-store undo için beklenmeyen hata=%', sqlerrm;
    end if;
  end;

  v_result := public.apply_working_draft_command(
    v_token_a,
    v_command_3,
    jsonb_build_object('email', 'son-a@example.com')
  );
  if (v_result ->> 'draft_version')::bigint <> 9 then
    raise exception 'TEST_FAIL: command_3 draft_version=9 olmalı';
  end if;

  begin
    perform public.undo_working_draft_command(v_token_a, v_command_2);
    raise exception 'TEST_SENTINEL: eski undo UNDO_STALE olmalı';
  exception when others then
    if sqlerrm like 'TEST_SENTINEL:%' then raise; end if;
    if sqlerrm <> 'UNDO_STALE' then
      raise exception 'TEST_FAIL: stale undo için UNDO_STALE yerine %', sqlerrm;
    end if;
  end;

  select draft_data, draft_version into v_data, v_version
  from public.store_working_drafts where store_id = v_store_a;
  if v_version <> 9
     or v_data ->> 'phone' <> '02127778899'
     or v_data ->> 'email' <> 'son-a@example.com' then
    raise exception 'TEST_FAIL: stale undo yeni veriyi değiştirdi';
  end if;

  raise notice 'Vixrex Assistant command runtime kabul testi YEŞİL';
end;
$$;

-- Test başarıyla bitse de hiçbir sahte veri kalmaz.
rollback;
