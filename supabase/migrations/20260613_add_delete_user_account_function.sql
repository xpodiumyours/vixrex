-- Create a SECURITY DEFINER function to allow users to delete their own account and all associated data.
create or replace function public.delete_user_account()
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $$
begin
  -- 1. Delete user's store/vitrin data. Since user_id references auth.users,
  -- this ensures any store profile is deleted.
  delete from public.stores where user_id = auth.uid();

  -- 2. Delete the user's auth account itself.
  delete from auth.users where id = auth.uid();
end;
$$;

-- Tighten execute privileges: only authenticated users can run this
revoke execute on function public.delete_user_account() from public;
revoke execute on function public.delete_user_account() from anon;
grant execute on function public.delete_user_account() to authenticated;

notify pgrst, 'reload schema';
