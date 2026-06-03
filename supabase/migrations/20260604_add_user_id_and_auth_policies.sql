-- 1. Add user_id column referencing auth.users
alter table public.stores
add column if not exists user_id uuid references auth.users(id) on delete set null;

-- Ensure a user can only own one store or showcase at a time
alter table public.stores
drop constraint if exists unique_user_store;

alter table public.stores
add constraint unique_user_store unique (user_id);

-- 2. Create RPC function to securely link an existing anonymous store to a logged-in user
create or replace function public.link_store_to_user(p_edit_token text)
returns boolean
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
begin
  -- Retrieve the authenticated user's ID
  v_user_id := auth.uid();
  
  if v_user_id is null then
    raise exception 'UNAUTHORIZED';
  end if;

  -- Link store that matches p_edit_token and doesn't have an owner yet
  update public.stores
  set user_id = v_user_id
  where edit_token = p_edit_token
    and user_id is null;

  return found;
end;
$$;

-- 3. Establish secure RLS updates using the authenticated User ID
drop policy if exists "Users can update their own stores" on public.stores;

create policy "Users can update their own stores"
on public.stores
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
