# Tek Asistan Planı

Vixrex bugün dört yüzeyde çıkıyor ama **üç ayrı beyinle** çalışıyor. Bu
belge o paralel yapıdan nasıl çıkacağımızı tanımlar.

Kullanıcının şartı: **karşılama ekranlarının sayısı azalmayacak.** Dört
giriş de kalacak; birleşecek olan beyin, yüzeyler değil.

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

Ölü kod: `lib/widgets/vixrex_panel.dart` — 607 satır, hiçbir yerden
çağrılmıyor. Yarım kalmış dördüncü deneme.

### Paralel yapı tam olarak nerede

| | Flutter | Next.js |
|---|---|---|
| Alan tanımı | `VixRexProfileSnapshot` — 6 adımlık enum | `vitrinFieldSchema.ts` — 41 alan (tip, etiket, ipucu) |
| "Eksik ne" motoru | `nextMissingField` (210 satır) | `vitrinReadiness.ts` (111 satır) |
| Mesaj katalogu | `chatbot_config.dart` — 465 satır, 56 mesaj | Panelin içine gömülü |
| Eylemler | `VixRexAction` — 20 eylem | Yok, doğrudan çağrı |

İki taraf **aynı soruyu** soruyor — *"ne eksik, sırada ne var, ne
diyeyim"* — farklı veriyle, farklı kodla cevaplıyor. Esnafın gördüğü
çelişki buradan doğuyor.

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

## Plan — üç aşama

### Aşama 2 — Tek mesaj katalogu  ← ÖNCE BU

Asistanın söylediği her cümle tek dosyada, anahtarla tutulur.
`chatbot_config.dart`'taki 56 mesaj oraya taşınır; Next.js paneli de
aynı kaynaktan okur.

**Neden önce:** En görünür sonucu verir (tek yüz, tek dil), en az riski
taşır, Aşama 1'i beklemez. Kullanıcı "tek asistan" derken önce dilin ve
tonun aynı olmasını kastediyor.

**Bittiğinde:** Bir cümleyi değiştirince iki tarafta birden değişir.

### Aşama 1 — Tek şema

`vitrinFieldSchema.ts` zaten daha zengin ve doğru kurulmuş (41 alan,
"bir satır = bir alan"). Tarafsız bir tanım dosyasına çıkarılır; Flutter
karşılığı ondan **üretilir**, elle yazılmaz.

Flutter'ın 6 adımlık enum'u yerini şemadan hesaplanan sıraya bırakır.

**En riskli aşama:** şema değişince Flutter'ın kayıt ve yayın akışı da
etkilenir. Yarım gün, dikkatli gidilmeli.

### Aşama 3 — Tek "sırada ne var" motoru

`nextMissingField` ile `vitrinReadiness` aynı kuralı uygular; kural
şemadan gelir. İki dosya kalır ama kararı ikisi de aynı yerden alır.

---

## Değişmeyecekler

- **Karşılama ekranı sayısı azalmaz** — maskot, telefon görseli, Vixrex
  sekmesi, tarayıcı paneli; dördü de kalır
- Manuel form paneli kalır (VIXREX_RULES §1)
- Yasal onay akışı kalır
- Şablon kataloğu kalır

Bunlar `test/kurulum_akisi_contract_test.dart` ile kilitli (10 test).
Biri silinirse test kırmızı olur.

## Yol üstünde silinecek

`lib/widgets/vixrex_panel.dart` — ölü kod.

---

## Dürüst maliyet

Üç aşama bir günlük iş değil. Aşama 1 tek başına yarım gün ve en riskli
kısım. Sıra bilinçli olarak **2 → 1 → 3** seçildi: önce görünür ve
güvenli olan.
