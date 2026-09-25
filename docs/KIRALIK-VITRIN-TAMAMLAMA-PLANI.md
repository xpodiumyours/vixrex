# Kiralık Vitrin — Eksik Tamamlama ve Canlıya Alma Planı

Tarih: 2026-09-25 · Dal: `faz1/toplu-kapi-kalite` · Kapsam: 30 kiralık vitrin (teknik işaret `stores.is_demo`)
Bu dosya bir öneri listesidir, emir değil. Her iş paketi Casper onayıyla başlar (bkz. CLAUDE.md §ÖNCE SOR).

---

## 0. Özet — iş nerede duruyor

| durum | iş |
|---|---|
| **Canlıda bitti** | 30 vitrin yayında ve sahibi yok; ürün özellik/hizmet satırı 182/182 dolu; puan bandı 30/30 açık ve puanlar çeşitli; migration geçmişi `repair --status applied` ile işaretli |
| **Canlıda bitti (2026-09-25)** | Slug geçişi `demo-*` → `kiralik-*` (4 vitrin) · ürün fotoğraflarının vitrin içinde çeşitlendirilmesi · eski adres yönlendirmesi (kod yazıldı, **deploy bekliyor**) |
| **Karar bekliyor** | Fotoğrafın kaynağı (ürün adına uygun görsel nasıl elde edilecek) · ürün başına özellik çeşitlendirmesi · kiralık vitrinler arama motoruna açılsın mı |
| **Bilinen kırık** | `20260925090000` migration'ındaki `h.havuz` kapsam hatası → `supabase db reset` ve CI temiz zinciri düşürüyor |
| **Doğrulanmadı** | Kiralama akışı (Kirala bandı → vitrin kopyası → sahip paneli → yayın) bu ortamda gerçek tarayıcıda uçtan uca denenmedi |
| **Commit'lenmedi** | 3 yeni dosya + 3 değişik dosya (bkz. İş Paketi 8) |

---

## 1. Bugünkü durum (canlı ölçüm, 2026-09-25)

**İçerik ve vitrin doluluğu — gerçekten dolu:**

| ölçüm | sonuç |
|---|---|
| yayında, sahibi olmayan vitrin | 30 / 30 |
| vitrin başına ürün | 6 (TeknoFix 8) |
| vitrin başına ürün kategorisi | 3 (TeknoFix 4) |
| blog yazısı (yayınlı) / galeri / SSS | 3 / 5 / 4 |
| kurumsal metin, tanıtım, hakkımızda başlığı | 30'u da birbirinden farklı |
| ürün açıklaması boş · fiyatı boş | 0 · 0 |
| özellik veya hizmet satırı dolu ürün | 182 / 182 (60'ı hizmet ürünü) |
| puan bandı + puan/yorum çeşitliliği | 30 / 30 |
| WhatsApp, adres, logo, kapak, çalışma saatleri | var |
| dış bağlantılı görsel (Unsplash vb.) | 0 |

**Fotoğraf — en büyük eksik:**

| ölçüm | sonuç | hedef |
|---|---|---|
| 182 ürünün paylaştığı toplam farklı görsel | **21** | ürün sayısına yakın |
| 30 vitrinde toplam farklı ilk fotoğraf | **7** | ≥ 150 |
| 6 ürünün 6'sı aynı ilk fotoğrafı gösteren vitrin | **28 / 30** | 0 |
| tek görseli paylaşan en kalabalık ürün grubu | **54 ürün** | 1 |
| fotoğraf dağıtımında kullanılabilen depo görseli | 82 dosya (7 kategori klasörü) | ürün başına 1-3 özgün kare |

**Kalan diğer bulgular:** 182 üründe 173 farklı ürün adı (9 ad iki vitrinde tekrar ediyor) · 4 vitrin hâlâ `demo-` adresli · kiralık vitrinler site haritasından bilinçli çıkarılmış (`public_web/src/app/sitemap.xml/route.ts:27` → yalnız `is_demo=false`) · Flutter karşılama ekranında iki kullanıcı-görünür "Demo vitrin" metni (`lib/screens/landing_screen.dart:373,381`).

---

## 2. İş Paketi 0 — Canlı işlemler

Amaç: hazır bekleyen iki düzeltmeyi canlıya almadan önce yedek, sonra uygulama, sonra ölçüm.

**Durum (2026-09-25): uygulandı.** Yedek alındı (`.scratch/geri-alma-slug-foto-20260925.sql`, 238 satır; sözdizimi canlıda `ROLLBACK` denemesiyle doğrulandı), iki migration canlıya koştu, geçmiş `applied` işaretlendi. Canlı ölçüm: `demo-` adres 0, `kiralik-` adres 30, eski adrese bağlı yazı 0, farklı fotoğraf 21 → 68, farklı ilk fotoğraf 7 → 61, tek fotoğraflı vitrin 28 → 0, bir fotoğrafı paylaşan en kalabalık grup 54 → 6. Eski adreslerin yönlendirmesi **kod deploy edilene kadar** canlıda çalışmaz.

| adım | ne yapılacak | kanıt / kabul kriteri | geri alma |
|---|---|---|---|
| 0.1 | Yedek: 30 vitrinin `slug` + 182 ürünün `image_urls` değerleri JSON ve SQL olarak alınır | `.scratch/geri-alma-slug-foto-20260925.sql` (BEGIN…COMMIT, tetikleyici kapalı) + `.json` | — |
| 0.2 | `20260925120000_kiralik_vitrin_sluglarini_yenile.sql` canlıya koşulur | `demo-` adresli vitrin 0, `kiralik-` 30, eski adrese bağlı makale 0 | 0.1'deki slug yedeği ters yönde uygulanır |
| 0.3 | `20260925130000_kiralik_vitrin_urun_fotograflarini_dagit.sql` canlıya koşulur | vitrin başına en az 6 farklı ilk fotoğraf, en az 8 farklı görsel, aynı ilk fotoğraf paylaşan vitrin 0 | 0.1'deki `image_urls` yedeği |
| 0.4 | `supabase migration repair --status applied 20260925120000 20260925130000 --yes` | geçmiş kaydı "applied" | geri alınabilir, veri değiştirmez |
| 0.5 | Gerçek tarayıcıda 4 yeni adres + eski adresin yönlendirmesi + bir vitrinin kart ızgarası | ekran görüntüsü; `/v/demo-aymira-giyim` → `/v/kiralik-aymira-giyim` | — |

Kuru koşu sonucu (canlıya yazmadan, `ROLLBACK`): `kiralik_slug 30 · demo_slug 0 · demo_makale 0 · tek_fotolu_vitrin 0 · en_az_farkli_ilk 6 · en_az_farkli_url 8 · yanlis_foto_adet 0`.

Bilinen tuzak: `store_articles_store_slug_fkey` yüzünden vitrin ve bağlı kayıtlar **tek ifadede** taşınmalı (ilk denemede `23503` ile düştü). `stores` üzerindeki `protect_landing_demo_stores` tetikleyicisi işlem boyunca kapalı kalır.

Efor: **S** (yaklaşık 1 saat, çoğu doğrulama).

---

## 3. İş Paketi 1 — Fotoğraf kimliği (en büyük eksik)

### 1.1 Vitrin içi çeşitlilik — hazır
Her ürün kendi kategorisinin havuzundan döndürülerek 3 görsel alır; her ürünün ilk görseli farklı olur. Yanlış havuz da düzelir (giyim vitrininde market fotoğrafı kalkar).
Kabul: `en_az_farkli_ilk ≥ 6`, `tek_fotolu_vitrin = 0`, `yanlis_foto_adet = 0`.

### 1.2 Ürün adına uygun fotoğraf — karar gerekiyor
1.1 tek başına yetmez: havuz kategori stoğudur, aynı kategorideki 5-10 vitrin aynı görselleri paylaşır ve "Deri Omuz Çantası" kartı çanta fotoğrafı göstermez. Üç yol var:

| seçenek | ne yapar | artı | eksi | efor |
|---|---|---|---|---|
| **A. Depoya ürün bazlı gerçek görsel yükle** | 182 ürün için 1-3 özgün kare (kategori başına 30-60 görsel) | Gerçek mağaza kalitesi; tam kontrol | Görsel üretimi/temin işi (insan veya stok lisans) | **L** |
| **B. Eski seed'in ürün bazlı fotoğraflarını bir kez indirip kendi depomuza koy** | Eski seed'de her ürünün adıyla eşleşen Unsplash adresi vardı (`supabase/migrations/20260921184712_kiralik_vitrin_standardini_tamamla.sql:181-200`); görseller indirilir, depoya yüklenir, veritabanı yalnız kendi depomuzu gösterir | Görsel üretimi gerekmez; eşleşme zaten ürün adı bazlı; dış bağlantı yasağı korunur | Lisans/yeniden dağıtım koşulları hukuken netleştirilmeli; görseller başka bir esnafın vitrininde de görünür | **M** |
| **C. Kategori havuzunu büyüt** | Kategori başına görsel 9-15 → 30+; vitrinler arası paylaşım seyrelir | Ürün eşleşmesi yok ama tekrar biter | Görsel sayısını artırmak da temin işi | **M-L** |

Öneri: **B + C birlikte** (B ürün eşleşmesini, C vitrinler arası tekrarı çözer). Karar verilmeden 1.2'ye başlanmaz.

Kabul kriteri: her ürünün ilk fotoğrafı ürün adıyla uyumlu; aynı kategori içinde iki farklı vitrinde aynı görselin tekrarı tanımlı bir eşiğin altında (öneri: %20); 182 üründe farklı görsel sayısı ≥ 150.

---

## 4. İş Paketi 2 — Taze zincir / CI kırığı

`supabase/migrations/20260925090000_demo_urun_foto_standardini_uc_cikar.sql` içindeki ikinci `UPDATE` bloğu havuzu `h2` takma adıyla bağlıyor ama gövdede `h.havuz` yazıyor (satır 107) → `missing FROM-clause entry for table "h"` (42P01). İlk blokta takma ad `h` olduğu için aynı satır orada doğru.

- Düzeltme: satır 107'de `h.havuz` → `h2.havuz` (tek kelime).
- Kabul kriteri: `supabase db reset` sıfırdan hatasız biter; CI'ın `grant-guard` işi yerel Supabase'i tam zincirden kurar ve yeşil geçer.
- Neden önemli: bu kırık dururken hiçbir PR'ın canlıya çıkışı güvenli değil, çünkü temiz kurulum test edilemiyor.
- Not: yerel taze kurulumun ürettiği içerik canlıyı birebir üretmiyordu (taze DB 144 ürünü özelliksiz ve 9 kategoriyi `generic` verirken canlıda aynı ölçüm 18 ürün ve 9 kategoriydi — ölçüm A1 öncesine ait). Bu fark ayrıca incelenmeli.

Efor: **S**.

---

## 5. İş Paketi 3 — Ürün başına özellik çeşitlendirme (karar bekliyor)

Bugün bir kategorideki tüm ürünler aynı özellik değerini taşıyor: Aymira'nın 6 kartında da **Siyah**, Nova Kuaför'de hep **60 dk · Sabit fiyat · İşletmede**, Lezzet Durağı'nda aynı alerjen satırı.

- Yapılacak: ürün başına farklı değer atayan bir migration (renk/beden/malzeme/porsiyon/hazırlık süresi vb.), `shared/product_attribute_schema.json` sınırları içinde.
- Kabul kriteri: aynı kategori içinde en az 4 farklı değer; hiçbir vitrinde 6 kartın 6'sı aynı satırı göstermiyor; guard tersini yakalarsa migration düşer.
- Risk: uydurma değer üretmek ürünü "sahte" gösterir. Karar: hangi alanlar çeşitlendirilecek (fiziksel ürünlerde renk/beden, hizmetlerde süre/kapsam).

Efor: **M**.

---

## 6. İş Paketi 4 — Kiralama akışı uçtan uca doğrulama

İş modelinin giriş kapısı vitrindeki "Kirala" bandı (`public_web/src/app/v/[slug]/VitrinProfileView.tsx:1392`, metin: "Kiralık vitrin standardı"). Bu oturumda **gerçek tarayıcıda denenmedi**; testler var ama ekran açılmadı.

- Adımlar: Kirala → vitrin kopyası oluşur → sahip paneli açılır → içerik düzenlenebilir → yayın kapısı (premium) doğru davranır.
- Kabul kriteri: her adımın ekran görüntüsü + bulunan her kırık için ayrı madde. Kırık varsa ayrı iş paketi açılır.
- Not: bu akış gerçek müşteri hesabı gerektirdiği için test hesabı ve önizleme adresi gerekir.

Efor: **M**.

---

## 7. İş Paketi 5 — Adres ve adlandırma süpürmesi

| ne | nerede | ne yapılacak |
|---|---|---|
| 4 vitrin adresi | canlı DB | 0.2'de halledilir |
| eski adresler | `public_web/src/app/v/[slug]/page.tsx` | hazır (kalıcı yönlendirme) |
| karşılama ekranı hata metni | `lib/screens/landing_screen.dart:373,381` | "Demo vitrin önizlemesi açılamadı" → "Kiralık vitrin önizlemesi açılamadı" (kullanıcı-görünür) |
| eski adres geçen test/dokümanlar | başka ajanların dosyaları (`landing-demo-preview-contract.test.ts` güncellendi; `kiralik-vitrin-30-contract.test.ts`, `unpublish-test-stores-contract.test.ts`, `kiralik-vitrin-standard-contract.test.ts` geçmiş migration metnini okuyor, kırılmıyor) | dokunulmaz; kırılan olursa tek tek ele alınır |
| klon köken notu | `stores.cloned_from_slug = 'demo-nova-kuafor'` (1 satır, yayında değil) | karar: eski notu tarih olarak bırak, yoksa yeni adrese çevir |

Efor: **S**.

---

## 8. İş Paketi 6 — Arama motoru görünürlüğü (karar bekliyor)

Kiralık vitrinler site haritasından bilinçli çıkarılmış (`is_demo=false` olanlar indeksleniyor). Yani bugün "kiralanabilir ama aranamaz" durumdalar.

- Seçenek 1 (mevcut hal): şablonlar indekslenmez, yalnız ana sayfa ve Keşfet indekslenir.
- Seçenek 2: kiralık vitrinler ayrı, kendi adresleriyle indekslenir (Google'a 30 sayfa girer; kopya içerik riski, çünkü 5-10 vitrin aynı kategori görsellerini paylaşır).
- Seçenek 3: şablon galerisi sayfası (Keşfet içinde "kiralık vitrinler" bölümü) indekslenir; tek tek vitrinler indekslenmez.
- Kabul kriteri: karar + uygulanacaksa sitemap/robots ölçümü ve `sitemap-demo-haric-contract.test.ts` güncellemesi.

Efor: **S-M** (karar verilirse uygulama küçük, test güncellemesi orta).

---

## 9. İş Paketi 7 — Vitrin içeriğini derinleştirme (ölçülen küçük eksikler)

| ne | bugün | öneri |
|---|---|---|
| ürün fotoğrafı sayısı | 3 | 4-6 (havuz büyüyünce) |
| SSS | 4 | 6 |
| galeri görseli | 5 | 8 |
| blog yazısı | 3 | 5 |
| ürün adı tekrarı | 9 ad iki vitrinde | her vitrine özgü ad |
| hizmet süreleri | sabit | ürün başına farklı |

Kabul kriteri: ölçüm tablosu güncel değerleri gösterir; hiçbir vitrin diğerinin kopyası değil.
Efor: **M**.

---

## 10. İş Paketi 8 — Dokümantasyon, commit, PR

- Güncellenecek: `GOREV-vitrin-kalite.md`, `docs/KIRALIK-VITRIN-KALITE-PLANI.md` (fotoğraf bölümü nihai hâle gelir), bu dosya.
- Commit'lenecek (yalnız kendi dosyalarımız): iki yeni migration, yeni sözleşme testi, `lib/screens/landing_screen.dart`, `public_web/src/app/v/[slug]/page.tsx`, `public_web/tests/landing-demo-preview-contract.test.ts`, `supabase/migrations/20260925110000_kiralik_vitrin_puanlari.sql` (başlık yorumu), dokümanlar.
- PR açılmadan önce: İş Paketi 2 bitmiş olmalı (yoksa CI temiz zincir adımı kırmızı).
- Kabul kriteri: PR'da yeşil `public_web` (lint/tipler/testler), `schema-drift`, `grant-guard`.

Efor: **S**.

---

## 11. İş Paketi 9 — Tek komutla kiralık vitrin kalite panosu

`tool/canli_durum.ts` bugün yalnız demo/foto durumunu gösteriyor. Bu planın bütün ölçümleri tek komuta indirilirse her turda elle SQL yazmak gerekmez.

- Kapsam: vitrin doluluğu (10 alan), ürün özellik/hizmet doluluğu, fotoğraf çeşitliliği (farklı ilk fotoğraf, farklı görsel, en kalabalık paylaşım), puan bandı, adres sayısı (`demo-` = 0 olmalı).
- Kabul kriteri: `node tool/canli_durum.ts` çıktısı bu plandaki tabloyu tek başına üretir.

Efor: **S-M**.

---

## 12. Sıra ve bağımlılıklar

```
0 (canlıya alma)  ──►  5 (adlandırma süpürmesi)  ──►  8 (commit/PR)
2 (h.havuz)       ──────────────────────────────────┘  (PR'dan önce şart)
1.2 kararı  ──►  1.2 uygulama  ──►  7 (içerik derinleştirme)
3 (özellik çeşitlendirme)  bağımsız, karar bekliyor
4 (kiralama akışı)         bağımsız
6 (arama motoru)           bağımsız, karar bekliyor
9 (ölçüm panosu)           her adımdan sonra faydalı
```

Efor özeti: S = 4 iş, M = 4 iş, L = 1 iş (fotoğraf temini).

---

## 13. Riskler ve önlemler

| risk | önlem |
|---|---|
| Canlı yazma sırasında tetikleyici/kısıt hatası | Yedek alınır, `protect_landing_demo_stores` işlem boyunca kapalı, guard blokları tutmazsa migration tümüyle geri alınır (tek transaction) |
| Yabancı anahtar kırılması | Vitrin + bağlı kayıtlar tek ifadede taşınır (kanıt: `store_articles_store_slug_fkey`) |
| Gerçek müşteri verisine dokunma | Bütün koşullar `is_demo = true AND user_id IS NULL`; `is_demo = false` hiçbir sorguda geçmez |
| Fotoğraf değişiminin görsel regresyon testleri kırması | Playwright baz çizgileri Linux'ta üretilir; içerik değişince baz çizgisi güncellemesi ayrı iş olarak planlanır |
| Başka ajanlarla çakışma | Dokunulmayacaklar: `README.md`, `CLAUDE.md`, `.claude/*`, `.gitignore`, `public_web/e2e/*`, `test-sonuc/`, `public_web/test-sonuc/`, `board.json`, `design-qa.md`, `build-apk-split.bat`, `tool/fotograf_kurali_uret.dart`, `public_web/playwright*.config.ts`, `public_web/design-qa/*` |
| Hayali ürün özelliği üretmek | İş Paketi 3 yalnız şemada tanımlı alanlarda ve vitrinin kendi kategorisinde çeşitlendirir |

---

## 14. Karar bekleyen maddeler (Casper)

1. **İş Paketi 0** — hazır bekleyen iki migration canlıya alınsın mı? (yedek + ölçüm dahil)
2. **İş Paketi 1.2** — A (yeni görsel temini), B (eski ürün fotoğraflarını kendi depomuza taşı), C (havuzu büyüt)? Öneri: B + C.
3. **İş Paketi 3** — ürün başına özellik çeşitlendirmesi yapılsın mı; hangi alanlar?
4. **İş Paketi 6** — kiralık vitrinler arama motoruna açılsın mı, açılacaksa hangi yolla?
5. **İş Paketi 7** — içerik derinleştirme bu turun kapsamına girsin mi?

---

## 15. Kapsam dışı (bilinçli)

- Gerçek müşteri vitrinleri (`is_demo=false`) ve onların içeriği.
- 26 mevcut `kiralik-*` vitrinin puan ve özellik verisi (yalnız yeni çeşitlendirme yazılır).
- Ödeme/premium iş akışı, Flutter panel davranışı, asistan paneli.
- Başka ajanların dosyaları (yukarıdaki liste).
- `supabase db push` ile toplu migration gönderimi (geçmişte canlıyı düşürme riski görüldü; cerrahi `db query --file` kullanılır).

---

## Ek — elde duran malzeme

| dosya | ne işe yarar |
|---|---|
| `supabase/migrations/20260925120000_kiralik_vitrin_sluglarini_yenile.sql` | slug geçişi (canlıya alınmadı) |
| `supabase/migrations/20260925130000_kiralik_vitrin_urun_fotograflarini_dagit.sql` | vitrin içi fotoğraf çeşitliliği (canlıya alınmadı) |
| `public_web/tests/kiralik-vitrin-slug-ve-foto-sozlesmesi.test.ts` | 17 kilit testi |
| `.scratch/kuru-kosu-uret-20260925.cjs` → `.scratch/kuru-kosu-20260925.sql` | canlıya yazmadan ölçüm (`ROLLBACK`) |
| `.scratch/kuru-kosu-aksesuar.cjs` | tek vitrinin yeni fotoğraf ataması |
| `.scratch/kalite-denetimi-vitrin2.sql` · `kalite-denetimi-foto.sql` · `kalite-denetimi-tekrar.sql` | bu plandaki tabloların kaynağı (salt okuma) |
| `.scratch/geri-alma-demo-icerik-20260925.sql` | özellik/puan geri alma (fotoğrafı geri almaz) |
| `.scratch/foto-once-sonra.html` | öncesi/sonrası görsel önizleme |
