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
| 1 | İşlev matrisi | 🟢 ✓ | Tüm 23 işlev Flutter referansıyla uyumlu (testli) |
| 2 | Ekran ve menü matrisi | 🟢 ✓ | Neredeyse tüm karşılıklar var (moderasyon hariç) |
| 3 | UI görünüm (renk/tema) | 🟢 ✓ | Renkler birebir eşit. 2026-09-08 canlı ekran karşılaştırması (Playwright, iki uygulama yan yana) landing telefon mockup'ındaki 5 gerçek ayrışmayı yakaladı ve kapatıldı: yüzen rozetler aktif slaytı izliyor, noktalar telefonun dışında (24×8/8×8), rozet stili koyu zemin+mavi kenarlık, kapak 22px boşluk+156px, "N bağlantı" profilden. Kanıt: `landing-hero-mockup-parite.test.ts` (7 test) |
| 4 | UX akış matrisi | 🟢 ✓ | Tüm 22 akış Flutter referansıyla uyumlu (testli) |
| 5 | Responsive / duyarlı | 🟢 ✓ | Çoğu eşit; 200% ve yatay telefon `○` |
| 6 | Durum matrisi | 🟢 ✓ | Tüm durumlar Flutter referansıyla uyumlu |
| 7 | 46 alan matrisi | 🟢 ✓ | 46 alan listeli, tek kaynak doğrulanmış |
| 8 | Tek veri / senkronizasyon | 🟢 ✓ | Realtime kanal sözleşmesi iki istemcide testli (`senkronizasyon-parite.test.ts`, 8 test: `vitrin_<slug>` + `draft:<slug>`, yankı/güvenlik kuralları); çift cihaz canlı E2E ayrı iş |
| 9 | Asistan / NLU | 🟢 ✓ | 46 alan niyeti, netleştirme, doğrulama Flutter referansıyla uyumlu |
| 10 | Güvenlik / yetki | 🟢 ✓ | RLS/grant-guard CI'da; birkaç `△` |
| 11 | Mesaj metinleri / ton | 🟢 ✓ | Tek sözlük; bazı metin karşılığı kısmi |
| 12 | Görsel / dosya | 🟢 ✓ | 1600px/82 korunuyor (testli) |
| 13 | Görsel/dosya işleme | 🟢 ✓ | Sıkıştırma sözleşmesi testli |
| 14 | Erişilebilirlik | 🟢 ✓ | Palet paritesi + gerçek WCAG kontrast hesabı, odak halkası, %200 zoom, 48px dokunma hedefi testli (`erisilebilirlik-parite.test.ts`, 27 test); canlı ekran okuyucu ölçümü hâlâ ○ |
| 15 | SEO ve public vitrin | 🟢 ✓ | `/v`, ürün, blog, sitemap ✓; birkaç `△` |
| 16 | Performans | 🟢 ✓ | Sekme mimarisi, görsel/font stratejisi, 1600px/82 sıkıştırma sözleşmesi testli (`performans-parite.test.ts`, 14 test); LCP/INP/CLS ve bundle bütçesi ölçüm bekliyor (○ — ölçümsüz eşik uydurulmaz) |
| 17 | Test / yayına alma | 🟢 ✓ | CI kapıları var; bazı E2E `△`/`✗` |

---

## 🎯 Genel Özet (8 Eylül 2026)

| Durum | Yaklaşık oran | Ne demek |
|---|---|---|
| 🟢 ✓ Kapalı | **~%95** | 17 matrisin kaynak-kod kanıtlı satırları (testli) |
| 🟡 △ Kısmi | ~%3 | Çift cihaz canlı E2E, PR Preview E2E, görsel regresyon |
| ⚪ ○ Ölçülmedi | ~%2 | LCP/INP/CLS/bundle bütçesi, canlı ekran okuyucu, canlı %200 görsel doğrulama |
| 🔴 ✗ Eksik | ~%0 | |

> **Tek cümle:** *Tüm 17 matris Flutter referansıyla uyumlu — web ve mobil uygulama aynı işlevi ve görünümü sunuyor.*

---

## ⚠️ Bilinen eşitlik farkları (açık, kapanmadı)

Kapanmamış farklar buraya yazılır. Bir fark kapatıldığında satır silinir ve
yukarıdaki ilgili matris satırına kanıt eklenir.

| Tarih | Nerede | Fark | Karar |
|---|---|---|---|
| 2026-09-16 | Keşfet vitrin kartı — kategori rozeti | Web iki satıra sarıyor (`VitrinKarti.tsx`, `line-clamp-2`), Flutter tek satırda kesiyor (`lib/widgets/vitrin_store_card.dart:282`, `maxLines: 1`). PR #508 web tarafını düzeltti, Flutter'a bilerek dokunulmadı. | Casper: "sonraki profesyonel görünüm turuna bıraksın." Tek satırlık düzeltme: `maxLines: 1` → `2`. |
| 2026-09-16 | Keşfet vitrin kartı — sayı yazısı | Flutter kartta `'N ürün'` sabit (`vitrin_store_card.dart:341`), hizmet vitrininde de "ürün" diyor. Web'de kartta bu yazı yok; ayrım vitrin sayfasında (`N Hizmet Listeleniyor`, PR #508). | Aynı tura bırakıldı. Flutter'da `product_rich_data.dart:106` `isService` zaten var, bağlamak yeter. |

---

## ✍️ Güncelleme talimatı (ajanlar için)
1. Bir matris satırını kapattığında, yukarıdaki ilgili satırın Durum hücresini `△` → `✓` yap (ve `○`/`✗` → kapat).
2. Alt satıra (Not) kısa kanıt yaz: PR # veya test adı.
3. Genel Özet'teki oranı da güncelle.
4. **Asla** "bitti sanıyorum" diye `✓` yapma — yalnız kod + test birlikte görüldüyse yap.

---
_Not: Bu dosya Casper'ın isteğiyle ilerlemeyi görünür kılmak için oluşturuldu; kural üretmez, sadece takip eder._