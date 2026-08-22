# Vitrinler Arası Çapraz Keşif (Komşu İşletmeler Widget'ı)

> `/grill-with-docs` oturumunda netleşen ürün kararı taslağı. Karar tarihi: 2026-08-22.
> Bu bir kural değil; uygulanacak çalışma ilgili GitHub issue'sunda planlanır (henüz açılmadı).
> Mimari karar: [[0004-vitrinler-arasi-capraz-kesif]].

## 1. Hedef

Esnafın kendi getirdiği trafiği (Instagram, WhatsApp) tek bir vitrinde
hapsetmek yerine, reklam bütçesi veya SEO beklemeden diğer VixRex
işletmelerine de dağıtmak — düşük maliyetli bir network-effect.

**Bu bir SEO veya pazaryeri projesi değil.** Google organik trafiği
(`docs/google-gorunurluk.md`) ve VixRex'i pazaryeri yapmak ayrı, büyük
kararlar; bu widget bugün var olan trafiği yeniden dağıtan küçük bir ek.

## 2. Bugünkü durum (bulgu, bu oturumda doğrulandı)

- `v/[slug]` vitrin sayfasında başka hiçbir VixRex vitrinine veya Keşfet'e
  link yok (repo genelinde grep ile doğrulandı) — her vitrin izole.
- "Keşfet" bugün yalnız Flutter'da yaşıyor (`lib/screens/explore_screen.dart`),
  esnafın kendi yönetim paneli — müşteri için yanlış bağlam.
- Canlı DB (`chfulefxczbgurtgavtp`, 2026-08-22 kontrolü): yayınlanmış 9
  vitrinin tamamı `is_demo = true`; **gerçek (demo olmayan) yayınlanmış
  vitrin: 0.** `is_demo = false` olan 15 kayıt var, hepsi `kiralik-*`/`demo-*`
  şablon denemesi, hiçbiri yayınlanmamış.
- Aynı DB'de demo verisinde koordinat (`latitude`/`longitude`) doluluğu
  %100 (9/9), `district_name`/`province_name` doluluğu %55 (5/9) — mesafe
  hesaplamak için koordinat, il/ilçe metnine göre daha güvenilir.

## 3. Kararlar (bu oturumda netleşti)

| Karar noktası | Seçilen | Gerekçe |
|---|---|---|
| Mekanizma şekli | Vitrin sayfasının içine gömülü kart şeridi, ayrı sayfa yok | Keşfet'e yönlendirmek yanlış bağlam + render kuralına ters; ayrı sayfa büyük iş (SEO/boş durum problemi taşır) |
| Kategori kuralı | Aynı kategori (`kategori`) hariç tutulur | Rakip önerisi değil, tamamlayıcı işletme önerisi; esnaf güveni riskini önler |
| Esnaf kontrolü | Esnaf kapatabilir, **varsayılan açık** | Sıfır ek geliştirme maliyeti (aynı kolon), esnafın sözünü koruma (`VIXREX_RULES.md` "istek dışı ürün değişikliği yok") + ölü-özellik riskini önleme dengesi |
| Yakınlık tanımı | Koordinat mesafesi (km); koordinatsız mağaza aday değil | Veri doluluğu koordinatta daha güvenilir; tek bir eşleştirme mantığı (il/ilçe fallback'i yok) |
| Aday yoksa davranış | Widget hiç render edilmez, boş durum mesajı yok | Vitrin kalitesi hedefiyle çelişmesin — "burada daha kimse yok" itirafı yapılmaz |

## 4. Açık kalan noktalar — detaylandırılacak

Bunlar bu oturumda **kesinleşmedi**, sadece öneri olarak konuşuldu:

- **Yarıçap ve gösterilecek sayı:** öneri 20 km / en yakın 3 — teyit edilmedi.
- **Sayfa içi tam yerleşim:** yalnız mağaza ana sayfası (`v/[slug]`) mı,
  ürün detay sayfası (`v/[slug]/urun/[productSlug]`) da mı gösterilecek —
  hiç konuşulmadı.
- **DB/şema detayları:** yeni boolean kolon adı (`stores` tablosunda),
  `shared/vitrin_alanlari.json`'a eklenecek alan tanımı, kapatma anahtarının
  hangi panelde (Vixrex Asistan / Flutter manuel panel) duracağı.
- **Sıralama/tekrar ziyaret davranışı:** her ziyarette aynı N işletki mi
  gösterilir, rotasyon var mı.
- **Ölçek/performans:** bugün aday havuzu 0, indeks ihtiyacı ölçek
  büyüyünce netleşecek.
- **Karşılıklılık kenar durumu:** bir mağaza kapattıysa (opt-out), hem
  kendi sayfasında widget kapanır hem başka sayfaların önerisinde hiç
  çıkmaz — bu örtük kabul edildi ama ayrıca yazılı teyit edilmedi.

## 5. Ne zaman yapılmalı

Bugün DB'de gerçek yayınlanmış vitrin yok — bu özelliğin gerçek etkisi
ancak birkaç gerçek işletme yayına girdikten sonra ölçülebilir
(`docs/google-gorunurluk.md` §6'daki aynı gerçeklik notu burada da geçerli).
Kod tarafı, gerçek işletme sayısından bağımsız olarak şimdiden yazılabilir.

## İlgili

- Mimari karar: [[0004-vitrinler-arasi-capraz-kesif]]
- İlişkili ama ayrı kararlar: [[google-gorunurluk]] (SEO), pazaryeri yönü
  (henüz belgelenmedi, ayrı büyük karar)
