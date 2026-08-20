-- #259: İade/chargeback durumu şemada takip edilmiyor.
--
-- SORUN: premium_orders.status yalnız pending/paid/failed biliyor.
-- 20260817030000_paytr_odeme_islemleri.sql ve 20260817040000_store_
-- premium_durumu.sql'de refund/chargeback alanı/mantığı yok — bir iade
-- veya chargeback olsa bunu şemada işaretlemenin hiçbir yolu bulunmuyor.
--
-- ÇÖZÜM: İki nullable kolon eklenir. `status` kolonuna VEYA onun mevcut
-- CHECK kısıtına (pending/paid/failed) DOKUNULMAZ — VIXREX_RULES §9
-- constraint değişikliklerini yüksek riskli sayar ve bu kısıt zaten canlı
-- ödeme akışının (create_premium_order/record_premium_payment) üzerine
-- oturuyor. Bunun yerine ayrı, kısıtsız bir takip alanı eklenir; beklenen
-- değer kümesi kolon yorumunda belgelenir, gerekirse uygulama katmanı
-- doğrular.
--
-- KAPSAM DIŞI (issue #259'un kendi notu, #240 ile ilişkili): bir iade/
-- chargeback olduğunda stores.premium_expires_at'in geri alınıp
-- alınmayacağı ayrı, henüz verilmemiş bir ürün kararı — bu migration
-- yalnız TAKİP ALANINI ekler, otomatik iptal mantığı yazmaz. PayTR'den
-- refund/chargeback bildirimini kimin/nasıl yazacağı (yeni webhook rotası
-- + RPC) da ayrı, daha büyük bir iş.

alter table public.premium_orders
  add column if not exists refund_status text,
  add column if not exists refunded_at timestamptz;

comment on column public.premium_orders.refund_status is
  'İade/chargeback takibi (#259). NULL = etkilenmedi. Beklenen değerler:
   ''refunded'' | ''chargeback''. Kısıt yoktur — status kolonundaki canlı
   ödeme CHECK''ine bilerek dokunulmadı, doğrulama uygulama katmanındadır.';

comment on column public.premium_orders.refunded_at is
  'refund_status dolduğu an. NULL = iade/chargeback yaşanmadı.';

-- Not: premium_orders üzerinde RLS zaten açık ve public/anon/authenticated
-- için grant yok (20260817000000_premium_sema.sql); yeni kolonlar aynı
-- tablo-seviyeli grant'ı (yalnız service_role) miras alır, ayrı bir grant
-- satırı gerekmez.

notify pgrst, 'reload schema';
