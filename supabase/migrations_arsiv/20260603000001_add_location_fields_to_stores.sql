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
comment on column public.stores.location_source is 'Source platform/device from which location was retrieved (e.g., ''geolocator'').';
