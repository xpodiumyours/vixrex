-- Product metadata'nın bütün yazım yollarında ortak şema sürümünü kullanmasını sağlar.
-- Tarihi batch/XML migration'ı değiştirilmez. Manuel Web/Flutter zaten sürüm 2
-- yazar; bu DB sınırı batch/XML ve gelecekteki diğer CORE çağrılarını da aynı
-- sözleşmeye yükseltir.

create or replace function public.enforce_product_metadata_schema_version()
returns trigger
language plpgsql
set search_path = 'pg_catalog', 'public'
as $$
begin
  if pg_catalog.jsonb_typeof(coalesce(new.metadata, '{}'::jsonb)) = 'object'
     and (new.metadata->>'itemKind') in ('physical', 'service')
     and nullif(pg_catalog.btrim(coalesce(new.metadata->>'templateKey', '')), '') is not null then
    new.metadata := pg_catalog.jsonb_set(
      new.metadata,
      '{schemaVersion}',
      '2'::jsonb,
      true
    );
  end if;

  return new;
end;
$$;

alter function public.enforce_product_metadata_schema_version() owner to postgres;
revoke execute on function public.enforce_product_metadata_schema_version() from public, anon, authenticated;

drop trigger if exists trg_products_metadata_schema_version on public.products;
create trigger trg_products_metadata_schema_version
before insert or update of metadata on public.products
for each row
execute function public.enforce_product_metadata_schema_version();
