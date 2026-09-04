-- Katman 1.1 — Vixrex merkezi blog veri omurgası
--
-- NEDEN AYRI TABLO:
-- `store_articles` bir esnaf vitrinine `store_slug` ile bağlıdır. Vixrex'in
-- platform yazılarını sahte bir vitrine bağlamamak ve owner RLS semantiğini
-- bozmamak için merkezi içerik ayrı tabloda tutulur.

create table if not exists public.vixrex_blog_articles (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  summary text not null default '',
  content text not null default '',
  cover_image_url text,
  status text not null default 'draft',
  reading_minutes integer not null default 1,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint vixrex_blog_articles_slug_format_check
    check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  constraint vixrex_blog_articles_title_not_blank_check
    check (length(btrim(title)) > 0),
  constraint vixrex_blog_articles_status_check
    check (status in ('draft', 'published')),
  constraint vixrex_blog_articles_reading_minutes_check
    check (reading_minutes between 1 and 120),
  constraint vixrex_blog_articles_published_at_check
    check (status <> 'published' or published_at is not null)
);

create index if not exists idx_vixrex_blog_articles_published
  on public.vixrex_blog_articles (status, published_at desc nulls last);

alter table public.vixrex_blog_articles enable row level security;

-- Tablo ayrıcalıkları RLS ile birlikte dar tutulur.
revoke all on table public.vixrex_blog_articles from public;
grant select on table public.vixrex_blog_articles to anon;
grant select, insert, update, delete on table public.vixrex_blog_articles to authenticated;
grant all on table public.vixrex_blog_articles to service_role;

-- Public yalnız yayınlanmış içerikleri okuyabilir.
drop policy if exists "Public can read published Vixrex blog articles"
  on public.vixrex_blog_articles;
create policy "Public can read published Vixrex blog articles"
  on public.vixrex_blog_articles
  for select
  to anon, authenticated
  using (status = 'published');

-- Platform adminleri taslak dahil okuyabilir ve yönetebilir.
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
      where admins.user_id = auth.uid()
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
      where admins.user_id = auth.uid()
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
      where admins.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.admins
      where admins.user_id = auth.uid()
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
      where admins.user_id = auth.uid()
    )
  );

-- updated_at uygulama koduna bağlı kalmadan doğru kalsın.
create or replace function public.set_vixrex_blog_articles_updated_at()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  new.updated_at := pg_catalog.now();
  return new;
end;
$$;

revoke all on function public.set_vixrex_blog_articles_updated_at()
  from public, anon, authenticated;

drop trigger if exists trg_vixrex_blog_articles_updated_at
  on public.vixrex_blog_articles;
create trigger trg_vixrex_blog_articles_updated_at
before update on public.vixrex_blog_articles
for each row execute function public.set_vixrex_blog_articles_updated_at();

-- Mevcut iki Vixrex blog taslağını kod dosyasından kalıcı modele taşı.
-- İkisi de taslak kalır; public yüzeye bu migration ile hiçbir yazı açılmaz.
insert into public.vixrex_blog_articles (
  slug,
  title,
  summary,
  content,
  status,
  reading_minutes,
  published_at,
  created_at,
  updated_at
)
values
(
  'kuafor-icin-internet-sitesi',
  'Kuaför salonu için internet sitesi nasıl yapılır?',
  'Kuaför ve berber salonları için internet sitesinin ne işe yaradığını, hangi bilgilerin bulunması gerektiğini ve bunu ücretsiz nasıl yapabileceğinizi adım adım anlattık.',
  $vixrex_blog$Bir kuaför salonunun internet sitesine ihtiyacı var mı? Kısa cevap: evet, ama sandığınız türden değil.

Müşteriniz size gelmeden önce üç şeyi merak eder: nerede olduğunuzu, ne kadar tuttuğunu ve nasıl randevu alacağını. Onlarca sayfalık bir site kurmanıza gerek yok. Bu üç sorunun cevabını taşıyan tek bir sayfa, çoğu salon için fazlasıyla yeterlidir.

Sayfanızda mutlaka bulunması gerekenler

Salonunuzun adı ve ne yaptığınız. "Ayşe Kuaför — kadın kuaförü, saç bakımı ve gelin saçı" gibi tek cümle yeterli. İnsanlar bunu okuduğunda doğru yerde olduklarını anlamalı.

Açık adres ve harita konumu. Semt adı yazmak yetmez; müşteri telefonundan haritaya dokunup yola çıkabilmeli.

Telefon veya WhatsApp bağlantısı. Randevu almanın en kısa yolu bu. Numarayı düz yazı olarak koymayın, dokununca arayan ya da WhatsApp açan bir bağlantı olsun.

Çalışma saatleri. "Pazartesi kapalı" bilgisini görmeyen müşteri boşuna yola çıkar ve bir daha gelmez.

Hizmetler ve fiyatlar. Fiyat yazmaktan çekinmeyin. Fiyat görmeyen müşteri en pahalı ihtimali varsayar ve aramaz bile.

Çalışmalarınızdan fotoğraflar. Kuaförlükte en güçlü satış aracı budur. Beş temiz fotoğraf, uzun bir metinden çok daha fazla iş getirir.

Alan adı almalı mısınız?

Başlangıçta gerek yok. Önce sayfanızı kurun, müşterilere gönderin, işe yarayıp yaramadığını görün. İşler yürüdüğünde kendi alan adınıza geçmek her zaman mümkün.

Instagram hesabım var, yetmez mi?

Instagram müşteri bulmak için iyidir ama bilgi vermek için kötüdür. Adresiniz nerede yazıyor? Fiyatlarınız hangi gönderinin altında kaldı? Instagram'ı vitrin sayfanıza yönlendiren bir tabela gibi düşünün: insanlar sizi orada görsün, ayrıntıyı sayfanızda bulsun.

Ne kadar sürer?

Vixrex ile bir vitrin sayfası kurmak yaklaşık on dakika sürüyor. Bilgileri yazıyorsunuz, fotoğrafları yüklüyorsunuz, sayfa yayına giriyor. Kod bilmenize, tasarımcı tutmanıza gerek yok.$vixrex_blog$,
  'draft',
  4,
  null,
  '2026-09-01T00:00:00+00'::timestamptz,
  '2026-09-01T00:00:00+00'::timestamptz
),
(
  'isletmemi-googleda-nasil-gosteririm',
  'İşletmemi Google''da nasıl gösteririm?',
  'Küçük bir işletmenin Google aramalarında çıkması için yapması gereken üç şey var. Üçü de ücretsiz ve hiçbiri teknik bilgi gerektirmiyor.',
  $vixrex_blog$"İşletmemin adını yazıyorum, Google'da çıkmıyorum." Küçük işletmelerin en sık sorduğu soru bu. Sebebi genellikle tek: Google'ın bakabileceği bir yer yok.

Google bir işletmeyi rastgele bulmaz. Sizi ancak internette bıraktığınız izlerden tanır. Üç iz yeterlidir.

1. Google İşletme Profili açın

Ücretsizdir ve en önemlisidir. Haritalarda çıkmanızı, "yakınımdaki kuaför" gibi aramalarda görünmenizi, yorum toplamanızı sağlar.

google.com/business adresinden açabilirsiniz. İşletme adı, kategori, adres, telefon ve çalışma saatlerini girin. Google adresinize kod içeren bir kart gönderir; o kodu girince profiliniz onaylanır.

Burada en çok yapılan hata kategoriyi yanlış seçmek. "Güzellik salonu" ile "kuaför" farklı aramalara çıkar. Müşterinizin sizi ararken yazacağı kelimeyi seçin.

2. Kendi sayfanız olsun

İşletme profili tek başına eksik kalır. Google, işletmenizin gerçek olduğunu doğrulamak için başka bir kaynak arar. Kendi vitrin sayfanız bu kaynaktır.

Sayfada adınız, adresiniz ve telefonunuz Google İşletme Profili'ndeki ile birebir aynı şekilde yazmalı. "Cad." ile "Caddesi" farkı bile Google'ı tereddüde düşürür. Aynı bilgiyi aynı biçimde yazmak, bu işin en ucuz ve en etkili adımıdır.

3. İnsanların aradığı kelimeleri kullanın

Kimse "estetik saç tasarım merkezi" diye aramaz. "Ümraniye kuaför" diye arar.

Sayfanızdaki metinlerde müşterinin kullandığı kelimeleri kullanın: semt adı, iş kolu, sunduğunuz hizmet. Süslü ifadeler arama motorunda işe yaramaz.

Ne kadar sürede çıkarım?

Google İşletme Profili onayı birkaç gün sürer. Vitrin sayfanızın aramalarda görünmesi genellikle bir ila dört hafta alır. Bu süreyi kısaltmanın yolu yok, ama üç adımı da tamamlamak sonucu belirgin biçimde hızlandırır.

Sabırsızlanmayın: profilinizi açtıktan sonra bilgileri sürekli değiştirmek Google'ı yavaşlatır. Bir kere doğru girin, bırakın otursun.$vixrex_blog$,
  'draft',
  4,
  null,
  '2026-09-01T00:00:00+00'::timestamptz,
  '2026-09-01T00:00:00+00'::timestamptz
)
on conflict (slug) do nothing;