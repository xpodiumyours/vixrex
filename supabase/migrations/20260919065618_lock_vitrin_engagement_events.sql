alter table public.vitrin_engagement_events enable row level security;

revoke all on table public.vitrin_engagement_events from public, anon, authenticated;

notify pgrst, 'reload schema';
