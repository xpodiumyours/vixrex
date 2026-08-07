-- Taslağı canlı sürümden tazele.
--
-- SORUN (2026-08-07, tur bulgusu 10)
-- Taslak BİR KEZ oluşturuluyor — o anki vitrinin kopyası olarak. Sonra
-- esnaf manuel panelden yayınladığı her şey `stores`a yazılıyor ama
-- taslak eski hâlde kalıyor. Sistem farkı görüyor ve turuncu bir kutuyla
-- "canlı vitrin değişmiş" diyor, ama uyarının ÇARESİ YOK: "yeniden yükle"
-- aynı eski taslağı tekrar getiriyor.
--
-- Casper'ın ifadesi: "canlı vitrin değişmiş taslak sürümü eski diye bir
-- turuncu kutucuk içinde yeniden yükle uyarısı veriyor ama yeniden
-- yükleme ile ... next.js ekrana gelmiyor."
--
-- Tek çıkış yolu "Değişiklikleri bırak"tı — taslağı siliyor, sonraki
-- açılışta canlıdan yeniden kuruluyor. Ama esnaf için o düğme "işimi
-- kaybedeceğim" demek; kimse basmaz.
--
-- ÇÖZÜM
-- Taslağı canlı satırdan yeniden kurar ve sürüm damgasını günceller.
-- Uyarı kapanır. Silme değil, tazeleme: esnaf aynı oturumda kalır.
--
-- KAYIP UYARISI ÇAĞIRANIN İŞİ
-- Bu fonksiyon taslakta bekleyen değişiklikleri ÜZERİNE YAZAR. Arayüz
-- önce sormalıdır. Fonksiyon sessizce çalışmaz: kaç alanın değiştiğini
-- döndürür, çağıran bunu gösterebilir.

create or replace function public.refresh_working_draft(p_session_token text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_token_hash text;
  v_store_id uuid;
  v_slug text;
  v_live_version integer;
  v_eski_draft jsonb;
  v_yeni_draft jsonb;
  v_degisen integer := 0;
  v_anahtar text;
begin
  if p_session_token is null
     or pg_catalog.length(pg_catalog.btrim(p_session_token)) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  v_token_hash := encode(sha256(pg_catalog.btrim(p_session_token)::bytea), 'hex');

  select s.store_id, st.slug, st.version
  into v_store_id, v_slug, v_live_version
  from public.owner_sessions s
  join public.stores st on st.id = s.store_id
  where s.session_token_hash = v_token_hash
    and s.consumed_at is not null
    and s.expires_at > now();

  if v_store_id is null then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  select draft_data into v_eski_draft
  from public.store_working_drafts
  where store_id = v_store_id;

  -- GİZLİ ALANLAR TASLAĞA GİRMEZ.
  -- to_jsonb(s) satırın TAMAMINI kopyalar; içinde edit_token de vardır.
  -- Taslak sahip paneline prop olarak gittiği için bu doğrudan tarayıcıya
  -- sızardı (koruma sınırı 7).
  select to_jsonb(st)
         - '{edit_token,user_id,privacy_notice_hash,terms_hash,publication_consent_hash}'::text[]
  into v_yeni_draft
  from public.stores st
  where st.id = v_store_id;

  if v_yeni_draft is null then
    raise exception 'STORE_NOT_FOUND';
  end if;

  -- Kaç alan değişecek — çağıran esnafa gösterebilsin.
  if v_eski_draft is not null then
    for v_anahtar in select jsonb_object_keys(v_yeni_draft)
    loop
      if v_eski_draft -> v_anahtar is distinct from v_yeni_draft -> v_anahtar then
        v_degisen := v_degisen + 1;
      end if;
    end loop;
  end if;

  insert into public.store_working_drafts (
    store_id, draft_data, draft_version, base_live_version, updated_at
  )
  values (v_store_id, v_yeni_draft, 1, v_live_version, now())
  on conflict (store_id) do update
    set draft_data = excluded.draft_data,
        draft_version = public.store_working_drafts.draft_version + 1,
        base_live_version = excluded.base_live_version,
        updated_at = now();

  return jsonb_build_object(
    'store_id', v_store_id,
    'slug', v_slug,
    'live_version', v_live_version,
    'degisen_alan', v_degisen
  );
end;
$$;

comment on function public.refresh_working_draft is
  'Sahip taslağını canlı vitrinden tazeler. Taslaktaki bekleyen '
  'değişiklikleri üzerine yazar; çağıran önce sormalıdır.';

revoke all on function public.refresh_working_draft(text) from public;
grant execute on function public.refresh_working_draft(text) to anon, authenticated;
