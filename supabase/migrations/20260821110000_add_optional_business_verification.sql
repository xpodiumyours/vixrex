-- #263: İsteğe bağlı Google Business Profile sahiplik doğrulaması.
-- Doğrulama yayınlama kapısı değildir; mevcut vitrinler null kalır.

alter table public.stores
  add column business_verified_at timestamptz,
  add column business_verification_method text,
  add column google_business_location_name text;

alter table public.stores
  add constraint stores_business_verification_consistent check (
    (
      business_verified_at is null
      and business_verification_method is null
      and google_business_location_name is null
    )
    or (
      business_verified_at is not null
      and business_verification_method = 'google_business_profile'
      and google_business_location_name is not null
    )
  );

create unique index stores_google_business_location_unique
  on public.stores (google_business_location_name)
  where google_business_location_name is not null;

create or replace function public.protect_store_business_verification()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    if tg_op = 'INSERT' then
      if new.business_verified_at is not null
        or new.business_verification_method is not null
        or new.google_business_location_name is not null then
        raise exception 'business_verification_fields_protected'
          using errcode = '42501';
      end if;
    elsif row(
      new.business_verified_at,
      new.business_verification_method,
      new.google_business_location_name
    ) is distinct from row(
      old.business_verified_at,
      old.business_verification_method,
      old.google_business_location_name
    ) then
      raise exception 'business_verification_fields_protected'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

revoke all on function public.protect_store_business_verification()
  from public, anon, authenticated;

create trigger stores_protect_business_verification
before insert or update of
  business_verified_at,
  business_verification_method,
  google_business_location_name
on public.stores
for each row execute function public.protect_store_business_verification();

comment on column public.stores.business_verified_at is
  'İsteğe bağlı sahiplik doğrulama zamanı; yayınlama için zorunlu değildir.';
comment on column public.stores.business_verification_method is
  'Sunucu tarafından doğrulanan yöntem.';
comment on column public.stores.google_business_location_name is
  'Eşleşen Google Business Profile location kaynak adı.';
