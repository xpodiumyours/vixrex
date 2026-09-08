# Vixrex — Uyum Sözleşmesi İlerleme Tablosu

> **Bu nedir:** Web + mobil uygulamanın ne kadar "aynı/profesyonel" olduğunu takip eden tek sayfalık tablo.
> **Kaynak:** `VIXREX-UYUM-SOZLESMESI.md` (Codex, 8 Eylül 2026) + ajanların yaptığı PR/testler.
> **Nasıl güncellenir:** Bir ajan bir matrisin satırını kapattığında buradaki ilgili hücreyi yalnız **çalışan davranış testi** kanıtlıyorsa `✓` yapar. Kaynak dosyada kelime aramak tek başına kanıt değildir.
> **Tarih:** 9 Eylül 2026 — parite testlerini gerçek teste çevirme çalışması başladı.

## Lejant (kısaca)
- 🟢 **✓ Eşit** = ilgili davranış gerçek kod çalıştırılarak kanıtlı
- 🟡 **△ Kısmi** = bir kısmı gerçek davranış testiyle kanıtlı, kalanı bekliyor
- ⚪ **○ Ölçülmedi** = canlı cihazda/ölçümde bakılmalı
- 🔴 **✗ Eksik** = karşılığı/testi yok

---

## 📋 17 Matrisin Durumu

| # | Matris | Durum | Not |
|---|---|---|---|
| 1 | İşlev matrisi | 🟡 △ | Katman A konum/harita, galeri ve hakkımızda alanlarını gerçek `vitrinFieldSchema` modülüyle çalıştırıyor. 23 işlevin tamamı davranış testine dönüşmeden `✓` değil. |
| 2 | Ekran ve menü matrisi | 🟢 ✓ | Neredeyse tüm karşılıklar var (moderasyon hariç) |
| 3 | UI görünüm (renk/tema) | 🟢 ✓ | Renkler birebir eşit. 2026-09-08 canlı ekran karşılaştırması (Playwright, iki uygulama yan yana) landing telefon mockup'ındaki 5 gerçek ayrışmayı yakaladı ve kapatıldı: yüzen rozetler aktif slaytı izliyor, noktalar telefonun dışında (24×8/8×8), rozet stili koyu zemin+mavi kenarlık, kapak 22px boşluk+156px, "N bağlantı" profilden. Kanıt: `landing-hero-mockup-parite.test.ts` (7 test) |
| 4 | UX akış matrisi | 🟡 △ | Katman A Keşfet arama/filtre/kategori veri akışını gerçek fonksiyon çağrılarıyla test ediyor. Diğer akışlar render/etkileşim/E2E katmanlarını bekliyor. |
| 5 | Responsive / duyarlı | 🟢 ✓ | Çoğu eşit; 200% ve yatay telefon `○` |
| 6 | Durum matrisi | 🟢 ✓ | Tüm durumlar Flutter referansıyla uyumlu |
| 7 | 46 alan matrisi | 🟡 △ | Next.js 46 alan şeması gerçek modülden yüklenip benzersizliği doğrulanıyor; iki istemcinin tüm alan davranışları henüz çalıştırılmış değil. |
| 8 | Tek veri / senkronizasyon | 🟡 △ | Katman A Next.js'te `vitrin_<slug>` + `draft:<slug>` kanal kurulumunu, dış olay yenilemesini, kendi yankısını atlamayı ve broadcast payload'ının yalnız `clientId` taşımasını gerçek mock kanal üzerinden çalıştırıyor. Flutter runtime + çift cihaz canlı E2E bekliyor. |
| 9 | Asistan / NLU | 🟡 △ | Katman A gerçek mesaj kataloğu, kurulum alanı çözümleyicisi ve `assistantHandoff` parser/continuation davranışını çalıştırıyor. 46 alanın tüm niyet/netleştirme etkileşimi henüz kanıtlı değil. |
| 10 | Güvenlik / yetki | 🟢 ✓ | RLS/grant-guard CI'da; birkaç `△` |
| 11 | Mesaj metinleri / ton | 🟡 △ | Ortak katalog gerçek modülden çözülüyor; tüm kullanıcı yüzeylerinin render kanıtı Katman B/C'yi bekliyor. |
| 12 | Görsel / dosya | 🟢 ✓ | 1600px/82 korunuyor (testli) |
| 13 | Görsel/dosya işleme | 🟢 ✓ | Sıkıştırma sözleşmesi testli |
| 14 | Erişilebilirlik | 🟡 △ | Gerçek WCAG kontrast hesabı korunuyor; canlı ekran okuyucu ölçümü yapılmadan `✓` değil. |
| 15 | SEO ve public vitrin | 🟢 ✓ | `/v`, ürün, blog, sitemap ✓; birkaç `△` |
| 16 | Performans | 🟡 △ | Kod/sözleşme testleri var; LCP/INP/CLS ve bundle bütçesi ölçülmeden `✓` değil. |
| 17 | Test / yayına alma | 🟡 △ | Parite testlerini gerçek davranış testlerine çevirme Katman A–E devam ediyor; metin arama testleri tek başına yayın kanıtı sayılmıyor. |

---

## 🎯 Genel Özet (9 Eylül 2026)

Eski **~%95 kapalı** oranı gerçek davranış kanıtı sanıldığı için askıya alındı. Katman A–E tamamlanırken oran yeniden hesaplanacak; ölçülmeyen metrikler oranı şişirmek için `✓` sayılmayacak.

| Durum | Şimdiki anlamı |
|---|---|
| 🟢 ✓ | Gerçek kod/render/handler/tarayıcı davranışıyla kanıtlı satırlar |
| 🟡 △ | Gerçek teste dönüşümü veya ek katmanı bekleyen satırlar |
| ⚪ ○ | Canlı cihaz / performans / ekran okuyucu gibi henüz ölçülmeyenler |
| 🔴 ✗ | Karşılığı veya gerçek testi bulunmayanlar |

> **Tek cümle:** *Web ve mobilin tamamen eşit olduğu henüz kanıtlanmış değil; parite oranı gerçek davranış testleri tamamlandıkça yeniden belirlenecek.*

---

## ✍️ Güncelleme talimatı (ajanlar için)
1. Bir matris satırını yalnız gerçek kod/render/handler/tarayıcı davranışı çalıştırıldığında `✓` yap.
2. Kaynak dosyada `readFileSync` + `toContain` ile kelime aramak tek başına parite kanıtı değildir.
3. Alt satıra kısa kanıt yaz: PR # veya gerçek test adı.
4. Genel özeti yalnız ölçülmüş sonuçla güncelle; yüzde uydurma.
5. **Asla** "bitti sanıyorum" diye `✓` yapma.

---
_Not: Bu dosya Casper'ın isteğiyle ilerlemeyi görünür kılmak için oluşturuldu; kural üretmez, sadece takip eder._
