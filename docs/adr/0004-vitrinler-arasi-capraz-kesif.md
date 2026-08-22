# 0004 — Vitrinler arası çapraz keşif: kategori-dışı + esnaf onaylı

## Durum

Kabul edildi (2026-08-22). Sayısal parametreler (yarıçap, gösterilecek sayı) ve
sayfa içi yerleşim henüz kesinleşmedi — bkz. `docs/vitrinler-arasi-kesif.md` §4.

## Bağlam

VixRex'in müşteri trafiği bugün tamamen esnafın kendi getirdiği trafiğe
(Instagram, WhatsApp) dayanıyor; SEO ve "VixRex'i pazaryeri yapmak" ayrı,
büyük kararlar. Kodda doğrulandı: `v/[slug]` vitrin sayfasında başka hiçbir
VixRex vitrinine veya Keşfet'e link yok — her vitrin izole bir ada. "Keşfet"
bugün Flutter'da yaşıyor (`lib/screens/explore_screen.dart`), yani esnafın
kendi yönetim panelinde; müşteriyi oraya yönlendirmek hem yanlış bağlam
olurdu hem `VIXREX_RULES.md`'deki "vitrin görünümü yalnızca Next.js'te
render edilir" kuralına ters düşerdi.

Buradan çıkan fırsat: esnafın zaten getirdiği trafiği, reklam bütçesi veya
SEO beklemeden, diğer VixRex işletmelerine dağıtan düşük maliyetli bir
network-effect mekanizması.

## Karar

Vitrin sayfasına (yalnızca Next.js, `/v/:slug`), **aynı kategoriden olmayan**,
koordinat mesafesine göre en yakın birkaç VixRex işletmesini gösteren gömülü
bir kart şeridi eklenir (ayrı bir sayfa değil, mevcut sayfanın içinde).

- Aday havuzu: yayınlanmış (`is_published`), demo olmayan (`is_demo != true`),
  koordinatı (`latitude`/`longitude`) dolu mağazalar.
- Aynı kategori (`kategori`) hariç tutulur — amaç rakip önerisi değil, bölgedeki
  tamamlayıcı işletkileri göstermek; esnafın "müşterimi rakibe gönderiyorsun"
  tepkisini baştan önler.
- Esnaf isterse bu widget'ı kendi sayfasında kapatabilir; **varsayılan açık.**
- Yarıçap içinde uygun aday yoksa widget hiç render edilmez (boş kutu/mesaj
  gösterilmez) — vitrin kalitesi zedelenmesin diye.

## Reddedilen alternatifler

- **Keşfet'e yönlendirme:** Flutter'daki mevcut Keşfet ekranına link vermek —
  müşteri için yanlış bağlam (esnaf paneli), `VIXREX_RULES.md`'nin render
  kuralına ters.
- **Aynı kategoriyi de dahil etmek:** teknik olarak daha basit ama esnaf
  güvenini riske atar (doğrudan rakip önerisi).
- **Varsayılan kapalı (esnaf açmalı):** aynı geliştirme maliyeti ama özelliği
  fiilen ölü doğurur — kimse bilmediği bir anahtarı açmaz.

## Kapsam dışı / açık kalan

Yarıçap (öneri: 20 km) ve gösterilecek sayı (öneri: en yakın 3), sayfa içi
tam yerleşim (yalnız mağaza ana sayfası mı, ürün sayfası da mı), DB kolon adı
ve `shared/vitrin_alanlari.json` alan tanımı, checkbox'ın hangi panelde
duracağı — bunlar bu ADR'nin kapsamında değil, `docs/vitrinler-arasi-kesif.md`
içinde detaylandırılacak.
