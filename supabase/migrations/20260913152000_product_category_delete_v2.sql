-- Category deletion for rich catalog clients.
-- Products are moved first so the existing category FK remains valid.

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

  select pc.store_id
  into v_replacement_store_id
  from public.product_categories as pc
  where pc.id = p_replacement_id;

  if v_replacement_store_id is distinct from v_store_id then
    raise exception 'CATEGORY_NOT_IN_SAME_STORE';
  end if;

  update public.products as p
  set category_id = p_replacement_id
  where p.store_id = v_store_id
    and p.category_id = p_category_id;

  delete from public.product_categories as pc
  where pc.id = p_category_id
    and pc.store_id = v_store_id;

  return pg_catalog.jsonb_build_object(
    'success', true,
    'deleted_id', p_category_id,
    'replacement_id', p_replacement_id
  );
end;
$$;

alter function public.delete_store_category_v2(uuid, uuid, text) owner to postgres;
revoke execute on function public.delete_store_category_v2(uuid, uuid, text) from public;
grant execute on function public.delete_store_category_v2(uuid, uuid, text) to anon, authenticated, service_role;
