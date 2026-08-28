-- Flutter ve web'in ortak bildirim kutusu.
-- Bildirim üreticisi Flutter'da kalabilir; okuma durumu cihazda değil
-- hesapta yaşar, böylece iki yüzey aynı satırları ve aynı read_at değerini
-- görür.

create table public.notification_inbox (
  user_id uuid not null references auth.users(id) on delete cascade,
  id text not null,
  title text not null check (char_length(title) between 1 and 160),
  body text not null check (char_length(body) between 1 and 1000),
  store_slug text,
  type text not null default 'booking' check (char_length(type) between 1 and 40),
  created_at timestamptz not null default now(),
  read_at timestamptz,
  primary key (user_id, id)
);

create index notification_inbox_unread_idx
  on public.notification_inbox (user_id, created_at desc)
  where read_at is null;

alter table public.notification_inbox enable row level security;

revoke all on table public.notification_inbox from public, anon, authenticated;
grant select, insert on table public.notification_inbox to authenticated;
grant update (read_at) on table public.notification_inbox to authenticated;
grant all on table public.notification_inbox to service_role;

create policy "notification_inbox_select_own"
  on public.notification_inbox
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "notification_inbox_insert_own"
  on public.notification_inbox
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "notification_inbox_update_own"
  on public.notification_inbox
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

comment on table public.notification_inbox is
  'Flutter ve web sahip yüzeylerinin ortak hesap bildirim kutusu.';
