-- İlk yayın öncesi Product CORE staging için store UUID'yi güvenli biçimde
-- çözer. Draft stores satırı public SELECT politikasına açık değildir; client'ın
-- tablo RLS'ini gevşetmek yerine mevcut edit-token yetkilendirmesini kullanır.
-- Ham edit_token veya user_id hiçbir zaman dönmez.
--
-- Supabase güvenlik kuralı: SECURITY DEFINER işi exposed/public şemada
-- tutulmaz. Privileged lookup private şemadadır; Data API'nin çağırdığı public
-- wrapper SECURITY INVOKER olarak kalır ve yalnız authenticated rolüne açılır.

create schema if not exists private;
grant usage on schema private to authenticated;

create or replace function private.get_store_id_for_edit_token_internal(
  p_slug text,
  p_edit_token text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_slug text := pg_catalog.btrim(coalesce(p_slug, ''));
  v_store_id uuid;
begin
  if v_slug = '' then
    return null;
  end if;

  select s.id
    into v_store_id
  from public.stores as s
  where s.slug = v_slug
  limit 1;

  if v_store_id is null then
    return null;
  end if;

  if not public._check_store_authorization(v_store_id, p_edit_token) then
    return null;
  end if;

  return v_store_id;
end;
$$;

alter function private.get_store_id_for_edit_token_internal(text, text)
  owner to postgres;
revoke all on function private.get_store_id_for_edit_token_internal(text, text)
  from public, anon, authenticated;
grant execute on function private.get_store_id_for_edit_token_internal(text, text)
  to authenticated;

create or replace function public.get_store_id_for_edit_token(
  p_slug text,
  p_edit_token text
)
returns uuid
language sql
security invoker
set search_path = ''
as $$
  select private.get_store_id_for_edit_token_internal(p_slug, p_edit_token);
$$;

alter function public.get_store_id_for_edit_token(text, text) owner to postgres;
revoke all on function public.get_store_id_for_edit_token(text, text)
  from public, anon, authenticated;
grant execute on function public.get_store_id_for_edit_token(text, text)
  to authenticated;

notify pgrst, 'reload schema';
