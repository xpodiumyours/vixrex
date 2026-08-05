-- Remaining Supabase Security Advisor hardening.
-- This migration is intentionally conservative: it fixes mutable search_path
-- and broad storage listing without breaking the anonymous edit-token flow.

-- 1. Ensure SECURITY DEFINER functions use a controlled search_path.
do $$
begin
  if pg_catalog.to_regprocedure('public.update_store_with_token(text,text,jsonb)') is not null then
    execute 'alter function public.update_store_with_token(text,text,jsonb) set search_path = pg_catalog, public, auth';
  end if;

  if pg_catalog.to_regprocedure('public.link_store_to_user(text)') is not null then
    execute 'alter function public.link_store_to_user(text) set search_path = pg_catalog, public, auth';
  end if;

  if pg_catalog.to_regprocedure('public.get_today_vitrin_view_count(text,text)') is not null then
    execute 'alter function public.get_today_vitrin_view_count(text,text) set search_path = pg_catalog, public, auth';
  end if;

  if pg_catalog.to_regprocedure('public.record_vitrin_view(text,text,text)') is not null then
    execute 'alter function public.record_vitrin_view(text,text,text) set search_path = pg_catalog, public, auth';
  end if;
end
$$;

-- 2. Remove broad public listing access on the public shelf-images bucket.
-- Public buckets can still serve known public URLs without a broad objects SELECT policy.
drop policy if exists "Allow public shelf image reads" on storage.objects;
drop policy if exists "Allow public shelf image listing" on storage.objects;
drop policy if exists "Public shelf image reads" on storage.objects;
drop policy if exists "Public shelf image listing" on storage.objects;

-- 3. Keep upload policy narrow and path based.
drop policy if exists "Allow public shelf image uploads" on storage.objects;

create policy "Allow public shelf image uploads"
on storage.objects
for insert
to anon, authenticated
with check (
  bucket_id = 'shelf-images'
  and name ~ '^[a-z0-9_-]+(/[a-z0-9_-]+){0,3}/[0-9]{10,}\.(jpg|png|webp)$'
);

-- 4. Tighten function EXECUTE grants.
-- Do not grant through PUBLIC. Grant only the roles the app actually uses.
do $$
begin
  if pg_catalog.to_regprocedure('public.link_store_to_user(text)') is not null then
    revoke execute on function public.link_store_to_user(text) from public;
    revoke execute on function public.link_store_to_user(text) from anon;
    grant execute on function public.link_store_to_user(text) to authenticated;
  end if;

  if pg_catalog.to_regprocedure('public.update_store_with_token(text,text,jsonb)') is not null then
    revoke execute on function public.update_store_with_token(text,text,jsonb) from public;
    grant execute on function public.update_store_with_token(text,text,jsonb) to anon, authenticated;
  end if;

  if pg_catalog.to_regprocedure('public.get_today_vitrin_view_count(text,text)') is not null then
    revoke execute on function public.get_today_vitrin_view_count(text,text) from public;
    grant execute on function public.get_today_vitrin_view_count(text,text) to anon, authenticated;
  end if;

  if pg_catalog.to_regprocedure('public.record_vitrin_view(text,text,text)') is not null then
    revoke execute on function public.record_vitrin_view(text,text,text) from public;
    grant execute on function public.record_vitrin_view(text,text,text) to anon, authenticated;
  end if;
end
$$;

notify pgrst, 'reload schema';
