# Mobil ↔ Web Uyum Matrisi (kemik matris)

**Referans değişti.** 1-17 numaralı matrislerin referansı *"çalışan Flutter
Web"*ti ve kuralı *"Flutter değiştirilmez"*. O referans emekli oluyor:
Flutter tanıtım sayfası yayından kalkacak, Flutter tek işe inecek — APK
kaynağı + esnaf paneli + asistan sohbeti. Next.js web yüzeyinin tamamı olacak.

**Bu matrisin referansı ortak kaynaktır**, karşı istemcinin ekranı değil.

**Kalıcıdır (kemik).** Bir hücrenin bozulması hata demektir. Hedefe varınca
emekli olmaz. Plan matrisleriyle karıştırma: `docs/plan/` altındakiler geçici,
`✗` orada "henüz yapılmadı" demektir; burada `✗` "bozuk" demektir.

**Dürüstlük kuralı (1-17 ile aynı):** `✓` yalnız kod **ve** onu kilitleyen test
birlikte görüldüyse yazılır.

---

## Temel kural

> **Uyum yüzeyde değil, ortak kaynakta korunur.**

Flutter mobil ekranını istediği gibi çizer, Next web kendininkini. İkisi de
aynı `shared/*.json` dosyalarından aynı alanları, aynı mesajları, aynı
kuralları okuduğu sürece uyum bozulmaz. Telefonda alt sekme, webde yan menü
olması **ayrışma değil, doğru tasarımdır.**

## Üç katman

| Katman | İçerik | Eşitlik | Nasıl kilitlenir |
|---|---|---|---|
| **1 — Ortak kaynak** | `shared/*.json` (10 dosya) + Supabase şeması/RPC | **Zorunlu** | Üretim tazeliği (CI `schema-drift`) |
| **2 — İş kuralları** | yayın kapısı, 46 alan, çalışma saati, konum, asistan davranışı | **Zorunlu** | Sözleşme testleri — kaynağı katman 1 olmalı, dart dosyası değil |
| **3 — Yüzey** | ekran, menü, düzen, görünüm, gezinme | **ARANMAZ** | Her istemci kendi testiyle; eşitlik iddiası yok |

---

## ÖNCE fotoğrafı — 2026-09-12

Geçişe başlamadan önceki ölçülmüş durum. Ölçüm dalı: `main@6c9d2912`. Sonrasıyla karşılaştırma bunun
üstünden yapılır.

| Ölçüm | Değer |
|---|---|
| Toplam test dosyası | **188** |
| Flutter dart dosyası okuyan test | **122** (%65) |
| Testler | 1531 geçti · 7 kırık · 3 todo — kırıkların ikisi de `fark-tespiti-randevu-*`, bu geçişle ilgisiz |
| `shared/*.json` | 10 dosya |
| Ortak kaynak tazeliği | **Taze** — üç üretici koşuldu, `dart format` sonrası fark yok |
| Flutter ekran dosyası | 24 (`lib/screens/`) |
| Flutter landing bileşeni | 14 (`lib/widgets/landing/`) |

**Dart okuyan 120 testin sınıflandırması** (ölçüm: `landing_screen.dart` veya
`widgets/landing/` okuyan → sınıf 1; `lib/screens/` veya `lib/widgets/`
okuyan → sınıf 3; diğer `lib/` yolları → sınıf 2):

| Sınıf | Adet | Karar |
|---|---|---|
| 1 — Flutter Web ile ölecek | **11** | Tanıtım sayfası kalkınca silinir |
| 2 — İş kuralı | **89** | Kalır, kaynağı `shared/`'a taşınır |
| 3 — Yüzey | **22** | "Parite" iddiasından çıkar |

---

## Matris

| # | Uyum alanı | Katman | Tek kaynak | Bugünkü kilit | Durum |
|---|---|---|---|---|---|
| 1 | Vitrin alanları (46 alan) | 1 | `shared/vitrin_alanlari.json` → `vitrin_alanlari.g.dart` + TS | CI `schema-drift` işi; üretim tazeliği 12 Eylül'de doğrulandı | `✓` — `business-categories.test.ts` |
| 2 | İşletme kategorileri | 1 | `shared/business_categories.json` | CI `schema-drift`; CLAUDE.md'de doğru desen örneği olarak geçiyor | `✓` — `business-categories.test.ts` |
| 3 | Mesaj kataloğu | 1 | `shared/vixrex_mesajlar.json` → `vixrex_mesajlar.g.dart` | Üretim tazeliği var; iki istemcide kullanım eşliği kilitli değil | `△` |
| 4 | Çalışma saati sözleşmesi | 1 | `shared/working_hours_contract.json` | `calisma-saatleri-parite.test.ts` — ama `lib/models/working_hours.dart` okuyor, ortak kaynağı değil | `△` |
| 5 | Niyet sözlüğü / asistan dili | 1 | `shared/vixrex_niyet_sozlugu.json` + 4 senaryo dosyası | `asistan-parite.test.ts` dart config okuyor | `△` |
| 6 | Vitrin akış algoritması | 1 | `shared/vitrin_akis_algoritmasi.json` | Kilitleyen test bulunamadı | `✗` |
| 7 | Yayın kapısı | 2 | Supabase RPC (`publish_working_draft`) | RPC sözleşme testi var, iki istemci eşliği kilitli değil | `△` |
| 8 | Taslak yazımı ve sahiplik | 2 | Supabase RPC + `edit_token` | `flutter-assistant-canonical-write-contract.test.ts` | `△` |
| 9 | Asistan hafıza sürekliliği | 2 | Supabase `assistant_conversations` | `assistant-cross-client-memory-contract.test.ts` | `△` |
| 10 | Ekran düzeni ve menü sırası | 3 | — | 22 yüzey testi hâlâ eşitlik iddia ediyor | `İstisna` — eşitlik aranmayacak |
| 11 | Tanıtım sayfası | 3 | — | 11 test Flutter landing okuyor | `İstisna` — Flutter tarafı kalkıyor |

## Sayım

| Durum | Adet |
|---|---|
| `✓` kod + kilitleyen test | 2 |
| `△` kısmi | 6 |
| `✗` yok | 1 |
| `İstisna` | 2 |

---

## Geçiş sırası

1. **87 iş kuralı testinin kaynağını `shared/`'a taşı.** Asıl mühendislik
   burada. Bu yapılmadan Flutter Web kaldırılırsa iş kuralları sessizce
   ayrışır — matrisin var olma sebebi bu.
2. **22 yüzey testini "parite" iddiasından çıkar.** Mobil kendi testine sahip
   olur, eşitlik aranmaz.
3. **11 landing testini sil.** Flutter tanıtım sayfası yayından kalktığı gün.
   Tek satır iş, en sona bırakılabilir.

**Bedeli ölçülü:** 11 Eylül gecesi `landing-esitlik-contract.test.ts` iki kez
kırıldı (ikon değişikliği ve blog metni). İkisi de gerçek bir hata değildi —
artık var olmayacak bir yüzeyle eşitlik zorunluluğuydu.

Kilitleyen test: `public_web/tests/mobil-web-uyum-matrisi-contract.test.ts`
