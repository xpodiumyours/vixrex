# VixRex — Kabul Senaryosu

Bu belge **tek hedeftir.** Esnafın baştan sona yaşayacağı yol, adım adım.

## Nasıl kullanılır

- Bu yolu **bozan** her şey iştir.
- Bozmayan her şey **park** edilir (en altta liste).
- Karar çatalı çıkarsa durulmaz: varsayılan seçilir, "geri alınabilir"
  diye not düşülür, yola devam edilir.
- "Bitti" demek için baştan sona **tek seferde**, kesintisiz yürünmeli.

Her adımda üç şey var: kullanıcı ne yapar, ne görmeli, bugün ne oluyor.

---

## 1. Karşılaşma

**Yapar:** Google'da bir ürün/işletme arar, bir VixRex vitrinine düşer.
Ya da Keşfet'te gezerken beğendiği bir vitrin görür.

**Görmeli:** Düzgün, hızlı açılan, telefonda bozulmayan bir vitrin.
Altında "Bu vitrin senin de olabilir" daveti.

**Bugün:** Vitrin çalışıyor. Kiralama bandı `hedef-vitrin.html`'de var,
gerçek vitrinde bağlı değil.

---

## 2. Karar ve giriş

**Yapar:** "Ben de isterim" der, kaydolur.

**Görmeli:** Sayfa anında açılır. Giriş takılmaz, dönmez.

**Bugün:** ✅ Düzeltildi (A1) — reCAPTCHA engeli kaldırıldı.
Doğrulanacak: kullanıcı elle denemeli.

---

## 3. Kurulum sohbeti

**Yapar:** Vixrex'le konuşur: işletme adı, WhatsApp, konum.

**Görmeli:** Üç soru, üç cevap, bitti. Konum **doğru** bulunmalı.
Sonunda link.

**Bugün:** Çalışıyor. **Konum yanlış tespit ediliyor (A2).**

---

## 4. İlk vitrin

**Yapar:** Linke tıklar, vitrinini ilk kez görür.

**Görmeli:** Kendi işletmesini tanımalı. Kategorisine uygun görünmeli.
Koymadığı bir şey karşısına çıkmamalı.

**Bugün:** Vitrin açılıyor. **Seçilmemiş kapak fotoğrafı kendiliğinden
geliyor (B1).**

---

## 5. Kişiselleştirme — işin kalbi

**Yapar:** Vixrex Asistan ile vitrinini kendi işletmesine benzetir.
Yazıya tıklar, değiştirir. Fotoğraf yükler. Hazır şablon seçer.

**Görmeli:**
- Sağ altta Vixrex, doluluk oranıyla
- Tıkladığı her yazı düzenlenebilir (41 alan)
- Kategorisine özel hazır görsel kütüphanesi **aynı sayfada** açılır
- Değişiklik anında görünür, müşteri yayınlanana kadar görmez
- Sonuç `sablonlar/hedef-vitrin.html` kalitesinde

**Bugün:** Tıkla-düzenle ve görsel yükleme çalışıyor.
**Şablon kütüphanesi yanlış tarafta açılıyor (C1).**
**Kalite hedefin altında (D1, D2).**

---

## 6. Yayınlama

**Yapar:** Beğenir, Yayınla'ya basar.

**Görmeli:** "Müşterileriniz artık yeni hâlini görüyor." Link paylaşıma
hazır, QR kod elinde.

**Bugün:** Yayınla/vazgeç çalışıyor, canlıda doğrulandı.
**QR kod yeni tasarımda yok.**

---

## 7. Geri dönüş

**Yapar:** Ertesi gün uygulamayı açar, bir şey değiştirmek ister.

**Görmeli:** Aynı Vixrex, aynı dil. Dün canlıda yaptığı değişiklikler
uygulamada da görünür.

**Bugün:** **Canlı düzenleme Flutter paneline yansımıyor (C3).**
**Sert devir (C2) — tek asistan hissi yok.**

---

## 8. Kiralama

**Yapar:** 14 günlük deneme biter, devam etmek ister.

**Görmeli:** Fiyat açık (499 TL + KDV/ay), ödeme kolay.

**Bugün:** **Ödeme sistemi yok. Premium kilidi açık.** Kabul
senaryosunun sonu şimdilik 7. adım.

---

## Boşluk listesi — 2026-08-06 durumu

| # | Adım | İş | Durum |
|---|---|---|---|
| 1 | 2 | A1 — giriş takılıyor / yavaş açılıyor | ✅ `6c83ef2` |
| 2 | 3 | A2 — konum yanlış tespit ediliyor | ✅ `0d23052` |
| 3 | 4 | B1 — istenmeyen kapak fotoğrafı | ✅ `772abd1` |
| 4 | 5 | C1 — şablon kütüphanesi yanlış tarafta | ✅ `d397eec` |
| 5 | 7 | C3 — canlı düzenleme uygulamaya yansımıyor | ✅ `6408082` |
| 6 | 7 | C2 — tek asistan, kesintisiz devir | ✅ `7fafe9c` |
| 7 | 1 | Kiralama bandı vitrine bağlansın | ✅ `171ef73` |
| 8 | 6 | QR kod geri gelsin | ✅ `fed3e72` |
| 9 | 5 | D2 — arayüz ince işçiliği | ⬜ E2E turunda toplanacak |

**Ölçülebilir her madde kapandı.** Kalan tek şey göz gerektiriyor: D2,
arayüzün ince işçiliği. O da tek tek tahmin ederek değil, baştan sona
tek bir E2E turunda toplanacak.

### Test düzeni — kural

- **Parça testi yok.** Bir düzeltmeden sonra "şunu bir dene" denmez.
- Liste bitmeden kullanıcıya test ettirilmez.
- Test tek oturumda, bu belgedeki 8 adım sırayla yürünerek yapılır.
- Her adım için tek soru: **vaat edilen oldu mu?**
- Takılan yer not edilir, tur DEVAM EDER — ortasında düzeltmeye
  girilmez. Tur bitince liste birlikte ele alınır.

---

## Park edilenler

Yolu bozmuyorlar, şimdi ele alınmayacak:

- Bot koruması (reCAPTCHA doğrulaması hiç bağlanmamış — gecikme
  kaldırıldı, koruma ayrı iş)
- Maskot testi (uygulamada çalışıyor, yalnız test kırık)
- 155 Dart dosyasının biçimlendirilmesi
- Karşılama ekranındaki 7 eksik kategori kutusu
- `PublishActionsSection` ölü kodu
- Ödeme sistemi, premium kilidi, deneme akışı (8. adım — ayrı faz)
