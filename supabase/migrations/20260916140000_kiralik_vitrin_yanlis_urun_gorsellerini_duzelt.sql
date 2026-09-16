-- Kiralik/demo vitrinlerde urunle ortusmeyen fotograflari degistir.
--
-- NEDEN (2026-09-16): canli vitrinler telefon boyutunda tek tek incelendi.
-- Alti karttaki gorsel urunle ilgisizdi; ikisi ayrica marka riski tasiyordu.
-- Yeni gorsellerin her biri secilmeden once indirilip goz ile dogrulandi.
--
-- Eski -> yeni:
--   pijama takimi   : vazolar        -> askida pijama takimi
--   el yapimi canta : marka logolu   -> logosuz kahverengi deri canta
--   zeytin karma    : hamburger      -> kaselerde zeytin
--   Samsung ekran   : iPhone         -> Samsung telefon
--   MacBook klavye  : Dell/Windows   -> gumus MacBook klavye
--   iPad ekran      : telefon        -> iPad + kalem
--
-- Eslesme urun adi yerine ESKI GORSEL KIMLIGI uzerinden yapiliyor: boylece
-- demo vitrinlerin kiralanmis kopyalari da ayni duzeltmeyi aliyor.

with esleme(eski, yeni) as (
  values
    ('photo-1631125915902-d8abe9225ff2','https://images.unsplash.com/photo-1768696082915-bdc6774f94c7?w=600&q=80'),
    ('photo-1548036328-c9fa89d128fa','https://images.unsplash.com/photo-1691480150204-66dd1eb77391?w=600&q=80'),
    ('photo-1541544741938-0af808871cc0','https://images.unsplash.com/photo-1706378398576-57a21244ef7a?w=600&q=80'),
    ('photo-1565849904461-04a58ad377e0','https://images.unsplash.com/photo-1705585174953-9b2aa8afc174?w=600&q=80'),
    ('photo-1588872657578-7efd1f1555ed','https://images.unsplash.com/photo-1512296014055-b49bbcd707d2?w=600&q=80'),
    ('photo-1601784551446-20c9e07cdbdb','https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=600&q=80')
),
hedef as (
  select p.id, e.yeni
  from public.products p
  join esleme e on (p.image_urls->>0) like '%' || e.eski || '%'
)
update public.products p
set image_urls = jsonb_set(p.image_urls, '{0}', to_jsonb(hedef.yeni), true),
    updated_at = now()
from hedef
where hedef.id = p.id;
