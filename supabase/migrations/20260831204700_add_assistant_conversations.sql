-- PR1-C3: assistant_conversations / assistant_messages — kalıcı VixRex Asistan konuşması
-- Problem: Next.js konuşması ekran belleğinde, ilk handoff kısa ömürlü
-- owner_sessions'da; Flutter web arası devamlılık yok.
-- Çözüm: kullanıcı/mağazaya bağlı, sıralı, idempotent, silme zincirli kalıcı konuşma.
-- Desen: doğrudan tablo erişimi YOK (RLS açık, politika yok), tüm erişim
-- SECURITY DEFINER fonksiyonlardan (PR1-C4/C5 ve PR4).

create table public.assistant_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  store_id uuid references public.stores(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Hesap başına tek aktif konuşma (tek vitrin kuralı); mağaza nullable ama
-- aktifse tek konuşma. Geçmiş konuşmalar silinince yenisi açılabilir.
create unique index if not exists idx_assistant_conversations_user_unique
  on public.assistant_conversations (user_id);

create index if not exists idx_assistant_conversations_store_id
  on public.assistant_conversations (store_id);

-- Mesajlar: sıralı, idempotent istemci mesaj kimliği, boyut sınırı
create table public.assistant_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.assistant_conversations(id) on delete cascade,
  seq bigint not null,
  role text not null check (role in ('assistant', 'user')),
  message_key text,
  message_text text not null check (char_length(message_text) > 0 and char_length(message_text) <= 4000),
  catalog_snapshot text,
  client_message_id text,
  created_at timestamptz not null default now()
);

-- Sıra tek artan: (conversation_id, seq) unique
create unique index if not exists idx_assistant_messages_conversation_seq
  on public.assistant_messages (conversation_id, seq);

-- Idempotent istemci kimliği: aynı istemci mesajı iki kez yazılmaz
create unique index if not exists idx_assistant_messages_client_id
  on public.assistant_messages (conversation_id, client_message_id)
  where client_message_id is not null;

create index if not exists idx_assistant_messages_conversation_created
  on public.assistant_messages (conversation_id, created_at);

-- updated_at tetikleyici (conversations)
create or replace function public.set_assistant_conversations_updated_at()
returns trigger
language plpgsql
set search_path = pg_catalog
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_assistant_conversations_updated_at on public.assistant_conversations;
create trigger trg_assistant_conversations_updated_at
  before update on public.assistant_conversations
  for each row execute function public.set_assistant_conversations_updated_at();

alter table public.assistant_conversations enable row level security;
alter table public.assistant_messages enable row level security;

comment on table public.assistant_conversations is
  'Kalıcı VixRex Asistan konuşması: user_id + optional store_id. RLS açık, doğrudan erişim kapalı.';
comment on table public.assistant_messages is
  'Sıralı konuşma mesajları: seq unique, client_message_id idempotent, message_key katalog anahtarı + snapshot. RLS açık.';

-- Hesap silinince konuşma ve mesajlar cascade silinir (FK on delete cascade)
-- Boyut sınırı: message_text <= 4000 (check), seq sıralı
