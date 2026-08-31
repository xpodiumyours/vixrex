revoke select ("edit_token") on table public.stores from anon;
select has_column_privilege('anon', 'public.stores', 'edit_token', 'SELECT') as still_has_it;
