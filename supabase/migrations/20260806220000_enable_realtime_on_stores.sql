-- Canlı senkron — stores tablosu için anlık dinleme açılır.
--
-- SORUN
-- Esnaf vitrinini iki yerden düzenleyebiliyor: uygulamadaki manuel panel
-- ve tarayıcıdaki Vixrex Asistan. Bir tarafta yayınladığı değişikliği
-- diğer taraf GÖRMÜYORDU. Uygulama yalnız açılışta buluta bakıyordu;
-- açıkken yapılan değişiklikten habersiz kalıyordu.
--
-- Kullanıcının kendi ifadesi (2026-08-06): "anlık veri 2 tarafa eşit bir
-- şekilde gidiyor mu baktım, gitmedi."
--
-- ÇÖZÜM
-- public.stores tablosu supabase_realtime yayınına eklenir. İki taraf da
-- kendi vitrin satırını dinler; biri yayınlayınca diğeri anında tazelenir.
--
-- KAPSAM — YALNIZ YAYINLANMIŞ VERİ
-- Yayınlanmamış taslaklar (store_working_drafts) buraya EKLENMEZ. O tablo
-- oturuma özeldir ve istemciye SELECT veren bir politikası yoktur; canlı
-- dinlemeye açmak sahip taslağını başkasına sızdırma riski doğurur.
-- Taslaklar zaten kasten ayrıdır: iki taraf birbirinin yarım işini görmez,
-- yayınlanan sonucu görür.
--
-- GÜVENLİK
-- Realtime, RLS'e uyar: istemci yalnız SELECT hakkı olduğu satırların
-- değişimini alır. stores üzerindeki mevcut politikalar aynen geçerlidir;
-- bu migration hiçbir yetki genişletmez.

-- Değişiklik yayınında satırın tamamı gitsin; istemci hangi alanın
-- değiştiğini anlayabilsin.
alter table public.stores replica identity full;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'stores'
  ) then
    alter publication supabase_realtime add table public.stores;
  end if;
end;
$$;
