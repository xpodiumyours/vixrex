-- Kategori tipi ve products.metadata aynı hakikati taşımalıdır.
-- Kategori adı üzerinden tahmin yapılmaz; yalnız product_template_key kullanılır.
-- Bu migration önceki rich-product fonksiyonlarını aynı imzayla güçlendirir.

create or replace function public.update_store_category_v2(
  p_category_id uuid,
  p_edit_token text,
  p_name text default null,
  p_template_key text default null,
  p_sort_order integer default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_store_id uuid;
  v_current_template_key text;
  v_template_key text;
  v_effective_template_key text;
begin
  select pc.store_id, pc.product_template_key
  into v_store_id, v_current_template_key
  from public.product_categories as pc
  where pc.id = p_category_id;

  if v_store_id is null then
    raise exception 'CATEGORY_NOT_FOUND';
  end if;

  if not public._check_store_authorization(v_store_id, p_edit_token) then
    raise exception 'UNAUTHORIZED';
  end if;

  if p_name is not null and pg_catalog.length(pg_catalog.btrim(p_name)) = 0 then
    raise exception 'CATEGORY_NAME_REQUIRED';
  end if;

  v_template_key := nullif(pg_catalog.btrim(coalesce(p_template_key, '')), '');
  if v_template_key is not null and v_template_key not in (
    'generic', 'fashion', 'electronics', 'beauty', 'food', 'home', 'automotive', 'service'
  ) then
    raise exception 'INVALID_PRODUCT_TEMPLATE_KEY';
  end if;

  v_effective_template_key := coalesce(v_template_key, v_current_template_key, 'generic');

  update public.product_categories as pc
  set
    name = case
      when p_name is not null then pg_catalog.btrim(p_name)
      else pc.name
    end,
    product_template_key = v_effective_template_key,
    sort_order = coalesce(p_sort_order, pc.sort_order),
    updated_at = now()
  where pc.id = p_category_id;

  if v_effective_template_key is distinct from v_current_template_key then
    update public.products as p
    set metadata = pg_catalog.jsonb_set(
      pg_catalog.jsonb_set(
        coalesce(p.metadata, '{}'::jsonb),
        '{templateKey}',
        pg_catalog.to_jsonb(v_effective_template_key),
        true
      ),
      '{itemKind}',
      pg_catalog.to_jsonb(
        case
          when v_effective_template_key = 'service' then 'service'::text
          else 'physical'::text
        end
      ),
      true
    )
    where p.store_id = v_store_id
      and p.category_id = p_category_id;
  end if;

  return pg_catalog.jsonb_build_object(
    'id', p_category_id,
    'product_template_key', v_effective_template_key,
    'success', true
  );
end;
$$;

alter function public.update_store_category_v2(uuid, text, text, text, integer) owner to postgres;
revoke execute on function public.update_store_category_v2(uuid, text, text, text, integer) from public;
grant execute on function public.update_store_category_v2(uuid, text, text, text, integer) to anon, authenticated, service_role;

create or replace function public.delete_store_category_v2(
  p_category_id uuid,
  p_replacement_id uuid,
  p_edit_token text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_store_id uuid;
  v_replacement_store_id uuid;
  v_replacement_template_key text;
  v_category_count integer;
begin
  select pc.store_id
  into v_store_id
  from public.product_categories as pc
  where pc.id = p_category_id;

  if v_store_id is null then
    raise exception 'CATEGORY_NOT_FOUND';
  end if;

  if not public._check_store_authorization(v_store_id, p_edit_token) then
    raise exception 'UNAUTHORIZED';
  end if;

  select count(*)
  into v_category_count
  from public.product_categories as pc
  where pc.store_id = v_store_id
    and pc.is_active = true;

  if v_category_count <= 1 then
    raise exception 'CATEGORY_MIN_ONE';
  end if;

  select pc.store_id, pc.product_template_key
  into v_replacement_store_id, v_replacement_template_key
  from public.product_categories as pc
  where pc.id = p_replacement_id;

  if v_replacement_store_id is distinct from v_store_id then
    raise exception 'CATEGORY_NOT_IN_SAME_STORE';
  end if;

  v_replacement_template_key := coalesce(
    nullif(pg_catalog.btrim(v_replacement_template_key), ''),
    'generic'
  );

  update public.products as p
  set
    category_id = p_replacement_id,
    metadata = pg_catalog.jsonb_set(
      pg_catalog.jsonb_set(
        coalesce(p.metadata, '{}'::jsonb),
        '{templateKey}',
        pg_catalog.to_jsonb(v_replacement_template_key),
        true
      ),
      '{itemKind}',
      pg_catalog.to_jsonb(
        case
          when v_replacement_template_key = 'service' then 'service'::text
          else 'physical'::text
        end
      ),
      true
    )
  where p.store_id = v_store_id
    and p.category_id = p_category_id;

  delete from public.product_categories as pc
  where pc.id = p_category_id
    and pc.store_id = v_store_id;

  return pg_catalog.jsonb_build_object(
    'success', true,
    'deleted_id', p_category_id,
    'replacement_id', p_replacement_id,
    'replacement_template_key', v_replacement_template_key
  );
end;
$$;

alter function public.delete_store_category_v2(uuid, uuid, text) owner to postgres;
revoke execute on function public.delete_store_category_v2(uuid, uuid, text) from public;
grant execute on function public.delete_store_category_v2(uuid, uuid, text) to anon, authenticated, service_role;
