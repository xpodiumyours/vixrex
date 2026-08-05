-- admins tablosunun okuma politikası kendi kendini sorguluyordu:
--
--   using (exists (select 1 from public.admins a where a.user_id = auth.uid()))
--
-- Yani "admins tablosunu okuyabilmek için admins tablosunu okumak" gerekiyordu.
-- PostgreSQL bunu "infinite recursion detected in policy for relation admins"
-- hatasıyla reddeder. Sonuç: vixrex-admin panelinin middleware'i admin satırını
-- okuyamıyor ve GERÇEK admin kullanıcı da giriş sayfasına geri atılıyordu.
--
-- Politika 20260622_add_google_visibility_and_blog.sql içinde oluşturulmuştu;
-- o migration DEĞİŞTİRİLMEDİ, düzeltme burada yapılıyor.
--
-- Yeni davranış: her giriş yapmış kullanıcı YALNIZ kendi satırını okuyabilir.
-- Bu, uygulamanın yaptığı tek sorgu tipini karşılar:
--   .from('admins').select('user_id').eq('user_id', <kendi id>)
-- vixrex-admin'deki dört kullanımın dördü de bu biçimde (middleware.ts,
-- lib/auth.ts x2, auth/callback/page.tsx). "Tüm adminleri listele" özelliği yok.
--
-- ETKİLENMEYENLER: diğer tabloların (stores, store_articles, vb.)
-- "exists (select 1 from public.admins ...)" politikaları farklı tablolar
-- üzerinde tanımlı olduğu için özyineleme oluşturmuyor; onlara dokunulmuyor.
--
-- GERİ DÖNÜŞ: bu migration'ı geri almak için:
--   drop policy if exists "Admins can view own admin row" on public.admins;
--   create policy "Admins can view admins" on public.admins
--     for select to authenticated
--     using (exists (select 1 from public.admins a where a.user_id = auth.uid()));
--   (Not: eski politika zaten bozuktu; geri alma yalnızca acil durum içindir.)

drop policy if exists "Admins can view admins" on public.admins;

create policy "Admins can view own admin row"
  on public.admins
  for select
  to authenticated
  using (user_id = (select auth.uid()));

comment on table public.admins is
  'Panel yöneticileri. Okuma politikası: kullanıcı yalnız kendi satırını görür.';
