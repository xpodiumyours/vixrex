-- Product live-ready gate: keep the shared rich product form as the single UI
-- contract while persisting KDV into the existing products.vat_rate column.
--
-- The UI stores the selected KDV rate inside metadata.attributes while editing
-- because both Flutter and Next.js already consume the same shared product
-- schema. This trigger is the database boundary: every metadata write maps that
-- value to products.vat_rate. Services clear KDV. Invalid values abort the same
-- statement, so a product can never be partially written.

create or replace function public.sync_product_vat_rate_from_metadata()
returns trigger
language plpgsql
set search_path = 'pg_catalog', 'public'
as $$
declare
  v_raw text;
  v_rate integer;
begin
  if pg_catalog.jsonb_typeof(coalesce(new.metadata, '{}'::jsonb)) <> 'object' then
    raise exception 'PRODUCT_METADATA_INVALID';
  end if;

  if coalesce(nullif(pg_catalog.btrim(new.metadata->>'itemKind'), ''), 'physical') = 'service' then
    new.vat_rate := null;
    return new;
  end if;

  if pg_catalog.jsonb_typeof(new.metadata->'attributes') = 'array' then
    select nullif(pg_catalog.btrim(attribute->>'value'), '')
      into v_raw
    from pg_catalog.jsonb_array_elements(new.metadata->'attributes') as attribute
    where attribute->>'key' = 'vatRate'
    limit 1;
  end if;

  if v_raw is null then
    new.vat_rate := null;
    return new;
  end if;

  if v_raw !~ '^[0-9]{1,3}$' then
    raise exception 'PRODUCT_VAT_INVALID';
  end if;

  v_rate := v_raw::integer;
  if v_rate < 0 or v_rate > 100 then
    raise exception 'PRODUCT_VAT_INVALID';
  end if;

  new.vat_rate := v_rate;
  return new;
end;
$$;

alter function public.sync_product_vat_rate_from_metadata() owner to postgres;
revoke execute on function public.sync_product_vat_rate_from_metadata() from public;

drop trigger if exists trg_products_vat_from_metadata on public.products;
create trigger trg_products_vat_from_metadata
before insert or update of metadata on public.products
for each row
execute function public.sync_product_vat_rate_from_metadata();
