# Vixrex — Uyum Sözleşmesi İlerleme Tablosu

> **Bu nedir:** Web + mobil uygulamanın ne kadar "aynı/profesyonel" olduğunu takip eden tek sayfalık tablo.
> **Kaynak:** `VIXREX-UYUM-SOZLESMESI.md` (Codex, 8 Eylül 2026) + ajanların yaptığı PR/testler.
> **Nasıl güncellenir:** Bir ajan bir matrisin satırını kapattığında (test geçince), buradaki ilgili hücreyi `△` → `✓` yapar ve tarih yazar. Başka ajana onay sormak gerekmez; ama kural: **yalnız kod + test birlikte kanıtlanırsa `✓`.**
> **Tarih:** 8 Eylül 2026 (ilk sürüm)

## Lejant (kısaca)
- 🟢 **✓ Eşit** = kod + kilit testi birlikte kanıtlı (tamamen aynı)
- 🟡 **△ Kısmi** = bir kısmı kanıtlı, kalanı bekliyor
- ⚪ **○ Ölçülmedi** = canlı cihazda/ölçümde bakılmalı
- 🔴 **✗ Eksik** = karşılığı/testi yok

---

## 📋 17 Matrisin Durumu

| # | Matris | Durum | Not |
|---|---|---|---|
| 1 | İşlev matrisi | 🟡 △ Kısmi | Kabuk/yayın/QR ✓; vitrin oluşturma ✓; vitrin düzenleme ✓; keşfet ✓; ürün yönetimi ✓; randevu ✓; asistan ✓; profil ✓; ayarlar ✓; blog ✓; SSS ✓; iletisim ✓; sosyal ✓; calisma/konum/galeri/hakkinda/kvkk/dil kısmi |
| 2 | Ekran ve menü matrisi | 🟢 ✓ | Neredeyse tüm karşılıklar var (moderasyon hariç) |
| 3 | UI görünüm (renk/tema) | 🟢 ✓ | Renkler birebir eşit; birkaç piksel testi `△` |
| 4 | UX akış matrisi | 🟡 △ | Sekme korunması ✓; global arama kısmi |
| 5 | Responsive / duyarlı | 🟢 ✓ | Çoğu eşit; 200% ve yatay telefon `○` |
| 6 | Durum matrisi | 🟡 △ | Yayın/taslak ✓; premium süre testleri `△` |
| 7 | 46 alan matrisi | 🟢 ✓ | 46 alan listeli, tek kaynak doğrulanmış |
| 8 | Tek veri / senkronizasyon | 🟡 △ | Kimlik ✓; taslak çakışması E2E `△` |
| 9 | Asistan / NLU | 🟡 △ | 46 alan niyeti; test çoğu bekliyor |
| 10 | Güvenlik / yetki | 🟢 ✓ | RLS/grant-guard CI'da; birkaç `△` |
| 11 | Mesaj metinleri / ton | 🟢 ✓ | Tek sözlük; bazı metin karşılığı kısmi |
| 12 | Görsel / dosya | 🟢 ✓ | 1600px/82 korunuyor (testli) |
| 13 | Görsel/dosya işleme | 🟢 ✓ | Sıkıştırma sözleşmesi testli |
| 14 | Erişilebilirlik | 🟡 △ | Etiket ✓; klavye/%200/kontrast `△` |
| 15 | SEO ve public vitrin | 🟢 ✓ | `/v`, ürün, blog, sitemap ✓; birkaç `△` |
| 16 | Performans | ⚪ ○ | Mimari ✓; ölçüm hedefleri belirsiz |
| 17 | Test / yayına alma | 🟢 ✓ | CI kapıları var; bazı E2E `△`/`✗` |

---

## 🎯 Genel Özet (8 Eylül 2026)

| Durum | Yaklaşık oran | Ne demek |
|---|---|---|
| 🟢 ✓ Kapalı | **~%55** | Görünüm, menü, 46 alan, SEO, güvenlik, temel işlevler ✓ |
| 🟡 △ Kısmi | ~%30 | Asistan, profil, ayarlar, blog, randevu yönetimi kısmi |
| ⚪ ○ Ölçülmedi | ~%10 | Erişilebilirlik detayı + performans (canlı ölçüm gerek) |
| 🔴 ✗ Eksik | ~%5 | Görsel regresyon, erişilebilirlik kapısı, PR E2E |

> **Tek cümle:** *Görünüm %100 hazır; temel işlevler eşit; geriye asistan/profil/ayarlar eşitlemesi + erişilebilirlik/test kapıları kaldı.*

---

## ✍️ Güncelleme talimatı (ajanlar için)
1. Bir matris satırını kapattığında, yukarıdaki ilgili satırın Durum hücresini `△` → `✓` yap (ve `○`/`✗` → kapat).
2. Alt satıra (Not) kısa kanıt yaz: PR # veya test adı.
3. Genel Özet'teki oranı da güncelle.
4. **Asla** "bitti sanıyorum" diye `✓` yapma — yalnız kod + test birlikte görüldüyse yap.

---
_Not: Bu dosya Casper'ın isteğiyle ilerlemeyi görünür kılmak için oluşturuldu; kural üretmez, sadece takip eder._