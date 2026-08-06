-- 1. Create a trigger function to handle spam checks and rate limits
create or replace function public.on_article_spam_check()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_count int;
  v_banned_pattern text := '(bahis|casino|slot|escort|porn|porno|uyusturucu|silah|kumar)';
begin
  -- Check Rate Limit: Maximum 5 articles in 24 hours per store (Only on INSERT)
  if tg_op = 'INSERT' then
    select count(*) into v_count
    from public.store_articles
    where store_slug = new.store_slug
      and created_at > now() - interval '24 hours';
      
    if v_count >= 5 then
      raise exception 'STORE_ARTICLE_RATE_LIMIT_EXCEEDED: 24 saat içinde en fazla 5 yazı yayınlayabilirsiniz.' using errcode = 'P0001';
    end if;
  end if;

  -- Check Banned Keywords: Case-insensitive check on title, summary, content, topic, and city
  if (new.title ~* v_banned_pattern) or 
     (new.summary ~* v_banned_pattern) or 
     (new.content ~* v_banned_pattern) or
     (new.target_topic ~* v_banned_pattern) or
     (new.target_city ~* v_banned_pattern) then
    raise exception 'CONTENT_CONTAINS_BANNED_WORDS: İçeriğiniz yasaklı veya uygunsuz kelimeler barındırmaktadır.' using errcode = 'P0001';
  end if;

  return new;
end;
$$;

-- 2. Drop existing trigger if it exists and register the trigger on store_articles
drop trigger if exists trg_article_spam_check on public.store_articles;
create trigger trg_article_spam_check
before insert or update on public.store_articles
for each row
execute function public.on_article_spam_check();
