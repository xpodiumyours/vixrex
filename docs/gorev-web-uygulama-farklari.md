# Görev tarifi — web ana sayfası ile uygulama açılış ekranı arasındaki farkları kapat

**Yazan:** Claude (26 Ağustos 2026) · **Yürüten:** ücretsiz modeller · **Doğrulayan:** Claude

## Neden

26 Ağustos'ta iki ekran yan yana açıldı ve karşılaştırıldı:

- Web (dal önizlemesi): `https://vixrex-public-git-feat-vixrex-core-555a4d-xpodiumyours-projects.vercel.app`
- Uygulama (canlı): `https://vixrex-app.vercel.app`

Metinler aynı — bunu `public_web/tests/landing-esitlik-contract.test.ts` zaten
bekliyor. Ama **görünüm aynı değil.** Web sayfası uygulamanın yanında eksik ve
sönük duruyor. Aşağıdaki dört fark, o karşılaştırmada gözle görülen ve kaynak
koddan doğrulanan farklardır.

**Hedef "piksel piksel aynı" değil.** Telefon uygulaması dar ve uzun, web geniş.
Hedef şu: aynı bölümler, aynı içerik yoğunluğu, aynı görsel zenginlik. Web'e
bakan biri "aynı ürünün web hâli" demeli, "eksik bir kopya" değil.

## Sıra

Küçükten büyüğe. Her görev ayrı dal, ayrı PR. Sıra atlanmayacak — küçük
görevler ısınma değil, büyük görevde kullanılacak zemini kuruyor.

---

## Standing kısıt — okumadan başlama

`.github/scripts/verify_pr_scope.py`: 12 dosyayı veya 600 satırı aşan bir PR,
açıklamasında `Kapsam-Onay:` satırı yoksa CI'yı kırmızıya düşürür. Görev 1-3
bu sınırın çok altında. Görev 4 sınırı aşabilir; aşarsa PR açıklamasına
`Kapsam-Onay:` satırı gerekçesiyle yazılır.

Her görevin sonunda çalıştırılacak ve **çıktısı gösterilecek**:

```
cd public_web && npm run lint && npm test && npm run build
```

Görev 4'te ek olarak `flutter analyze lib/ && flutter test` (Flutter'a
dokunulmasa bile regresyon kapısı).

**"Testler yeşil" demek yetmez.** Bu depoda yeşil testle kırık ekran yaşandı.
Her görevin sonunda `npm run dev` ile sayfayı gerçekten aç, ilgili bölümün
ekran görüntüsünü al ve göster.

---

# Görev 1 — Arka plan parıltısı

**Etki: yüksek. Risk: yok.** Sayfanın sönük görünmesinin ana sebebi bu.

## Fark

Uygulamada hero bölümünün arkasında üç yumuşak renkli ışık dairesi var ve
yavaşça hareket ediyorlar. Web'de düz siyah zemin var, hiçbir şey yok.

Kaynak: `lib/widgets/landing/landing_hero_section.dart:65-100` (`Ambient Mesh
Glows`) ve yardımcı `_buildMeshGlow()` (satır 653-662).

Uygulamadaki üç daire:

| # | Renk | Saydamlık | Boyut | Konum |
|---|---|---|---|---|
| 1 | `AppColors.primary` (#147DFF) | 0.30 | 300 | üst 100, sol -100 |
| 2 | `blueAccent` | 0.25 | 400 | alt 50, sağ -50 |
| 3 | `pinkAccent` (#8B5CF6) | 0.20 | 250 | üst 200, sağ 150 |

Her biri dairesel bir `RadialGradient` — merkezde renk, kenarda tam saydam.
Konumlar `sin`/`cos` ile yavaşça salınıyor.

Hero bölümünün kendi zemini ayrıca `bgEditor` → `bgLight` (#050B1A → #08132D)
doğrusal geçişi.

## Yapılacak

`public_web/src/components/landing/HeroSection.tsx` içine, mevcut içeriğin
**arkasına** üç daire ekle. Saf CSS — `radial-gradient` ile.

Kurallar:

- **Hareket eklenmeyecek.** Uygulamadaki salınım güzel ama web'de görsel
  regresyon testlerini sonsuza kadar oynatır. Daireler sabit duracak;
  uygulamadaki salınımın **orta noktası** kullanılacak.
  Bu bilinçli sapmayı dosyanın başına gerekçesiyle yaz.
- Renkler `lp-*` tokenlarından gelecek, elle onaltılık yazılmayacak.
  Gereken token yoksa `globals.css`'e **ekleyerek** aç, mevcut hiçbir
  değeri değiştirme.
- Daireler `pointer-events: none` ve `aria-hidden` olacak.
- Taşma yapmayacak: hero bölümü `overflow-hidden` olmalı, yoksa yatay
  kaydırma çubuğu çıkar. Bunu dar ekranda (390px) gerçekten kontrol et.

## Doğrulama

- 1280px ve 390px genişlikte ekran görüntüsü al, göster.
- Sayfanın yatay kaydırma çubuğu **olmadığını** doğrula.
- `npm test` yeşil.

---

# Görev 2 — Maskot balonu metni

**Etki: düşük. Risk: yok. Çok küçük iş.**

## Fark

Uygulamada maskotun yanındaki balon: `👋 Dijital vitrinini hazırlayayım mı?`
(kaynak: `lib/widgets/chatbot_badge.dart:127`)

Web'de: `Vitrinini birlikte kuralım — başlamak için dokun.`
(kaynak: `public_web/src/components/landing/MascotFab.tsx:27`)

Farklı metinler. Eşitlik bekçisi bunu yakalamadı çünkü metin çıkarıcı yalnız
`lib/screens/landing_screen.dart` ve `lib/widgets/landing/` altını tarıyor;
`chatbot_badge.dart` o kapsamın dışında.

Ayrıca web'de balon yalnız üstüne gelince/tıklayınca açılıyor, uygulamada
sürekli görünüyor.

## Yapılacak

1. Web'deki metni uygulamadakiyle **birebir aynı** yap (emoji dahil).
2. Balon açılışını uygulamadakine yaklaştır: sayfa açıldığında görünür olsun.
   Kapatma davranışını koruyabilirsin.
3. **Asıl iş bu:** metin çıkarıcının kapsamını genişlet.
   `public_web/tests/yardimcilar/landingMetinleri.ts` içindeki
   `flutterLandingMetinleri()` fonksiyonu `lib/widgets/chatbot_badge.dart`
   dosyasını da taramalı. Böyle bir fark bir daha sessizce geçmesin.

   Kapsamı genişletince **başka metinler de dökülecektir.** Hepsini toptan
   istisnaya yazma. Dökülen listeyi bana göster, birlikte bakacağız.
   **Bu noktada dur.**

## Doğrulama

- `npm test` — eşitlik testi yeni metni görüyor mu.
- Ekran görüntüsü: balon görünür hâlde.

---

# Görev 3 — Hero formundaki adres öneki

**Etki: orta. Risk: düşük.**

## Fark

Uygulamada form iki parça (kaynak: `landing_hero_section.dart:495-541`):
- solda sabit gri bir kutu: `vixrex-public.vercel.app/v/`
  (dar ekranda sadece `/v/`)
- sağda boş bir yazı alanı, ipucu metni: `isletmeniz`

Web'de tek kutu var ve hepsi soluk ipucu metni olarak yazılı:
`vixrex-public.vercel.app/v/isletmeniz`. Kullanıcı tıklayınca hepsi kayboluyor,
adresin sabit kısmı olduğu anlaşılmıyor.

Uygulamadaki daha anlaşılır.

## Yapılacak

`public_web/src/components/landing/HeroSection.tsx` içindeki formu ikiye ayır:
sabit önek + yazı alanı.

Kurallar:

- Önek metni **elle yazılmayacak**, `getSiteUrl()`'den gelecek
  (`src/lib/siteUrl.ts`). Alan adı alındığında kod değişmemeli.
- Dar ekranda (400px altı) uygulamadaki gibi yalnız `/v/` gösterilecek.
- Form bugün `<form method="get">` ile çalışıyor ve JavaScript kapalıyken de
  gönderilebiliyor. **Bu davranış korunacak** — istemci bileşenine çevirme.
- İpucu metni `isletmeniz` olacak (uygulamadakiyle aynı).

## Doğrulama

- JavaScript kapalı tarayıcıda form hâlâ gönderiliyor mu — gerçekten dene.
- 390px ve 1280px ekran görüntüsü.

---

# Görev 4 — Telefon mockup'ı

**Etki: en yüksek. Risk: orta. En büyük iş. Görev 1-3 bitmeden başlanmayacak.**

## Fark

Bu, iki ekran arasındaki en büyük fark. Uygulamada gerçek bir telefon var:
çerçeve, mavi parıltı, içinde dolu bir vitrin. Web'de yuvarlak köşeli düz bir
kutu, içinde kapak fotoğrafı, isim ve üç küçük görsel.

Uygulamadaki telefonun içeriği (kaynak: `lib/widgets/landing/phone_mockup.dart`,
663 satır):

| Bölüm | İçerik |
|---|---|
| Çerçeve | 325×640, 40px köşe, beyaz %18 kenarlık 2.5px, üç katmanlı gölge (#0EA5E9 parıltısı dahil) |
| Kapak | 156px yükseklik, kategori rengiyle geçiş + kapak fotoğrafı, üstünde isim/kategori/durum |
| Hakkında | başlık + açıklama metni (satır 254-263) |
| Eylem simgeleri | WhatsApp, konum vb. yuvarlak renkli düğmeler |
| Eylem satırları | başlık + alt başlık + ok (ör. "Günün menüsü / Sıcak yemek ve tatlılar") |
| Vitrin galerisi | başlık + "N fotoğraf" rozeti + fotoğraf şeridi (satır 426-448) |
| Vitrin hazır | "Vitrin hazır / N bağlantı" + QR simgesi (satır 521-552) |

Ayrıca telefonun **dışında**, üstünde uçuşan iki etiket var
(`landing_hero_mockup.dart:98-123`): ör. "Menü" ve "Yol tarifi". Bulanık zeminli,
renkli simgeli küçük rozetler.

## Önce karar — koda başlamadan bunu sor

Web'deki mockup verisi bugün yalnız dört alan taşıyor
(`public_web/src/components/landing/mockupProfilleri.ts`): ad, kategori şeridi,
kapak, galeri. Uygulamadaki `HeroDemoProfile`
(`lib/models/landing_demo_profile.dart`) ise ek olarak açıklama, durum, eylemler
ve bağlantılar taşıyor.

Bu içerik şu an **bilerek** web'de yok: 19 metin
`public_web/tests/yardimcilar/landingEsitlikIstisnalari.ts` dosyasında
`MOCKUP_ICERIGI` gerekçesiyle istisna olarak yazılı.

Bu görev o kararı geri alıyor. Başlamadan önce **bana sor ve onay al** —
istisna listesini boşuna dağıtmayalım.

## Yapılacak (onay geldikten sonra)

**4.1** Mockup verisini genişlet. Uygulamadaki dört profilin açıklama, durum,
eylem ve bağlantı içeriğini `mockupProfilleri.ts`'e taşı. Metinler
uygulamadakiyle **birebir aynı** olacak — istisna listesindeki 19 metin
tam olarak bunlar, oradan kopyalanabilir.

Kapak ve galeri görselleri **bugünkü kaynağından gelmeye devam edecek**
(`category_image_templates`). Uygulamadaki uydurma Unsplash bağlantılarına
dönme — bu bilinçli bir iyileştirmeydi, gerekçesi `mockupProfilleri.ts`
dosyasının başında yazılı, koru.

**4.2** `PhoneMockupSlaytlari.tsx`'i yukarıdaki tablodaki bölümleri çizecek
şekilde genişlet. Telefon çerçevesini `PhoneMockup.tsx`'te kur (kenarlık,
köşe, gölge/parıltı).

**4.3** Uçuşan iki etiketi ekle. **Hareket olmayacak** — Görev 1'deki
gerekçenin aynısı; sabit konumda dursunlar.

**4.4** Dar ekranda (390px) telefon taşmayacak, ölçeklenecek.

**4.5** İstisna listesinden `MOCKUP_ICERIGI` gerekçeli 19 kaydı **sil.**
Bu adım isteğe bağlı değil: `landing-esitlik-contract.test.ts`'teki
"istisna listesi bayat değil" iddiası zaten kırılacaktır. Metinler artık
web'de olduğu için istisnaya gerek kalmaz.

**4.6** `e2e/visual-regression.spec.ts-snapshots/` altındaki ana sayfa
görüntüleri bu değişiklikle kırmızıya dönecek. Yeni temelleri **sen
üretmeyeceksin** — bana bildir, Casper gerçek tarayıcıda üretecek.

## Doğrulama

- `npm test` — 19 istisna silindikten sonra da yeşil olmalı. Yeşilse
  metinlerin gerçekten web'e taşındığı kanıtlanmış olur.
- 1280px ve 390px ekran görüntüsü, uygulamanın ekranıyla yan yana.
- Slayt döngüsü dört profilde de dolu görünüyor mu — dört slaytı da gör.

---

# Kapsam dışı — bunlara dokunma

- **Landing'deki asistan sohbeti bir makettir.** Telefon mockup'ının içindeki
  sohbet sabit metindir; kullanıcı yazamaz, hiçbir sunucuya bağlı değildir ve
  **bağlanmayacaktır**. "Çalışmıyor" sanıp gerçek motora bağlama.
  Web'de gerçek asistan yalnızca sahip panelindedir (`/v/:slug` →
  `OwnerAssistantPanel`). Tam kural: `VIXREX_RULES.md` §1.

  Sebep (2026-08-26 ölçümü): iki yüzeyde toplam **dokuz ayrı "Vixrex Asistan"
  parçası** var — Flutter'da 6, web'de 3. Onuncusunu doğurma.

- **"Giriş Yap" / "Çıkış Yap" farkı.** Web'de hesap oturumu yok; bu Faz 2
  işi, ayrı bir plan.
- **"Hazır şablonlara göz at" düğmesi.** Web'de var, uygulamada yok. Bu
  fazladan bir şey ve web'e özel Keşfet dizinine götürüyor — kalması doğru.
- **Güven rozetlerinin satır düzeni.** Genişlik farkından kaynaklanıyor,
  gerçek bir ayrışma değil.
- **Fiyat ve renk değerlerinin tek kaynağa çekilmesi.** Ayrı bir konu,
  şimdilik ertelendi.

---

# Çalışma kuralları

1. **Bir görev, bir dal, bir PR.** Görevleri birleştirme.
2. **Ölçmeden değiştirme.** Tarifteki satır numaraları 26 Ağustos'a ait,
   kaymış olabilir. Başlamadan kendi kontrolünü yap, fark varsa bildir.
3. **Her görevin sonunda gerçek ekran görüntüsü göster.** Testin yeşil
   olması yetmez.
4. **Görev 2.3 ve Görev 4 başında dur ve sor.** Orada karar bende değil.
5. Elle onaltılık renk yazma; `lp-*` tokenlarını kullan.
6. Hareket/animasyon ekleme. Gerekçesi Görev 1'de yazılı.
7. Geçici ölçüm betiklerini commit etme.
