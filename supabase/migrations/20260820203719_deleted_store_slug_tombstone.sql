-- #266 / #244: Vitrin silinirse eski URL için hiçbir iz kalmıyor.
--
-- SORUN (kod taramasıyla doğrulandı, 2026-08-20):
-- - #244 "slug yayından sonra değişebiliyor mu?" → HAYIR. `slug`
--   vitrinFieldSchema.ts'e hiç girmiyor (docs/vitrin-alan-semasi.md §7,
--   sahibin düzenleyemeyeceği alanlar), update_working_draft_field yalnız
--   şemadaki anahtarları yazabiliyor, store_publish_service.dart da
--   zaten dolu olan data.slug'ı yeniden kullanıyor (_allocateUniqueSlug
--   yalnız slug BOŞSA ya da çakışıyorsa devreye giriyor). Yani slug
--   pratikte yayından sonra değiştirilemiyor — bu migration'ın konusu
--   değil, yalnız doğrulama notu.
-- - #266 "vitrin silinirse ne olur?" → stores satırı gerçekten kalıcı
--   silinebiliyor (delete_user_account(), temel şema). Satır silinince
--   slug de tamamen yok oluyor; /v/:slug o andan sonra Next.js'in genel
--   notFound() (404) sayfasına düşüyor ve arama motoruna "belki geri
--   gelir" sinyali veriyor — oysa vitrin GERÇEKTEN gitti. Bunu daha
--   net bir sinyale (ör. 410 Gone, veya "bu vitrin artık yok" mesajı)
--   çevirebilmek için önce "bu slug daha önce var mıydı, silindi mi"
--   bilgisinin BİR YERDE durması gerekiyor — bugün hiç durmuyor,
--   silinen satırla birlikte kalıcı olarak kayboluyor.
--
-- ÇÖZÜM: Silinmeden ÖNCE slug'ı ayrı, küçük bir "mezar taşı" (tombstone)
-- tablosuna yazan bir BEFORE DELETE tetikleyicisi.
--
-- NEDEN delete_user_account()'IN GÖVDESİ DEĞİŞTİRİLMEDİ: o fonksiyon
-- daha önce bir kez canlı uçtan uca testte kırılgan çıkmıştı
-- (20260818080000_fix_delete_user_account_missing_tables.sql — eksik iki
-- tabloya DELETE denemesi). Bu oturumda gerçek bir Postgres'e karşı test
-- imkanı yok (docker/dart SDK'sı kurulu değil) — üstüne ekleme riski
-- almak yerine, hangi yoldan silinirse silinsin (bugün tek yol
-- delete_user_account, yarın başka bir yol eklenirse de) çalışan,
-- fonksiyon gövdesinden tamamen bağımsız bir tetikleyici tercih edildi.
--
-- GÜVENLİK — tetikleyici asıl silme işlemini ASLA engellemez: mezar taşı
-- yazımı bir exception handler içinde; INSERT her nasılsa başarısız
-- olursa hesap/vitrin silme yine de tamamlanır (sessizce mezar taşı
-- eksik kalır — bu, hesap silmeyi bloke etmekten kesinlikle daha iyi).
--
-- KAPSAM DIŞI: Next.js tarafında bu tabloyu okuyup 410/özel mesaj
-- döndürmek ayrı bir iş — App Router'da bir page.tsx'in notFound() dışında
-- özel bir HTTP durum kodu döndürmesi middleware gerektiriyor, bu ayrı,
-- kendi başına test edilmesi gereken bir değişiklik. Bu migration yalnız
-- kaybolmadan ÖNCE kalıcı olarak yakalanması gereken veriyi (slug + silme
-- anı) şimdi yakalar — geri dönüşü olmayan kısım budur, tüketen taraf her
-- zaman sonradan eklenebilir.

create table if not exists public.deleted_store_slugs (
  slug text primary key,
  deleted_at timestamptz not null default now()
);

comment on table public.deleted_store_slugs is
  'Silinen stores satırlarının slug mezar taşı (#266). /v/:slug bu tabloyu
   okuyup 404 yerine daha net bir "gitti" sinyali dönebilir — bu migration
   yalnız veriyi yakalar, tüketen taraf ayrı bir iştir. RLS açık, politika
   yok: yalnız service_role veya SECURITY DEFINER tetikleyicisi yazar.';

comment on column public.deleted_store_slugs.deleted_at is
  'Silinme anı. Aynı slug ile ikinci bir tombstone denemesi (teorik —
   normalde stores.slug unique) bu alanı günceller, yeni satır açmaz.';

alter table public.deleted_store_slugs enable row level security;

-- Yeni tablolara PostgreSQL varsayılan olarak PUBLIC'e yetki vermez, ama
-- 20260817000000_premium_sema.sql'deki disiplin gereği açıkça güvence
-- altına alınır (grant satırı yok ≠ kapalı değildir).
revoke all on table public.deleted_store_slugs from public, anon, authenticated;
grant all on table public.deleted_store_slugs to service_role;

create or replace function public.tombstone_deleted_store_slug()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  -- İç blok kasıtlı: EXCEPTION yalnız kendi BEGIN/END'ine bağlı olabilir;
  -- RETURN dış bloktan (buradan) gitmeli, yoksa geçersiz sözdizimi olur.
  begin
    insert into public.deleted_store_slugs (slug)
    values (old.slug)
    on conflict (slug) do update set deleted_at = now();
  exception when others then
    -- Mezar taşı yazımı ASLA silme işlemini engellemez. Bugün tek çağıran
    -- delete_user_account() zaten SECURITY DEFINER — bu fonksiyon çağıran
    -- rolden bağımsız çalışsın diye ayrıca sabitlendi, ama asıl güvence bu
    -- exception handler: en kötü ihtimalle mezar taşı eksik kalır, hesap
    -- silme yine de tamamlanır.
    null;
  end;
  return old;
end;
$$;

comment on function public.tombstone_deleted_store_slug() is
  'stores satırı silinmeden hemen önce slug''ı deleted_store_slugs''a
   yazar. Mezar taşı yazımı başarısız olsa bile (exception yutulur) silme
   işlemini engellemez — bkz. fonksiyon gövdesindeki not.';

drop trigger if exists trg_stores_tombstone_slug on public.stores;
create trigger trg_stores_tombstone_slug
  before delete on public.stores
  for each row execute function public.tombstone_deleted_store_slug();

notify pgrst, 'reload schema';
