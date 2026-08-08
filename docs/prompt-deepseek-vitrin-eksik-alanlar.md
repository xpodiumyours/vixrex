# deepseek görevi — vitrinde toplanan ama gösterilmeyen alanları ekle

Bu dosyanın tamamı tek seferde deepseek'e yapıştırılacak prompt'tur.
Aşağıdaki çizginin altındaki her şey kopyalanır.

---

Sen VixRex deposunda çalışıyorsun: `C:\Projects\vixrex`.

## 1. Bağlam — onaylı görsel taslak var, ona uy

Casper bu görevin **görsel taslağını onayladı**:
https://claude.ai/code/artifact/efce5783-ca8a-4274-9a93-44d151308890

Aşağıdaki her adım o taslağın kod karşılığı. **Kendi tasarım kararını
verme** — renk, boşluk, ikon, sıralama zaten karara bağlandı; senin
işin bunu `public_web/src/app/v/[slug]/VitrinProfileView.tsx`'in
**var olan** desenlerine birebir uyarak kodlamak.

## 2. Sorun (ölçüldü)

`VitrinProfileView.tsx` şu prop'ları alıyor ama **hiçbirini kullanmıyor**
(ESLint `no-unused-vars` ile doğrulandı, satır numaraları o dosyaya
göre — sen açtığında kaymış olabilir, isimden bul):

| Prop | Ne olması gerekiyordu | Bu görevde ne yapılacak |
|---|---|---|
| `logoUrl` | Esnafın yüklediği logo | Hero'da rozet olarak göster |
| `status`, `isClosed` | Açık/Kapalı durumu | Hero'da rozet olarak göster |
| `workingHoursWeek` | 7 günlük çalışma saati | İletişim kartında açılır liste |
| `marketplaceLinks` | Pazaryeri linkleri (Trendyol vb.) | İletişim kartında yeni satır |
| `googleBusinessLink` | Google İşletme linki | İletişim kartında yeni satır |
| `referencesUrl` | Referans/portföy linki | İletişim kartında yeni satır |

`corporateBio` de listede çıkmıştı ama o **zararsız** — aynı metin
`aboutSection.body` üzerinden zaten gösteriliyor, ona dokunma.
`isBookingEnabled` da **bu görevin kapsamında değil** — o görünürlük
değil, randevu akışını etkiliyor, ayrı ele alınacak.

## 3. Sıra — taslaktaki gibi, birer birer commit

### Adım 1 — Açık/Kapalı rozeti (en küçük, en çok fark eden)

Hero bölümünde (`{/* ===== HERO ===== */}`), var olan `displayBadge`
rozetinin (`heroRozet`, pill şekilli, mavi) yanına ikinci bir rozet ekle.
**Aynı pill deseni**, yeşil/kırmızı varyantı:

- Açıksa: yeşil nokta + "Şu an açık" — `bg-green-500/12 border-green-500/25 text-green-300` gibi mevcut renk paletine uyan bir yeşil (taslakta `--success:#22C55E` kullanıldı)
- Kapalıysa: kırmızı nokta + "Şu an kapalı"
- `isClosed` prop'undan karar ver (`status` metnini rozetin içinde göstermene gerek yok, "Açık"/"Kapalı" yeter — zaten `workingHoursToday` ayrı satırda saati gösteriyor)

### Adım 2 — Logo rozeti

Hero'da işletme adının (`<h1>`) hemen solunda, aynı satırda küçük bir
logo kutusu:

- `logoUrl` doluysa: görsel olarak göster (yuvarlak köşeli kutu)
- `logoUrl` boşsa: **yeni bir bileşen yazma** — `ProductCatalog.tsx`
  satır ~58-61'deki baş-harf yedeği deseniyle aynı mantığı kullan
  (`border border-blue-500/20 bg-blue-500/10 text-blue-400
  font-extrabold`, işletme adının ilk harfi, büyük harf)

### Adım 3 — 3 yeni İletişim & Konum satırı

`{/* Left Contact Panel */}` içindeki satır listesine (adres, telefon,
whatsapp, e-posta, website, çalışma saati — hepsi aynı desen:
`flex items-start gap-4 pb-4 border-b ...` + ikon kutusu + `<h4>` +
link/metin) **birebir aynı desende** 3 satır daha ekle:

- 🛒 Pazaryeri Bağlantıları — `marketplaceLinks` dizisi, her biri
  `{platform}` başlığıyla `{url}` linki. Birden fazla varsa alt alta
  listele (her biri kendi satırı değil, tek "Pazaryeri Bağlantıları"
  başlığı altında birkaç link — taslakta tek link örneklendi ama
  gerçekte dizi olduğunu unutma)
- 🏢 Google İşletme Profili — `googleBusinessLink`, tek link
- 📇 Referanslar — `referencesUrl`, tek link

**Her biri yalnız veri doluysa görünür** — boşsa satır hiç açılmaz
(var olan satırların hepsi zaten bu kuralda, aynısını uygula).

### Adım 4 — Haftalık saatler (en son, en fazla karar gerektiren)

Var olan "Çalışma Saatleri" satırının (`workingHoursToday`) altına,
`workingHoursWeek` doluysa küçük bir "Haftalık saatleri gör" metni +
ok ikonu ekle. Tıklanabilir açılır/kapanır olması gerekiyorsa
(`<details>`/`<summary>` en basit yol, React state açmaya gerek yok)
altında 7 satırlık kompakt bir liste: gün adı — saat aralığı, bugünün
günü kalın, kapalı günler "Kapalı" (kırmızımsı) yazsın. Taslaktaki
grid deseni: iki sütun (gün / saat), `font-variant-numeric:
tabular-nums` saatler için.

`workingHoursWeek` boşsa bu bölüm hiç çıkmaz, mevcut tek satır
(bugünün saati) olduğu gibi kalır.

## 4. Kesin kurallar

1. Yalnız `public_web/src/app/v/[slug]/VitrinProfileView.tsx`'e
   dokun. `page.tsx` zaten bu prop'ları geçiyor, değiştirmene gerek yok
   — kontrol et, geçmiyorsa (isim uyuşmazlığı vb.) o zaman `page.tsx`'i
   de düzelt ama bunu raporda ayrıca belirt.
2. Sahip modu işaretleyicilerine (`editableProps(...)`) dokunma,
   yeni eklediğin alanlar tıkla-düzenle şemasında yoksa
   (`vitrinFieldSchema.ts`'e bakma bile, bu görevin kapsamı değil)
   editableProps eklemene gerek yok — yalnız görüntüleme.
3. Yeni bir kart, yeni bir bölüm **açma** — her şey var olan hero/
   iletişim kartının içine giriyor, taslakta gösterildiği gibi.
4. Renk/boşluk değeri icat etme — mevcut dosyadaki class'ları kopyala,
   yalnız renk tonunu (yeşil/kırmızı) değiştir.
5. Türkçe yaz, depo kuralına uy.
6. `isBookingEnabled`'a dokunma — kapsam dışı.

## 5. Doğrula

- `npx tsc --noEmit`, `npm run lint` — **17 uyarıdan en az 6'sı**
  (logoUrl, status, isClosed, workingHoursWeek, googleBusinessLink,
  referencesUrl, marketplaceLinks — bazıları aynı satırda olabilir)
  artık "kullanılmıyor" olarak çıkmamalı, çünkü artık kullanılıyorlar.
  Kalan uyarılar (dead import'lar vb.) bu görevin konusu değil, olduğu
  gibi kalsın.
- `npm run build` başarılı.
- Varsa ilgili testler (`vitrin-field-schema` DEĞİL — o alan
  eklemiyorsun, bu görev şemayı değiştirmiyor).
- 4 durumun ekran görüntüsü: (a) her alan dolu bir mağaza, (b) hiçbiri
  dolu olmayan bir mağaza (hiçbir yeni satır/rozet çıkmamalı, eski
  hâliyle birebir aynı görünmeli) — ikisini karşılaştır, boş durumda
  hiçbir kırık/boş kutu görünmediğini kanıtla.

## 6. Dal

`duzeltme/vitrin-eksik-alanlar` main'den (ayrı bir worktree hazır:
`C:\Projects\vixrex-vitrin-alanlar-worktree`, orada çalışabilirsin ya
da kendi ortamında aynı isimle aç).

## 7. Nasıl rapor ver

Kanıtla, anlatma: `tsc`/`lint`/`build` çıktıları, dolu/boş durum ekran
görüntüleri, hangi adımı bitirdiğin. Taslaktan bir yerde ayrılmak
zorunda kaldıysan (ör. veri şekli taslaktakinden farklı çıktı) nedenini
yaz, sessizce başka bir şey yapma. Uydurma yasak.
