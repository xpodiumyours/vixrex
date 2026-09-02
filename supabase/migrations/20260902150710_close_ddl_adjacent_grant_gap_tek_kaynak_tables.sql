-- GRANT güvenlik bekçisi kırmızısı (2026-09-02): "tek-kaynak" refaktörüyle
-- eklenen owner_flow_states, assistant_conversations, assistant_messages
-- tabloları oluşturuldukları migration'larda hiç açık grant almamıştı
-- ("tabloya doğrudan grant yok" yorumu, bkz. 20260831204600/204700), ama
-- yine de anon/authenticated rollerinde TRUNCATE/MAINTAIN/REFERENCES/
-- TRIGGER vardı — çünkü bu 4 yetki, Supabase projelerinde tablolar için
-- platform seviyesinde varsayılan olarak veriliyor (bu repo'nun kontrol
-- ettiği bir şey değil), 20260821200730'da yalnız O ANKİ tablolara
-- REVOKE uygulanmıştı, gelecekteki tablolar için değil.
--
-- 20260821200730'un kendi yorumu bunu zaten öngörmüştü: "Gelecekte
-- eklenecek tablolar için de aynı disiplin (yeni migration'da açıkça
-- revoke) uygulanmalı" — ama bu, her yeni tablo migration'ında elle
-- hatırlanması gereken bir disiplin olarak bırakılmıştı ve şimdi (en az)
-- 4. kez unutuldu (2026-08-21 yorumunda 3 kez zaten sayılmıştı).
--
-- Bu migration iki şey yapıyor:
--   1) Mevcut 3 tabloyu 20260821200730 ile birebir aynı yöntemle temizler.
--   2) Kök sebebi kapatır: 20260815210000'in FONKSİYONLAR için yaptığını
--      (ALTER DEFAULT PRIVILEGES ile "postgres rolünün yarattığı her yeni
--      nesne artık kapalı doğar") burada TABLOLAR için ama yalnız bu 4
--      DDL-bitişik yetkiyle sınırlı olarak tekrarlar. SELECT/INSERT/
--      UPDATE/DELETE'e KASITLI OLARAK dokunulmuyor — 20260815210000'de
--      belgelendiği gibi Supabase'in geniş GRANT + dar RLS deseni CRUD
--      yetkileri için bilinçli bir mimari tercih; yalnız PostgREST'in
--      hiçbir zaman kullanmadığı ve RLS'ten muaf olan (TRUNCATE) bu 4
--      yetki kapatılıyor. Bundan sonra postgres rolünün public şemada
--      yarattığı HİÇBİR yeni tablo bu 4 yetkiyle doğmayacak — "yeni
--      migration'da elle hatırla" disiplinine bir daha bağımlı olunmuyor.

revoke truncate, maintain, references, trigger
  on table public.owner_flow_states,
            public.assistant_conversations,
            public.assistant_messages
  from anon, authenticated;

alter default privileges for role postgres in schema public
  revoke truncate, maintain, references, trigger on tables from anon, authenticated;

notify pgrst, 'reload schema';
