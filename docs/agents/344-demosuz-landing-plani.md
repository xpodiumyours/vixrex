# #344 — Demo'suz Landing Planı (Web + APK birlikte)

> Durum: ONAY BEKLİYOR. Bu belge uygulamanın tek kaynağıdır; önceki "~3 dosya"
> tahmini YANLIŞTI, aşağıda kanıtlı kapsam vardır. Tarih: 2026-08-25

## 0. Kanıtla netleşen gerçekler

- `landing_screen.dart:53-210`: 4 sahte işletme profili (Aymira Giyim, Lezzet
  Durağı, Nova Kuaför, TeknoFix) — Unsplash URL'leriyle.
- `landing_screen.dart:232-281`: `_loadCategoryGalleryImages()` bu profillerin
  kapak/galerisini GERÇEK şablon görselleriyle değiştirir (`templateCategoryKey`
  → `category_image_templates`). Yani iskelet zaten şablona bağlı.
- `landing_screen.dart:361-366`: `_landingDemoDrafts` map → `/v/demo-*`
  önizleme linkleri (`is_demo=true` yayınlanmış vitrinler).
- `lib/models/store_data.dart:434+`: `StoreData.dummy()` fabrikası Aymira
  içerikli — **çağıranları tespit edilmeli** (aşağıda D1).
- `explore_controller.dart:31,90,99` + `explore_screen.dart:493`: Keşfet'te
  hazır `isExample` dürüstlük mekanizması VAR.
- Kontrat testleri bugünkü davranışı KİLİTLİYOR:
  - `test/kurulum_akisi_contract_test.dart:24-40` → `ChatbotBadge(`,
    `onOpen: _openMockupChat`, `LandingBottomCta(`, `_navigateToEditor`,
    `SizedBox(height: 96)`, `LandingTemplateCatalog(`
  - `test/hayalet_vitrin_test.dart:20` → `yayindaMi(`
  - `test/widget_test.dart:137` → "Landing maskotu telefon içi kurulum
    sohbetini açar"
  - `test/main_navigation_screen_test.dart`, `test/tek_agiz_contract_test.dart`
- Test FIXTURE'larındaki Aymira/Lezzet adları (explore/whatsapp/payload
  testleri) landing'den bağımsızdır — DOKUNULMAZ.

## 1. Yeni spesifikasyon (ürün kararı — Casper onaylı)

Mockup "sahte işletme vitrini" DEĞİL "şablon önizlemesi" olur:

| Öğe | Eski | Yeni |
|---|---|---|
| Mockup profilleri | 4 sahte işletme adı | 4 şablon kartı: `Butik Şablonu`, `Kafe Şablonu`, `Kuaför Şablonu`, `Teknik Servis Şablonu` (kategori etiketi başlık) |
| Kart içeriği | Sahte menü/linkler ("Trendyol" vb.) | Şablondan gelen gerçek görsel seti + jenerik çipler (Galeri/Menü/Randevu) |
| Mockup tıklaması | `/v/demo-*` dış bağlantı | Katalogdaki o kategori sheet'ini açar (şablonun kendi görselleri) |
| `_landingDemoDrafts` | Landing'de durur | Landing'den KALDIRIR; demo vitrinler yalnız keşfet `isExample` akışında yaşar |
| Maskot FAB | Sohbet açar | Kurulum formuna scroll+focus (sohbet motoru port edilemez) |

Değişmeyenler: tüm diğer bölümler (value/features/comparison/trust/steps/katalog/CTA/footer), tasarım dili, kırılımlar.

## 2. Dosya dosya değişiklik listesi

### Flutter (APK + web app)
1. `lib/screens/landing_screen.dart`
   - `_heroDemoProfiles` literal'leri → şablon-kaynaklı üretim (mevcut
     `_loadCategoryGalleryImages` mantığı korunur, isim/etiket alanları
     kategori bazlı olur)
   - `_landingDemoDrafts` + `_navigateToPreview` kaldırılır; yerine
     `_openTemplateSheet(categoryKey)` (katalog widget'ına public API eklenir)
   - `_openMockupChat` → `_focusSetupForm()` (scroll + focus)
2. `lib/models/landing_demo_profile.dart` → `landing_template_profile.dart`
   olarak yeniden adlandırılır; `name.contains('Aymira'|'TeknoFix')`
   dallanmaları silinir (satır 80,143)
3. `lib/widgets/landing/landing_hero_section.dart` + `phone_mockup.dart` +
   `chatbot_badge.dart`: yeni callback imzaları, metinler envanter §2 ile
   birebir (değişmez)
4. `lib/widgets/landing/landing_template_catalog.dart`: `openPreview(key)`
   public metodu eklenir
5. `StoreData.dummy()`: çağıranlar bulunup karar verilir (D1); landing
   kullanmıyorsa dokunulmaz

### Next.js (#344 Aşama 1 — ayrı PR)
6. `public_web/src/app/page.tsx`: redirect → SSR landing (envanter
   `docs/research/landing-port-envanteri-2026-08-25.md` + bu spec'in
   "şablon-merkezli" farkıyla)

## 3. Test stratejisi (Testi sonuca uydurma YASAK — spec değişti, testler
yeni spec'e bilinçli yazılır)

- C1 commit'i ÖNCE kontrat testlerini yeni beklentiye çevirir (kırmızı):
  - `kurulum_akisi_contract_test`: `_openMockupChat` yerine `_focusSetupForm`;
    `_landingDemoDrafts` bekleyen satır düşer; `Aymira|TeknoFix` geçmez
    iddiası EKLENİR (negatif test)
  - `widget_test.dart:137` → "Maskot kurulum formuna odaklanır"
  - `hayalet_vitrin_test`, `tek_agiz_contract_test`, `main_navigation_*`:
    yapısal pin'ler korunur (değişmez)
- Yeni test: landing kaynak kodunda `demo-aymira|demo-lezzet|demo-nova|`
  `demo-teknofix|Aymira Giyim|Nova Kuaför` geçmez (grep-test deseni,
  `kurulum_akisi_contract_test` tarzı)

## 4. Commit ve geri dönüş planı

Dal: `feat/demosuz-landing` (main'den). Kirli çalışma ağacındaki 25 dosyaya
dokunulmaz.

| Commit | İçerik | Doğrulama | Geri dönüş |
|---|---|---|---|
| C1 | Kontrat testleri yeni spec'e (kırmızı beklenir) | `flutter test test/kurulum_akisi_contract_test.dart` kırmızı | `git revert C1` |
| C2 | Flutter landing şablon-merkezli dönüşüm | analyze + contract + widget testleri yeşil | `git revert C2` — tek başına eski haline döner |
| C3 | Next.js landing portu (envanter + spec) | npm test + build + view-source kontrolü | `git revert C3`; `/` redirect'i geri gelir |

- APK: release build yalnız C2 merge + canlı doğrulama SONRASI üretilir;
  eski APK dağıtımı C2 merge edilene kadar devam eder.
- Ana dal koruması: yalnız PR ile; push kullanıcı onayıyla.

## 5. Uygulanacak doğrulama maddeleri (D = ajan çözüler)

- D1: `StoreData.dummy()` çağrı haritası (grep `.dummy()`), landing ilişkisi yoksa kapsam dışı notu
- D2: `/terms` rotası public_web'de mevcut mu
- D3: `category_image_templates` anon SELECT policy teyidi (SSR okuması için)
- D4: Outfit fontu layout'ta yüklü mü
- D5: App hedef URL'leri (`vixrex-app` origin + path) kesinleştirme
