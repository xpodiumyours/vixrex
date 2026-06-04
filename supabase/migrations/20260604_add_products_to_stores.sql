-- Safe migration to add products column with default jsonb array
alter table public.stores
add column if not exists products jsonb not null default '[]'::jsonb;

comment on column public.stores.products is 'Product catalog list for stores.';

-- Fallback migration to ensure working_hours is present
alter table public.stores
add column if not exists working_hours text;

comment on column public.stores.working_hours is 'Working hours text for stores.';

-- Reload the PostgREST schema cache
notify pgrst, 'reload schema';
