alter table public.products
  add column image_publish_minimum smallint not null default 0
  check (image_publish_minimum in (0, 3));

alter table public.products alter column image_publish_minimum set default 3;

create or replace function public.guard_product_image_publication()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
declare
  v_image_count integer;
begin
  if tg_op = 'INSERT' then
    new.image_publish_minimum := 3;
  else
    new.image_publish_minimum := old.image_publish_minimum;
  end if;

  if new.image_publish_minimum > 0 then
    select count(distinct pg_catalog.btrim(value #>> '{}'))
    into v_image_count
    from pg_catalog.jsonb_array_elements(
      case when pg_catalog.jsonb_typeof(new.image_urls) = 'array'
        then new.image_urls else '[]'::jsonb end
    ) as images(value)
    where pg_catalog.jsonb_typeof(value) = 'string'
      and pg_catalog.btrim(value #>> '{}') ~* '^https?://[^[:space:]/?#]+[^[:space:]]*$';

    if v_image_count < new.image_publish_minimum then
      new.is_visible := false;
    end if;
  end if;
  return new;
end;
$$;

revoke all on function public.guard_product_image_publication() from public, anon, authenticated;

create trigger guard_product_image_publication
before insert or update on public.products
for each row execute function public.guard_product_image_publication();
