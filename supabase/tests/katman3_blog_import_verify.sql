begin;

insert into auth.users (id, email, role, aud, created_at, updated_at)
values
  ('11111111-1111-4111-8111-111111111111', 'katman3-a@example.test', 'authenticated', 'authenticated', now(), now()),
  ('22222222-2222-4222-8222-222222222222', 'katman3-b@example.test', 'authenticated', 'authenticated', now(), now());

insert into public.stores (slug, name, business_type, user_id)
values
  ('katman3-test-a', 'Katman 3 Test A', 'hizmet', '11111111-1111-4111-8111-111111111111'),
  ('katman3-test-b', 'Katman 3 Test B', 'hizmet', '22222222-2222-4222-8222-222222222222');

insert into public.vixrex_blog_articles
  (id, slug, title, summary, content, status, published_at, primary_topic, purpose, provenance)
values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1', 'katman3-yayin-tam', 'Yayındaki Tam Yazı', 'Tam yazı özeti', '<p>Tam kaynak içerik</p>', 'published', now(), 'vixrex-kullanimi', 'vixrex-kullanimi', 'vixrex-editorial'),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2', 'katman3-taslak', 'Merkezi Taslak', 'Taslak özet', '<p>Taslak içerik</p>', 'draft', null, 'vixrex-kullanimi', 'vixrex-kullanimi', 'vixrex-editorial'),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3', 'katman3-yayin-kisa', 'Yayındaki Kısa Yazı', 'Kısa yazı özeti', '<p>Kısa kaynak tam içeriği</p>', 'published', now(), 'vixrex-kullanimi', 'vixrex-kullanimi', 'vixrex-editorial'),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa4', 'katman3-owner-token', 'Owner Token Yazısı', 'Owner token özeti', '<p>Owner token içerik</p>', 'published', now(), 'vixrex-kullanimi', 'vixrex-kullanimi', 'vixrex-editorial');

-- Kimliksiz çağrı reddedilir.
select set_config('request.jwt.claim.sub', '', true);
do $$
begin
  begin
    perform public.import_vixrex_blog_article_to_store(
      'katman3-test-a', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1', 'adaptable_draft', null
    );
    raise exception 'TEST_EXPECTED_FAILURE_NOT_RAISED';
  exception when others then
    if sqlerrm = 'TEST_EXPECTED_FAILURE_NOT_RAISED' then raise; end if;
    if position('STORE_NOT_AUTHORIZED' in sqlerrm) = 0 then raise; end if;
  end;
end $$;

-- A sahibinin JWT gerçeği.
select set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);

-- A, B vitrininin yazısını oluşturamaz.
do $$
begin
  begin
    perform public.import_vixrex_blog_article_to_store(
      'katman3-test-b', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1', 'adaptable_draft', null
    );
    raise exception 'TEST_EXPECTED_FAILURE_NOT_RAISED';
  exception when others then
    if sqlerrm = 'TEST_EXPECTED_FAILURE_NOT_RAISED' then raise; end if;
    if position('STORE_NOT_AUTHORIZED' in sqlerrm) = 0 then raise; end if;
  end;
end $$;

-- Merkezi draft kaynak import edilemez.
do $$
begin
  begin
    perform public.import_vixrex_blog_article_to_store(
      'katman3-test-a', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2', 'adaptable_draft', null
    );
    raise exception 'TEST_EXPECTED_FAILURE_NOT_RAISED';
  exception when others then
    if sqlerrm = 'TEST_EXPECTED_FAILURE_NOT_RAISED' then raise; end if;
    if position('SOURCE_NOT_PUBLISHED' in sqlerrm) = 0 then raise; end if;
  end;
end $$;

-- Published → adaptable_draft daima tek bir draft snapshot üretir ve tekrar idempotenttir.
do $$
declare
  r1 jsonb;
  r2 jsonb;
  c integer;
  s text;
  body text;
begin
  r1 := public.import_vixrex_blog_article_to_store(
    'katman3-test-a', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1', 'adaptable_draft', null
  );
  if coalesce((r1->>'created')::boolean, false) is not true then
    raise exception 'İlk import created=true değil: %', r1;
  end if;

  select count(*), min(status), min(content)
    into c, s, body
  from public.store_articles
  where store_slug='katman3-test-a'
    and source_vixrex_blog_article_slug='katman3-yayin-tam';

  if c <> 1 or s <> 'draft' or body <> '<p>Tam kaynak içerik</p>' then
    raise exception 'Published→draft snapshot hatalı: count=%, status=%, body=%', c, s, body;
  end if;

  r2 := public.import_vixrex_blog_article_to_store(
    'katman3-test-a', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1', 'adaptable_draft', null
  );
  if coalesce((r2->>'created')::boolean, true) is not false then
    raise exception 'Tekrar import idempotent değil: %', r2;
  end if;
  if r1->>'article_id' <> r2->>'article_id' then
    raise exception 'Tekrar import aynı article_id döndürmedi';
  end if;
end $$;

-- linked_excerpt tam gövdeyi değil özet + merkezi kaynak bağlantısını taşır.
do $$
declare
  r jsonb;
  body text;
begin
  r := public.import_vixrex_blog_article_to_store(
    'katman3-test-a', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3', 'linked_excerpt', null
  );
  select content into body
  from public.store_articles
  where id=(r->>'article_id')::uuid;

  if position('Kısa yazı özeti' in body) = 0
     or position('/blog/katman3-yayin-kisa' in body) = 0
     or position('Kısa kaynak tam içeriği' in body) > 0 then
    raise exception 'linked_excerpt sözleşmesi hatalı: %', body;
  end if;
end $$;

-- Next.js owner-session token yolu auth.uid olmadan kendi store_id'sinde çalışır.
insert into public.owner_sessions
  (store_id, code_hash, expires_at, consumed_at, session_token_hash)
select id, 'katman3-code-hash', now() + interval '1 hour', now(),
       'ffe054fe7ae0cb6dc65c3af9b61d5209f439851db43d0ba5997337df154668eb'
from public.stores where slug='katman3-test-a';

select set_config('request.jwt.claim.sub', '', true);
do $$
declare r jsonb;
begin
  r := public.import_vixrex_blog_article_to_store(
    'katman3-test-a', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa4', 'adaptable_draft',
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
  );
  if coalesce((r->>'created')::boolean, false) is not true then
    raise exception 'Owner-session token yolu başarısız: %', r;
  end if;
end $$;

-- Kaynak silinince store snapshot ve slug provenance kalır, canlı FK null olur.
delete from public.vixrex_blog_articles where id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
do $$
declare c integer; source_id uuid; source_slug text;
begin
  select count(*), max(source_vixrex_blog_article_id::text)::uuid, min(source_vixrex_blog_article_slug)
    into c, source_id, source_slug
  from public.store_articles
  where store_slug='katman3-test-a'
    and source_vixrex_blog_article_slug='katman3-yayin-tam';

  if c <> 1 or source_id is not null or source_slug <> 'katman3-yayin-tam' then
    raise exception 'ON DELETE SET NULL/provenance hatalı: count=%, id=%, slug=%', c, source_id, source_slug;
  end if;
end $$;

-- Owner, mevcut store_articles RLS yoluyla oluşan taslağı düzenleyebilir.
select set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
set local role authenticated;
update public.store_articles
   set title='Esnaf tarafından uyarlanmış başlık'
 where store_slug='katman3-test-a'
   and source_vixrex_blog_article_slug='katman3-yayin-kisa';
reset role;

do $$
begin
  if not exists (
    select 1 from public.store_articles
    where store_slug='katman3-test-a'
      and source_vixrex_blog_article_slug='katman3-yayin-kisa'
      and title='Esnaf tarafından uyarlanmış başlık'
  ) then
    raise exception 'Mevcut owner CRUD/RLS ile düzenleme başarısız';
  end if;
end $$;

-- Public/anon taslak satırı göremez.
select set_config('request.jwt.claim.sub', '', true);
set local role anon;
do $$
declare c integer;
begin
  select count(*) into c
  from public.store_articles
  where store_slug='katman3-test-a';
  if c <> 0 then raise exception 'Anon draft store_articles gördü: %', c; end if;
end $$;
reset role;

-- RPC PUBLIC'e açık değildir; yalnız gerekli iki istemci rolü execute alır.
do $$
begin
  if exists (
    select 1
    from information_schema.routine_privileges
    where specific_schema = 'public'
      and routine_name = 'import_vixrex_blog_article_to_store'
      and grantee = 'PUBLIC'
      and privilege_type = 'EXECUTE'
  ) then
    raise exception 'PUBLIC import RPC execute yetkisi taşıyor';
  end if;
  if not has_function_privilege('anon', 'public.import_vixrex_blog_article_to_store(text,uuid,text,text)', 'EXECUTE') then
    raise exception 'anon owner-token yolu için execute yetkisi yok';
  end if;
  if not has_function_privilege('authenticated', 'public.import_vixrex_blog_article_to_store(text,uuid,text,text)', 'EXECUTE') then
    raise exception 'authenticated Flutter yolu için execute yetkisi yok';
  end if;
end $$;

rollback;
