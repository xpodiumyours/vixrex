-- Kullanıcının kendi vitrini için kalıcı silme.
-- Tüm bağlı kayıtlar önce temizlenir; slug ve edit token eşleşmeden hiçbir şey silinmez.
create or replace function public.delete_store_with_token(
  p_slug text,
  p_edit_token text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_slug text := pg_catalog.btrim(p_slug);
  v_store_id uuid;
begin
  select id
  into v_store_id
  from public.stores
  where slug = v_slug
    and edit_token = pg_catalog.btrim(p_edit_token);

  if v_store_id is null then
    raise exception 'EDIT_TOKEN_MISMATCH';
  end if;

  delete from public.store_instagram_imports
  where store_slug = v_slug
     or connection_id in (
       select id from public.store_instagram_connections where store_slug = v_slug
     );
  delete from public.store_instagram_tokens
  where connection_id in (
    select id from public.store_instagram_connections where store_slug = v_slug
  );
  delete from public.store_instagram_connections where store_slug = v_slug;
  delete from public.vitrin_views where store_id = v_store_id;
  delete from public.store_category_image_usage where store_id = v_store_id;
  delete from public.booking_settings where store_slug = v_slug;
  delete from public.store_articles where store_slug = v_slug;
  delete from public.appointments where store_slug = v_slug;
  delete from public.stores where id = v_store_id;
end;
$$;

revoke execute on function public.delete_store_with_token(text, text) from public;
grant execute on function public.delete_store_with_token(text, text) to anon, authenticated;
