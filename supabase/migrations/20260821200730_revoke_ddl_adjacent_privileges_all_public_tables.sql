-- ACİL (2026-08-21, canlıda bulundu ve canlıda kapatıldı — bu migration o
-- düzeltmenin dosyaya yazılmış hâlidir, uygulanınca no-op olur).
--
-- Bir önceki migration'da (20260821195828) stores tablosunda anon/
-- authenticated rollerine TRUNCATE/MAINTAIN/REFERENCES/TRIGGER tablo-
-- seviyesinde açık olduğu bulunmuştu. Şemanın tamamı tarandığında aynı
-- desenin NEREDEYSE TÜM tablolarda (18 tablo: audit_logs, appointments,
-- products, profiles, legal_documents, platform_settings, feature_flags,
-- store_working_drafts, product_categories, booking_settings,
-- booking_blocks, store_articles, store_category_image_usage,
-- store_instagram_connections, store_instagram_imports, article_reports,
-- appointment_reschedule_requests, xml_feeds ve bir yedek tablo) olduğu
-- görüldü.
--
-- TRUNCATE RLS'ten muaftır — bu hâliyle herkese açık anon anahtarla bu
-- tabloların neredeyse tamamı boşaltılabilirdi. PostgREST bu 4 yetkiyi
-- standart REST arayüzünden (GET/POST/PATCH/DELETE → SELECT/INSERT/
-- UPDATE/DELETE) hiçbir zaman kullanmaz — kaldırmak hiçbir uygulama
-- işlevini bozmaz, yalnız gereksiz saldırı yüzeyini kapatır.
--
-- Bu migration şemadaki tüm tablolara (mevcut) uygulanır. Gelecekte
-- eklenecek tablolar için de aynı disiplin (yeni migration'da açıkça
-- revoke) uygulanmalı — base şemadaki `alter default privileges` bu 4
-- yetkiyi zaten varsayılan olarak vermiyor (yalnız fonksiyonlar için
-- default privileges kullanılıyor, bkz. 20260815210000), risk yalnız
-- geçmişte kalan tablolardaydı.

do $$
declare
  r record;
begin
  for r in
    select c.relname
    from pg_class c
    where c.relnamespace = 'public'::regnamespace
      and c.relkind in ('r', 'p')
  loop
    execute format(
      'revoke truncate, maintain, references, trigger on table public.%I from anon, authenticated;',
      r.relname
    );
  end loop;
end $$;

notify pgrst, 'reload schema';
