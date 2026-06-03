-- Run this in Supabase SQL Editor before testing store publishing again.
-- It fixes PGRST204 errors for the location fields and refreshes PostgREST.

alter table public.stores
add column if not exists latitude float8,
add column if not exists longitude float8,
add column if not exists location_accuracy_meters float8,
add column if not exists location_consent_at timestamptz,
add column if not exists location_source text;

comment on column public.stores.latitude is 'Store location latitude coordinate.';
comment on column public.stores.longitude is 'Store location longitude coordinate.';
comment on column public.stores.location_accuracy_meters is 'Accuracy radius of the retrieved location in meters.';
comment on column public.stores.location_consent_at is 'Timestamp when the user provided KVKK consent to share their location.';
comment on column public.stores.location_source is 'Source platform/device from which location was retrieved.';

notify pgrst, 'reload schema';
select pg_notification_queue_usage();

select column_name
from information_schema.columns
where table_schema = 'public'
  and table_name = 'stores'
  and column_name in (
    'latitude',
    'longitude',
    'location_accuracy_meters',
    'location_consent_at',
    'location_source'
  )
order by column_name;
