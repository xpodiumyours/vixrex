# Tek Asistan Planı

Vixrex bugün dört yüzeyde çıkıyor ama **üç ayrı beyinle** çalışıyor. Bu
belge o paralel yapıdan nasıl çıkacağımızı tanımlar.

Kullanıcının şartı: **karşılama ekranlarının sayısı azalmayacak.** Dört
giriş de kalacak; birleşecek olan beyin, yüzeyler değil.

---

## Durum: PLAN TAMAMLANDI (2026-08-17)

Üç aşama da koda girdi ve CI'da sapma kontrolüyle kilitlendi. Aşağıdaki
aşama açıklamaları planın nasıl yapıldığını anlatır; güncel gerçek her
zaman koddadır (CONTEXT.md vault kuralı: çelişkide kod kazanır).

| Aşama | Sonuç | Kanıt (kod) |
|---|---|---|
| 2 — Tek mesaj katalogu | ✅ Tamamlandı | `shared/vixrex_mesajlar.json` + üretilen `lib/config/vixrex_mesajlar.g.dart`; `chatbot_config.dart` 465→389 satır, 56 mesajı katalogdan okuyor. CI `schema-drift` sapma kontrolünde. |
| 1 — Tek şema | ✅ Tamamlandı | `public_web/src/lib/vitrinFieldSchema.ts` → `shared/vitrin_alanlari.json` → üretilen `lib/config/vitrin_alanlari.g.dart`. 6 adımlık `VixRexProfileStep` enum'u kalktı; zorunluluk şemadaki `zorunlu` işaretinden gelir. CI `schema-drift` sapma kontrolünde. |
| 3 — Tek "sırada ne var" motoru | ✅ Tamamlandı | Flutter `nextMissingField` (`lib/services/vixrex_profile_snapshot.dart`) ve Next.js `vitrinReadiness.ts` ikisi de şemadaki `zorunlu` işaretinden karar verir. |

**Yol üstünde silinecek** denilen ölü kod `lib/widgets/vixrex_panel.dart`
(607 satır) silindi.

**Not (plan dokümanı 6 Ağustos'tan beri eski kalmıştı):** aşamalar
Ağustos ortasında koda girdi ama bu belge güncellenmemişti — 2026-08-17'de
kod doğrulamasıyla (yukarıdaki kanıtlar) "tamamlandı" işaretlendi.

---

## Bugünkü durum

### Vixrex nerede çıkıyor

| # | Nerede | Kod | İşi |
|---|---|---|---|
| 1 | Karşılama — sağ alt maskot | `ChatbotBadge` → `VixRexOnboardingChatScreen` | Kurulum: ad → WhatsApp → konum → onay → yayın |
| 2 | Karşılama — telefon görseli | Aynı ekran | Birebir aynı sohbet |
| 3a | Vixrex sekmesi, yayın yoksa | Aynı ekran | Yine kurulum |
| 3b | Vixrex sekmesi, yayın varsa | `VixRexCompanionChat` | Rehber: şablon → ürün → paylaş |
| 4 | Vitrin sayfası (tarayıcı) | `OwnerAssistantPanel` | Tıkla-düzenle, 41 alan, yayınla |

### Paralel yapı — bugün

Plan öncesi iki taraf aynı soruyu ("ne eksik, sırada ne var, ne diyeyim")
farklı veriyle cevaplıyordu. Bugün karar ve kelimeler tek kaynaktan gelir:

| | Flutter | Next.js |
|---|---|---|
| Alan tanımı | `lib/config/vitrin_alanlari.g.dart` (şemadan üretilir) | `vitrinFieldSchema.ts` |
| "Eksik ne" motoru | `nextMissingField` (`vixrex_profile_snapshot.dart`) | `vitrinReadiness.ts` |
| Mesaj katalogu | `vixrex_mesajlar.g.dart` (şemadan üretilir) | `shared/vixrex_mesajlar.json` |
| Ortak veri | `shared/vitrin_alanlari.json` + `shared/vixrex_mesajlar.json` | aynı |

Ekranlar ayrı kalır; **karar ve kelimeler ortaklaşır.**

---

## Kritik gerçek

Flutter ile Next.js aynı kodu çalıştıramaz. Ama asistanın beyni kod
değil **veri**:

- hangi alanlar var
- hangisi zorunlu, hangisi kalite
- her biri için ne denir
- hangi eylemler mümkün

Bu veri tek yerde durabilir. Ekranlar ayrı kalır; **karar ve kelimeler
ortaklaşır.**

---

## Plan — üç aşama (nasıl yapıldı)

### Aşama 2 — Tek mesaj katalogu  ← ÖNCE BU

Asistanın söylediği her cümle tek dosyada, anahtarla tutulur.
`chatbot_config.dart`'taki 56 mesaj oraya taşınır; Next.js paneli de
aynı kaynaktan okur.

**Neden önce:** En görünür sonucu verir (tek yüz, tek dil), en az riski
taşır, Aşama 1'i beklemez. Kullanıcı "tek asistan" derken önce dilin ve
tonun aynı olmasını kastediyor.

**Bittiğinde:** Bir cümleyi değiştirince iki tarafta birden değişir. ✅

### Aşama 1 — Tek şema

`vitrinFieldSchema.ts` zaten daha zengin ve doğru kurulmuş (41 alan,
"bir satır = bir alan"). Tarafsız bir tanım dosyasına çıkarılır; Flutter
karşılığı ondan **üretilir**, elle yazılmaz.

Flutter'ın 6 adımlık enum'u yerini şemadan hesaplanan sıraya bırakır.

**En riskli aşama:** şema değişince Flutter'ın kayıt ve yayın akışı da
etkilenir. Yarım gün, dikkatli gidilmeli. ✅

### Aşama 3 — Tek "sırada ne var" motoru

`nextMissingField` ile `vitrinReadiness` aynı kuralı uygular; kural
şemadan gelir. İki dosya kalır ama kararı ikisi de aynı yerden alır. ✅

---

## Değişmeyecekler

- **Karşılama ekranı sayısı azalmaz** — maskot, telefon görseli, Vixrex
  sekmesi, tarayıcı paneli; dördü de kalır
- Manuel form paneli kalır (VIXREX_RULES §1)
- Yasal onay akışı kalır
- Şablon kataloğu kalır

Bunlar `test/kurulum_akisi_contract_test.dart` ile kilitli (10 test).
Biri silinirse test kırmızı olur.

---

## Dürüst maliyet (tarihsel)

Üç aşama bir günlük iş değil. Aşama 1 tek başına yarım gün ve en riskli
kısım. Sıra bilinçli olarak **2 → 1 → 3** seçildi: önce görünür ve
güvenli olan.
