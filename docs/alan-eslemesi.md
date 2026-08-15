# Alan eşlemesi — Faz F ön çalışması

**Durum:** keşif tamamlandı, kod yazılmadı. PLAN.md'nin Faz F için istediği
"kod yazılmadan önce eşleme tablosu" adımı. Bu belge canlı koda bakılarak
üretildi (2026-08-15) — PLAN.md'nin taslak tablosu değil, doğrulanmış hâli.

## Özet — geçerli mi, ne kadarı geçerli

PLAN.md'nin Faz F gerekçesi ("`nextMissingField`, `vitrinReadiness.ts`,
`guidance_service`'in 5 kalite kalemi aynı kuralı uygular") **kısmen
yanlış** — ve bunun kaydı zaten var: `docs/adr/0001-vixrex-core-omurga-ve-uzman-beyinler.md`
madde 4, 2026-08-10'da (Faz F planından birkaç gün önce) tam bu soruyu
inceleyip **"meşru uzmanlaşma olarak KALDI, birleştirilmedi"** kararını
vermiş. ADR'nin kendi ifadesiyle: Flutter'ın 5 kalite kalemi ile şemanın 7
`kalite` alanı bilerek örtüşmüyor, birleştirmek "basit bir liste değişimi
değil, ayrı bir tasarım kararı" gerektiriyor.

**Sonuç:** Faz F ikiye ayrılmalı.

| Parça | ADR 0001 ile ilişki | Bu turda yapılsın mı |
|---|---|---|
| A. Zorunlu alan eşlemesi (adres bölünmesi, doğrulama/boş-değer işaretleri) | ADR'nin "iyi örnek" dediği omurga deseninin devamı — şemadaki `zorunlu` seti zaten paylaşılıyor, yalnız eksiği tamamlanıyor | **Evet** |
| B. Kalite kalemi / rehberlik motoru birleşimi (`VixRexGuidanceService` ↔ `kaliteAlanlari`) | ADR'nin AÇIKÇA "bu turda yapılmadı" dediği, ayrı tasarım kararı istediği parça | **Hayır — bu PR'da değil.** Ayrı bir ADR-takip kararı gerekir, Faz F'nin bir alt maddesi olarak sessizce yapılmaz |

Aşağıdaki tablo yalnız A parçasını kapsar.

## Eşleme tablosu (doğrulanmış)

| Flutter (`VixRexProfileSnapshot`) | Şema (`vitrinFieldSchema.ts` / `vitrin_alanlari.g.dart`) | Bugünkü durum | Karar |
|---|---|---|---|
| `nameCompleted` | `isletmeAdi` (zorunlu) | Şemadan geliyor (`zorunluAlanlar`), `_alanDolu` switch'inde ayrıca elle kontrol var | Aynı kalır |
| `whatsappCompleted` | `whatsapp` (zorunlu) | Flutter ek olarak `WhatsAppLinkHelper.isValidTurkeyMobile` ile TR mobil formatı doğruluyor; şema bunu bilmiyor | Şemaya `dogrulama` alanı eklenir (bkz. aşağı), Next.js tarafı bugün bu doğrulamayı YAPMIYOR — **bilinen fark, bu PR onu gidermez, yalnız görünür kılar** |
| `addressCompleted` | yalnız `adres` (zorunlu) | **Gerçek eksik, üçüncü bir kontrol noktasıyla birlikte**: `VixRexProfileSnapshot.addressCompleted` VE ondan tamamen ayrı `store_publish_validator.dart` (asıl yayın kapısı) ikisi de `address`+`provinceName`+`districtName` üçünü BİRLİKTE zorunlu sayıyor; şemada il/ilçe hiç alan olarak yok. Next.js tarafında bunu zorunlu kılan HİÇBİR ŞEY yok (doğrulandı — `province`/`district` sıfır eşleşme). DB'de de (`stores.province_name`/`district_name`) NOT NULL değil | Şemaya `il` ve `ilce` **yeni zorunlu alan** olarak eklenir. DB migration GEREKMEZ — kolonlar zaten var (`province_code/name`, `district_code/name`), yalnız NULL/boş olabiliyorlar; şema onları artık "zorunlu" işaretler |
| `categoryCompleted` | `kategori` (zorunlu) | "Diğer" dolu sayılmama kuralı yalnız Flutter'da (`categoryCompleted` getter'ında elle) var; Next.js'in `doluMu()`'su yalnız boş-string kontrolü yapıyor, "Diğer"i dolu sayar | Şemaya `bosDegerler: ["diger","diğer"]` eklenir, `doluMu`/`_alanDolu` bunu okur |
| `descriptionCompleted` | `kisaTanitim` (kolon: `description`) | ADR 0001'in kaydettiği tuzak: Flutter kısa `description`'a bakar, uzun `hakkindaMetin`'e (`corporate_bio`, kalite alanı) DEĞİL. İkisi gerçekten ayrı alan | **Ayrı kalır**, birleştirilmez — ADR'nin kendisi bunu zaten netleştirmiş |
| `coverCompleted` | `kapakGorseli` (kalite, kolon: `shelf_image_url`) | Zorunlu değil, kalite alanı; Flutter yine de kendi "sıradaki adım" sırasında (yayın sonrası) buna bakıyor | Karışıklık yok — `nextMissingField` zorunlu kümeyle sınırlı, `kapakGorseli` oraya girmiyor zaten |
| `galleryCompleted` | — (şemada yok) | Flutter'a özgü operasyonel durum (galeri öğesi var mı) | Şemaya **girmez** — ADR 0001 madde 4 ile aynı gerekçe |
| `catalogCompleted` | — (şemada yok) | Ürün/hizmet sayısı, vitrin içerik alanı değil | Şemaya **girmez** |
| `autoFillCompleted` | — (şemada yok) | Kategori-şablon görseli uygulandı mı — Flutter'a özgü | Şemaya **girmez** |
| `legalCompleted` | — (şemada yok, akış aşaması) | DB tetikleyicisi zaten var (`PUBLICATION_CONSENT_REQUIRED`, `20260805180000_add_publish_and_discard_working_draft.sql`) | Şemaya girmez, akış aşaması olarak kalır — **dokunulmuyor** |

## Şemaya eklenecek somut değişiklik (A parçası, bu PR'ın kapsamı)

1. `VitrinField`/`VitrinAlani` tipine üç yeni **isteğe bağlı** alan:
   - `dogrulama?: string` — doğrulama kuralının adı (ör. `"tr_mobil"`). Bu
     turda yalnız WhatsApp alanına yazılır, gerçek doğrulama mantığı
     Next.js'e taşınmaz (o ayrı bir iş — burada yalnız işaretleniyor).
   - `bosDegerler?: string[]` — dolu sayılmayacak değerler (kategori için
     `["diger","diğer"]`).
   - `sira?: number` — Faz F'nin ikinci yarısının (bu PR'da değil) ihtiyaç
     duyacağı açık sıra numarası. Bu turda eklenirse de kullanılmaz; PLAN.md
     madde 2'nin önerisi ama bu belge onu **zorunlu kılmıyor** — eklemek
     istersen ayrı bir küçük karar.
2. İki yeni alan: `il` (kolon: `province_name`, zorunlu) ve `ilce` (kolon:
   `district_name`, zorunlu).
3. `vitrinReadiness.ts`'in `doluMu()`'su `bosDegerler`'ı okur.
4. Flutter tarafı: `VixRexProfileSnapshot._alanDolu` switch'ine `il`/`ilce`
   case'leri eklenir; `addressCompleted` getter'ı üç ayrı alana bölünmüş
   hâliyle YENİDEN KURULMAZ — geriye dönük uyumluluk için AYNI davranışı
   (üçü birlikte) döndürmeye devam eder, yalnız artık şemadan 3 ayrı
   `zorunluAlanlar` girdisi gelecek olması `sonrakiEksikZorunluAlan`'ın
   sırasını etkiler (adres artık tek adım değil, üç adım).

## Etkilenen yüzeyler (blast radius)

| Yüzey | Etki | Kanıt seviyesi gerekli |
|---|---|---|
| Flutter kurulum sohbeti (`vixrex_onboarding_controller.dart`) | `sonrakiEksikZorunluAlan` artık adres yerine önce il, sonra ilçe, sonra adres isteyebilir — `_resumeSavedVitrin`/`nextMissingField` akışı değişir | test + elle iki cihaz senaryosu |
| `test/kurulum_akisi_contract_test.dart` | PLAN.md'nin kendisi bunun güncelleneceğini söylüyor — beklenen, testi gevşetme değil | test |
| Next.js `OwnerAssistantPanel`/`hazirlikRaporu` | Toplam alan sayısı 43→45 olur (il+ilce eklenince), `yuzde` hesap tabanı değişir, "temel alan eksik" mesajları artık il/ilçeyi de sayar | test + `public_web/tests` sentinel'leri |
| Yayın kapısı (`store_publish_validator.dart`, Next.js publish akışı) | Şu an il/ilçe boşken bile Next.js üzerinden yayın engellenmiyor olabilir (kontrol edilmedi — **bu PR'ın kapsamına eklenmeli**) | kod okuma + varsa canlı doğrulama |
| DB | Yok — kolonlar zaten var, migration gerekmiyor | — |
| `assistant_state_test.dart` (Faz E golden test) | `toplamAlan`/`doluAlan` sayıları değişir (zorunlu alan sayısı 4→6 olur) ama testler `snapshot.totalRequiredStepCount`'a göreceli kaldığı için otomatik uyum sağlar | test yeniden çalıştırılır, sayı elle kilitlenmemiş olduğu doğrulanır |

## Risk sınıflandırması

| Risk | Olasılık | Etki | Azaltma |
|---|---|---|---|
| Adres bölünmesi kurulum akışını üç adıma çıkarır, kullanıcı deneyimini uzatır | Orta | Düşük-orta (UX, veri kaybı yok) | `kurulum_akisi_contract_test.dart` güncellemesi + tek elle uçtan uca deneme |
| Next.js `hazirlikRaporu` yüzdesi geriye düşer (yeni 2 zorunlu alan eklenince mevcut yayınlı vitrinler "eksik" görünebilir) | Yüksek (43 alan → 45, mevcut hiçbir vitrin il/ilçeyi "zorunlu" olarak doldurmamıştı) | Orta — sahiplerin paneli "eksik" gösterir ama **yayından düşürmez** (legal trigger'a dokunulmuyor, yalnız görüntü) | Rapor metnini kontrol et: "temelTamam" false olan mevcut yayınlı vitrin sayısı canlıda kaç — mümkünse ölçülür |
| Next.js yayın akışı il/ilçeyi hiç bilmiyor — **doğrulandı**: `public_web/src/lib` ve `src/app/api/` içinde `province`/`district` sıfır eşleşme. Yalnız Flutter'ın `store_publish_validator.dart` (asıl yayın kapısı — `VixRexProfileSnapshot`'tan AYRI, üçüncü bir kontrol noktası) bunu zorunlu tutuyor | — (doğrulandı, artık varsayım değil) | Orta — Next.js sahip panelinden bir gün doğrudan yayın/güncelleme eklenirse il/ilçesiz vitrin yayınlanabilir; bugün risk düşük çünkü tek yayın yolu Flutter | Şemaya `il`/`ilce` eklenmesi bunu da kapatır — Next.js artık bu iki alanı `zorunlu` görür |
| Kalite kalemi birleşimi (B parçası) yanlışlıkla bu PR'a sızar | Düşük (bu belge net ayırdı) | Yüksek (ADR 0001 ihlali, ayrı tasarım kararı gerektiren işi habersiz yapmak) | Bu belge + PR açıklamasında açık sınır |
| İki bağımsız zorunlu-alan kontrolcüsü (`VixRexProfileSnapshot`, `store_publish_validator.dart`) birbirinden sapar | **Gerçekleşti** — `validateStore`'un kategori kontrolü "Diğer"i dolu sayıyordu, `categoryCompleted` saymıyordu | Orta — "Diğer" kategoriyle bir mağaza yayınlanabiliyordu ama asistan onu hep "eksik" gösteriyordu | Düzeltildi (bkz. aşağı, 2026-08-15 güncellemesi) — şemanın `bosDegerler`'ı tek kaynak yapıldı |

## Önerilen sıra (bu belgenin ürettiği karar, henüz uygulanmadı)

1. ~~Next.js publish/validate yolunu oku, il/ilçe zorunluluğunun bugün orada
   olup olmadığını kesinleştir~~ — **tamamlandı, bu belgede**: Next.js hiç
   bilmiyor, yalnız Flutter'ın `store_publish_validator.dart`'ı biliyor.
2. Şemaya `il`/`ilce` + `dogrulama`/`bosDegerler` alanlarını ekle
   (`vitrinFieldSchema.ts` → `alan_semasi_uret.dart` ile üret, elle `.g.dart`
   düzenlenmez).
3. `VixRexProfileSnapshot._alanDolu` + `vitrinReadiness.ts`'in `doluMu()`
   güncellemesi.
4. `kurulum_akisi_contract_test.dart` bilinçli güncelleme (PLAN.md'nin
   öngördüğü, beklenen değişiklik).
5. Kalite kalemi/rehberlik motoru birleşimi (B parçası) **bu işe dahil
   edilmez** — ayrı, ADR-takip gerektiren bir karar olarak bırakılır.

## Güncelleme — 2026-08-15, A parçası + kalan işler tamamlandı

- **A parçası kodlandı, doğrulandı, main'e getirildi** (PR #168 → yanlış
  ara dala merge oldu → PR #169 ile main'e senkronize edildi).
- **PLAN.md'nin istediği cross-language "sapma testi" eklendi**
  (`test/zorunlu_alan_baglanti_test.dart` +
  `public_web/tests/zorunlu-alan-baglanti.test.ts`). Dart testi ilk
  çalıştırmada GERÇEK bir sapma yakaladı: `_alanDolu('adres')`
  `addressCompleted`'i (adres+il+ilçe birlikte) kullandığı için il/ilçe
  eksikken bile ilk sırada "adres" raporlanıyordu, `il`/`ilce` case'lerine
  hiç sıra gelmiyordu. `VixRexProfileSnapshot`'a ham `address` alanı
  eklenerek düzeltildi.
- **İki-validator sapması (yukarıdaki risk tablosu) düzeltildi**:
  `store_publish_validator.dart`'ın kategori kontrolü artık şemanın
  `bosDegerler`'ını okuyor, "Diğer"i `categoryCompleted` ile tutarlı
  şekilde eksik sayıyor. Validator'ın geri kalanı (iki ayrı
  `validateVitrin`/`validateStore` yolu, `VixRexProfileSnapshot`'la genel
  birleşimi) **bilinçli olarak dokunulmadı** — bu Faz F'nin kapsamının
  dışında, ayrı ve daha büyük bir refactor.
- **B parçası (kalite kalemi birleşimi) — `qualityItems()` ile
  birleştirilmedi, ADR 0001 doğru.** `VixRexGuidanceService.qualityItems()`'a
  şemayla eşleme tablosunu içeren kod-içi belge eklendi
  (`test/kalite_kalemi_semasi_test.dart` bu sınırı kilitler).
- **Ama ayrı, gerçek bir bulgu çıktı:** `qualityItems()`/`qualityReportFor()`
  **ölü kod** — ürettiği skor hiçbir çağrı noktasında `ChatMessage.snapshotScore`'a
  yazılmıyor, `ChatScoreBar` hiçbir zaman ekrana çıkmıyor (doğrulandı).
  Esnafa GERÇEKTEN gösterilen liste `improvementRecommendations()`.
  O listede de şemanın 6 kalite alanı (kapak dışındakiler: heroRozet,
  logo, calismaSaatleri, haritaLinki, hakkindaBaslik, hakkindaMetin) hiç
  yoktu — esnaf yalnız telefonu kullanıyorsa bu 6 alan hiç dürtülmüyordu.
  **Bu 6'sı ayrı ayrı (birleştirmeden) `improvementRecommendations()`'a
  eklendi** — `VixRexProfileSnapshot`'a 6 yeni `*Completed` alanı,
  `test/vixrex_guidance_improvement_test.dart`'a bu motorun hiç olmayan
  ilk testleri (8 test) eklendi.

Bu belge onaylanmadan kod yazılmadı.
