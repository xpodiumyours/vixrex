# Dal durum haritası — `docs/canli-test-bulgulari`

main'e inmeden önce: **neyin gerçekten çalıştığı, neyin sadece yazıldığı.**

54 commit, 248 dosya. Aşağıdaki tablo körlüğü bitirmek için.

## Kanıt seviyeleri (VIXREX_RULES §5)

| Seviye | Anlamı |
|---|---|
| 🔴 kodda görüldü | Yazıldı, hiç çalıştırılmadı |
| 🟠 test var | Otomatik test geçiyor, ekranda görülmedi |
| 🟡 yerelde görüldü | Bir kez ekranda çalıştı |
| 🟢 canlıda doğrulandı | Casper gerçek ortamda gördü |

---

## A. Sağlam — test + Casper doğruladı

| İş | Kanıt | Not |
|---|---|---|
| Yayınla / vazgeç | 🟢 | 14 sözleşme testi + canlıda doğrulandı |
| Sahip oturumu güvenlik zinciri | 🟢 | Tek kullanımlık kod, HMAC çerez, fail-closed |
| Taslak yalıtımı | 🟠 | `working-draft-isolation.test.ts` |
| XSS açığı (blog sanitizer) | 🟠 | `sanitize.test.ts`, 11 test — gerçek açık kapandı |
| Migration zinciri | 🟡 | `db reset` baştan sona çalışıyor |
| Şema tek kaynak (44 alan) | 🟠 | `vitrin-field-schema.test.ts` |

## B. Yazıldı, ekranda görülmedi

| İş | Kanıt | Risk |
|---|---|---|
| Canlı senkron (realtime) | 🔴 | Bulutta yayın yeni açıldı, hiç denenmedi |
| Kategori adımı (kurulum sohbeti) | 🟠 | Sözleşme testi var; **balonların dizilişi bozuk** (bulgu 1) |
| Tek asistan — "sen" kipi | 🟠 | Ton testi var, akış ekranda izlenmedi |
| Adres doğrulama | 🟠 | 11 test |
| Kiralama bandı | 🔴 | Vitrine bağlandı, ekranda görülmedi |
| QR kod | 🟡 | Ekranda göründü |

## C. Düzeltildi sanıldı — turda çürüdü

| İş | Ne sanıldı | Gerçek |
|---|---|---|
| GPS konumu | Hassasiyet 30m → 10m düzeltildi | **Şikayet bu değildi.** Koordinat geliyor, adres gelmiyor (bulgu 2) |
| Kapak fotoğrafı | Unsplash adresleri silindi | Dekorasyon vitrininde hâlâ kot fotoğrafı (bulgu 3) — önizleme adresinde teyit gerek |
| 41 alan düzenleme | Şema tekleşti | Panelde 12 alan görünüyor, 32'sine ulaşılamıyor (bulgu 5) |

## D. Hiç ele alınmamış — turda çıktı

| İş | Bulgu |
|---|---|
| Sahip oturumu 15 dk, yenilenmiyor | 4 |
| Eylem butonları sahip modunda dışarı atıyor | 6 |

---

## Sonuç — main'e ne inebilir

**A grubu bugün inebilir.** Testi var, doğrulandı, geri dönüşü kolay.

**B grubu** turda bir kez görülünce iner.

**C ve D** açık iş. Bunlar `docs/tur-bulgulari-2026-08-06-aksam.md`
listesinde; kapanmadan inmez.

Kural: bir iş bir günden fazla dalda kalmaz. Liste biter, Casper tek
adreste bakar, aynı gün main'e iner.
