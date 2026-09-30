-- 20260930140000_fatura_yayin_kapisi_sertlestirme.sql
--
-- 30 Eylül 2026 güvenlik incelemesi sonucu eklendi. Kod davranışını DEĞİŞTİRMEZ;
-- yalnızca yetki sızıntısını kapatır ve depo standardına uygun hale getirir.
--
-- 1) publish_invoice_product yalnızca sunucudan çağrılıyor
--    (yalnız /api/fatura-yayinla → productCoreServer.ts:270).
--    Tarayıcı ve telefon bu RPC'ye dogrudan ulaşmıyor (flutter taraması boş).
--    Migration `anon`'a da EXECUTE vermişti; bu, edit_token'ı bilen bir istemcinin
--    satır bazlı ön kontrolleri atlayıp RPC'yi doğrudan çağırmasına izin veriyordu.
--    Fonksiyon içindeki fiyat/görsel/stok/kanıt kapıları yine çalıştığı için bu
--    tam bir delik değildi; yine de "yalnız bu kapıdan yayınlanır" sözünü
--    uygulama disiplinine değil veritabanına bağlıyordu. Şimdi bağlandı.
--
-- 2) fatura_yayin_kilidi() tetikleyici fonksiyonu için depo standardı:
--    set search_path + owner to postgres
--    (aynı desen: 20260920140000_urun_gorsel_yayin_kapisi.sql)

-- --- 1) Dışarıdan çağrıyı kapat -------------------------------------------
revoke execute on function public.publish_invoice_product(uuid, text) from public;
revoke execute on function public.publish_invoice_product(uuid, text) from anon;
revoke execute on function public.publish_invoice_product(uuid, text) from authenticated;

-- Sunucu service_role ile çağırıyor; bu yetki AÇIK kalmalı.
grant execute on function public.publish_invoice_product(uuid, text) to service_role;

-- --- 2) Tetikleyici fonksiyonu sertleştir ---------------------------------
-- SECURITY DEFINER değil; yalnız arama yolu sabitleniyor ve sahiplik netleşiyor.
alter function public.fatura_yayin_kilidi() set search_path = pg_catalog, public;
alter function public.fatura_yayin_kilidi() owner to postgres;

-- Tetikleyici yeniden kurulmaz; yalnız tanım sertleştirilir.
-- (fatura_yayin_kilidi trigger'ı 20260930000000'de oluşturuldu; burada dokunulmaz.)

-- --- 3) PostgREST şema önbelleğini tazele ---------------------------------
-- Bu 6 dosyada yoktu; 20260920140000 ve 20260822162238 içinde var.
-- Uygulama sonrası PostgREST'in yeni kolonları görmesi için gerekir.
notify pgrst, 'reload schema';
