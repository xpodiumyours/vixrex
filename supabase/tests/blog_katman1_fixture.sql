update public.vixrex_blog_articles
set status = 'published', published_at = now()
where slug = 'kuafor-icin-internet-sitesi';

do $$
begin
  if (select count(*) from public.vixrex_blog_articles where status = 'published') <> 1 then
    raise exception 'Yerel blog fixture beklenen tek yayın satırını üretmedi';
  end if;
end $$;
