-- Engagement events are written/read only through the existing SECURITY DEFINER
-- RPCs. The underlying table must not be directly exposed through PostgREST.
-- This is additive and keeps record_vitrin_engagement/get_haftalik_performans
-- behavior unchanged.

alter table public.vitrin_engagement_events enable row level security;

revoke all privileges on table public.vitrin_engagement_events
  from public, anon, authenticated;

comment on table public.vitrin_engagement_events is
  'WhatsApp/telefon/konum tıklamaları + ürün görüntülemeleri. Doğrudan Data API erişimi kapalıdır; yazma record_vitrin_engagement, sahip özeti get_haftalik_performans RPC hattından yapılır.';

notify pgrst, 'reload schema';
