-- Katman 2.5.2 — Blog RLS performans sertleştirmesi
-- Yetki davranışı değişmez. Supabase Performance Advisor'ın auth.uid()
-- initplan uyarısını gidermek için çağrı policy başına tek kez değerlendirilir.

-- vixrex_blog_articles admin policy'leri

drop policy if exists "Admins can read all Vixrex blog articles"
  on public.vixrex_blog_articles;
create policy "Admins can read all Vixrex blog articles"
  on public.vixrex_blog_articles
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.admins
      where admins.user_id = (select auth.uid())
    )
  );

drop policy if exists "Admins can insert Vixrex blog articles"
  on public.vixrex_blog_articles;
create policy "Admins can insert Vixrex blog articles"
  on public.vixrex_blog_articles
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.admins
      where admins.user_id = (select auth.uid())
    )
  );

drop policy if exists "Admins can update Vixrex blog articles"
  on public.vixrex_blog_articles;
create policy "Admins can update Vixrex blog articles"
  on public.vixrex_blog_articles
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.admins
      where admins.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.admins
      where admins.user_id = (select auth.uid())
    )
  );

drop policy if exists "Admins can delete Vixrex blog articles"
  on public.vixrex_blog_articles;
create policy "Admins can delete Vixrex blog articles"
  on public.vixrex_blog_articles
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.admins
      where admins.user_id = (select auth.uid())
    )
  );

-- vixrex_blog_article_relations admin policy'leri

drop policy if exists "Admins can read all Vixrex blog relations"
  on public.vixrex_blog_article_relations;
create policy "Admins can read all Vixrex blog relations"
  on public.vixrex_blog_article_relations
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.admins
      where admins.user_id = (select auth.uid())
    )
  );

drop policy if exists "Admins can insert Vixrex blog relations"
  on public.vixrex_blog_article_relations;
create policy "Admins can insert Vixrex blog relations"
  on public.vixrex_blog_article_relations
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.admins
      where admins.user_id = (select auth.uid())
    )
  );

drop policy if exists "Admins can update Vixrex blog relations"
  on public.vixrex_blog_article_relations;
create policy "Admins can update Vixrex blog relations"
  on public.vixrex_blog_article_relations
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.admins
      where admins.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.admins
      where admins.user_id = (select auth.uid())
    )
  );

drop policy if exists "Admins can delete Vixrex blog relations"
  on public.vixrex_blog_article_relations;
create policy "Admins can delete Vixrex blog relations"
  on public.vixrex_blog_article_relations
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.admins
      where admins.user_id = (select auth.uid())
    )
  );