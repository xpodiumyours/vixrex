-- 20260930140000_ONCESI_KONTROL.sql
--
-- AMAÇ: Migration'lar UYGULANMADAN ÖNCE çalıştırılır. Hiçbir şeyi değiştirmez.
-- Sadece "SELECT" — sadece okur, veri yazmaz, tablo oluşturmaz.
--
-- Bu dosya migration değildir, uygulanmaz. Supabase SQL Editöründe
-- elle çalıştırılıp sonuca bakılır.
--
-- NASIL KULLANILIR
--   1. Bu dosyanın tamamını Supabase SQL Editörüne yapıştır ve ÇALIŞTIR.
--   2. Çıktıda "Beklenen" sütunundan farklı olan satır varsa migration'ı UYGULAMA.
--   3. Hepsi "Beklenen" ise migration sırasını uygula.
--
-- NEDEN: 20260929000000_fatura_islem_kaniti.sql içinde
-- `create unique index ... on invoice_jobs(store_id, document_fingerprint)`
-- var. Eğer bu tablo daha önce oluşturulmuşsa ve aynı (mağaza, parmak izi)
-- ikilisi iki kez kayıtlıysa, index oluşturma hata verir ve DOSYANIN TAMAMI
-- geri sarılır (migration'lar transaction içinde çalışır).


-- ─────────────────────────────────────────────────────────────────────────
-- KONTROL 1 — Fatura masaları daha önce oluşturulmuş mu?
-- Beklenen: 0 | 0 | 0 | 0 | 0
--   (0 ise masalar hiç yok → migration sıfırdan kuracak → güvenli)
-- ─────────────────────────────────────────────────────────────────────────
select 'invoice_jobs'                    as tablo, count(*) as mevcut from pg_tables where schemaname='public' and tablename='invoice_jobs'
union all select 'invoice_job_lines',            count(*) from pg_tables where schemaname='public' and tablename='invoice_job_lines'
union all select 'invoice_line_evidence',        count(*) from pg_tables where schemaname='public' and tablename='invoice_line_evidence'
union all select 'invoice_line_candidates',      count(*) from pg_tables where schemaname='public' and tablename='invoice_line_candidates'
union all select 'invoice_image_rights',         count(*) from pg_tables where schemaname='public' and tablename='invoice_image_rights'
union all select 'supplier_permissions',         count(*) from pg_tables where schemaname='public' and tablename='supplier_permissions'
union all select 'supplier_permission_requests',  count(*) from pg_tables where schemaname='public' and tablename='supplier_permission_requests'
union all select 'supplier_permission_products',  count(*) from pg_tables where schemaname='public' and tablename='supplier_permission_products'
order by 1;


-- ─────────────────────────────────────────────────────────────────────────
-- KONTROL 2 — Ürün tablosunda kanıt kolonu var mı?
-- Beklenen: 0
--   (1 ise 20260930000000 daha önce uygulanmış → tekrar çalıştırmak güvenli,
--    hepsi "if not exists" korumalı → yine de 1. dosyayı atlayabilirsin)
-- ─────────────────────────────────────────────────────────────────────────
select count(*) as fatura_kanit_kolonu
from information_schema.columns
where table_schema='public' and table_name='products' and column_name='fatura_kanit';


-- ─────────────────────────────────────────────────────────────────────────
-- KONTROL 3 — Tekrar eden kayıt var mı?  (SİRALAMA HATASI KORUMASI)
-- Beklenen: 0 satır
--   (satır varsa benzersizlik kuralı 20260929000000'de takılır)
--
--   invoice_jobs tablosu yoksa bu sorgu hata verir — bu NORMAL'dir,
--   1 numaralı kontrol zaten "0" dediyse bu adımı atlayıp 4'e geç.
-- ─────────────────────────────────────────────────────────────────────────
select store_id, document_fingerprint, count(*) as tekrar
from public.invoice_jobs
where document_fingerprint is not null
group by store_id, document_fingerprint
having count(*) > 1;


-- ─────────────────────────────────────────────────────────────────────────
-- KONTROL 4 — Yayınlama fonksiyonu var mı?
-- Beklenen: 1 satır, proargnames = {p_product_id,p_edit_token}
--   (yoksa 20260930000000 henüz uygulanmamış → normal)
-- ─────────────────────────────────────────────────────────────────────────
select p.proname, p.proargnames
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname='public' and p.proname in ('publish_invoice_product','fatura_yayin_kilidi');


-- ─────────────────────────────────────────────────────────────────────────
-- KONTROL 5 — Yayınlama tetikleyicisi var mı?
-- Beklenen: 1 satır, tgname = fatura_yayin_kilidi
-- ─────────────────────────────────────────────────────────────────────────
select t.tgname
from pg_trigger t
where t.tgrelid = 'public.products'::regclass
  and not t.tgisinternal;
