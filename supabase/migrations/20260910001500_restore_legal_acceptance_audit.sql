-- Vixrex yasal onay denetim izi.
--
-- 2026-09-10 production salt-okuma denetiminde public.legal_acceptance_events
-- tablosu vardı ancak tabloya yazan stores trigger/fonksiyon yoktu ve tablo
-- 0 kayıt içeriyordu. Eski arşiv migration'ı bu denetim izini öngörüyordu.
--
-- Bu migration yeni bir onay/yayın yolu açmaz. Mevcut stores değişikliklerini
-- gözleyip yalnız yasal durum gerçekten değiştiğinde mevcut audit tablosuna
-- olay ekler. İstemci bu fonksiyonu doğrudan çağıramaz.

create or replace function public.vixrex_record_store_legal_events()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if new.privacy_notice_acknowledged is true and (
    tg_op = 'INSERT'
    or old.privacy_notice_acknowledged is not true
    or old.privacy_notice_version is distinct from new.privacy_notice_version
    or old.privacy_notice_hash is distinct from new.privacy_notice_hash
  ) then
    insert into public.legal_acceptance_events (
      store_slug,
      user_id,
      event_type,
      document_type,
      document_version,
      document_hash,
      occurred_at
    ) values (
      new.slug,
      new.user_id,
      'privacy_notice_acknowledged',
      'privacy',
      new.privacy_notice_version,
      new.privacy_notice_hash,
      coalesce(new.privacy_notice_acknowledged_at, pg_catalog.now())
    );
  end if;

  if new.terms_accepted is true and (
    tg_op = 'INSERT'
    or old.terms_accepted is not true
    or old.terms_version is distinct from new.terms_version
    or old.terms_hash is distinct from new.terms_hash
  ) then
    insert into public.legal_acceptance_events (
      store_slug,
      user_id,
      event_type,
      document_type,
      document_version,
      document_hash,
      occurred_at
    ) values (
      new.slug,
      new.user_id,
      'terms_accepted',
      'terms',
      new.terms_version,
      new.terms_hash,
      coalesce(new.terms_accepted_at, pg_catalog.now())
    );
  end if;

  if new.publication_consent_accepted is true and (
    tg_op = 'INSERT'
    or old.publication_consent_accepted is not true
    or old.publication_consent_version is distinct from new.publication_consent_version
    or old.publication_consent_hash is distinct from new.publication_consent_hash
  ) then
    insert into public.legal_acceptance_events (
      store_slug,
      user_id,
      event_type,
      document_type,
      document_version,
      document_hash,
      occurred_at
    ) values (
      new.slug,
      new.user_id,
      'publication_consent_granted',
      'consent',
      new.publication_consent_version,
      new.publication_consent_hash,
      coalesce(new.publication_consent_accepted_at, pg_catalog.now())
    );
  end if;

  if tg_op = 'UPDATE'
    and old.publication_consent_accepted is true
    and new.publication_consent_accepted is not true then
    insert into public.legal_acceptance_events (
      store_slug,
      user_id,
      event_type,
      document_type,
      document_version,
      document_hash,
      occurred_at
    ) values (
      new.slug,
      new.user_id,
      'publication_consent_withdrawn',
      'consent',
      old.publication_consent_version,
      old.publication_consent_hash,
      coalesce(new.publication_consent_withdrawn_at, pg_catalog.now())
    );
  end if;

  return new;
end;
$$;

revoke all on function public.vixrex_record_store_legal_events()
  from public, anon, authenticated, service_role;

drop trigger if exists trg_record_store_legal_events on public.stores;
create trigger trg_record_store_legal_events
after insert or update on public.stores
for each row execute function public.vixrex_record_store_legal_events();

comment on function public.vixrex_record_store_legal_events() is
  'Yasal onay/şartlar/yayın izni değişikliklerini legal_acceptance_events tablosuna append-only denetim izi olarak yazar.';
