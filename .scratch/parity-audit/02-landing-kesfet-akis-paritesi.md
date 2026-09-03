# Landing + Keşfet Akış Paritesi — Çalışma Spec'i (02)

> **Kapsam:** Landing + Keşfet'te kesişen 3 akış. Hero/konum adımı GAP-01..22 için bkz. `report.md` (29-08 denetimi) — bu dosya onu tekrarlamaz, üstüne eklenir.
> **Yön:** Flutter (`lib/`) referans, Next (`public_web/`) eşitlenecek taraf. Eşitlik her yerde hedef DEĞİL — karar tablosundaki "bilinçli fark"lar korunur.
> **Tarih:** 2026-09-03 · Dal: `feat/sayfa-esitleme`

## Faz 0 — TAMAMLANDI: çıkarıcı bug'ı

**Kırık:** `landing-esitlik-contract.test.ts` B yönü — çıkarıcı JS kodunu kullanıcı metni sandı:
`= ASISTAN_ADIMLARI.length; const aktif = bitti ? null : ASISTAN_ADIMLARI[adim]; const inputRef = useRef`

**Kök neden (2 katmanlı):**
1. `jsxIcerikMetinleri` deseni (`>([^<>{]+)<`) `LandingAsistanSohbeti.tsx:143-147` içinde `>=` nin `>`si ile `useRef<HTMLInputElement>` in `<`si arasını tek "metin" yakaladı.
2. `yorumsuz()` yalnız satır-başı `//` yorumları söküyordu; `// GAP-22: ...` satır-içi yorumu artığın içine karıştı.

**Düzeltme:** `public_web/tests/yardimcilar/landingMetinleriWeb.ts`
- `yorumsuz()`: satır-içi `//` de sökülür (`://` URL korunur).
- `kullaniciyaGorunurMu()`: `=` / `//` / `?.` içeren + `const|let|return|useRef|useState|useEffect|...` geçen aday elenir. (`;` elenemez — "Konum izni alınamadı; ..." gerçek metindir.)

**Kanıt:**
- `npx vitest run tests/landing-esitlik-contract.test.ts tests/kesfet-esitlik-contract.test.ts tests/landing-port-metin-contract.test.ts tests/landing-vitrin-akisi-equality.test.ts` → 4/4 dosya, 25/25 test yeşil
- + `landing-hesap-baglama-paritesi, landing-asistan-tek-kaynak, landing-niyet-panele-tasinir, kesfet-kirala-cta-contract, kesfet-kirala-inline-guvenlik, demo-kirala-cta-contract, f5-shell-parite` → 7/7 dosya, 40/40 test yeşil
- `npx eslint` (değişen dosya) temiz · `npx tsc --noEmit` temiz

## Akış envanteri (yan yana, kod kanıtlı)

### Akış 1 — "Hazır Vitrin Seç" (karşılama → Keşfet)

| | Flutter | Next |
|---|---|---|
| Karşılama butonları | `vixrex_onboarding_chat_screen.dart:382` `Hızlı Seçenekler` → `İşini seç` (`:432`) | `LandingAsistanSohbeti.tsx:501-521` `Hazır Vitrin Seç` / `Sıfırdan Oluştur`; `/kayit:105-119` aynı ikili + `Bakiniyorum` |
| Ara adım | YOK — buton direkt `ExploreScreen(onlyRentalTemplates:true)` (`app_router.dart:481-496` `pushReadyTemplatePicker`, başlık `Hazır Vitrin Seç` `explore_screen.dart:259`) | VAR — Faz C1 niyet sorusu `Ne iş yapıyorsun?` + `İşine uygun hazır vitrinleri Keşfet'ten göstereyim.` + `‹ Geri` (`LandingAsistanSohbeti.tsx:428`) → filtreli `/kesfet?kategori=` |
| Keşfet başlığı | `Vixrex'leri Keşfet` / kiralık modda `Hazır Vitrin Seç` | Aynı (`(site)/kesfet/page.tsx:60-65`) — bekçili (`kesfet-esitlik-contract`) |

**KARAR (2026-09-03, Casper): Flutter'a soru ekle → UYGULANDI (aynı gün).**

Nasıl (tek-kaynak, istisna dosyasında yazan yön):
- `shared/vixrex_mesajlar.json`: 6 yeni anahtar (`niyet_kategori_baslik/aciklama`, `niyet_geri_buton`, `niyet_anlat_buton`, `niyet_serbest_yertutucu`, `niyet_ack`) → `dart run tool/mesaj_semasi_uret.dart` → `lib/config/vixrex_mesajlar.g.dart` (+9 satır). Web JSON'u direkt okur (`vixrexMesajlari.ts`).
- Flutter: `VixRexOnboardingStep.templateNiyet` (profil `category` adımından ayrı — editöre yazmaz); `chooseReadyTemplate` soruyu açar, `selectTemplateCategory`/`submitTemplateFreeText` Keşfet'i açar, `cancelTemplateNiyet` sessizce karşılamaya döner; `ExploreScreen.initialCategory` + `AppRouter.pushReadyTemplatePicker(initialCategory:)` (bilinmeyen etiket sessizce yoksayılır — Web kuralıyla aynı). Serbest-metinden kategori çözümü best-effort (`templateKategoriCoz`, Türkçe I/İ duyarsız; bulanık eşleşme yok).
- Web: `LandingAsistanSohbeti.tsx` 4 literal + placeholder + 2 buton kataloğa bağlandı; köprü mantığı (`niyetSohbetiKaydet`, conditional buton, `NIYET_KATEGORI_SORUSU` adı) aynen duruyor — bekçiler kilitliyor. 4 C1 istisna kaydı silindi.
- Mikro-fark (bilinçli): Flutter'da "Anlat ve devam et" giriş kutusunun ÜSTÜNDE (paylaşılan composer altta sabit), Web'de ALTINDA. İşlev aynı.
- Kapılar: `dart format` (yeni kod; dosyadaki 3 ChatPill + 2 boş-satır HEAD-kiri aynen korundu — local SDK 3.12.2 vs repo formatı), `dart analyze` temiz, flutter yeni 11 test yeşil (niyet 9 + explore 2), web 9 dosya/73 test yeşil, `eslint` + `tsc` temiz, sayı kilidi 106→112.
- Dokunulmayan önceden-kırıklar (bu işten değil, kanıtlı): web `owner-ui-contract` (`giris/page.tsx` `aria-busy` eksik — dal ucu 002e8f3'ten), flutter tam-süit 15 fail = HEAD ile birebir aynı (stash'lı baz koşusu: 540+15 → değişikle 551+15, +11 yeni yeşil, 0 yeni kırık).

### Akış 2 — "Kirala" (kart → sahiplenme)

| | Flutter | Next |
|---|---|---|
| Kart butonları | `vitrin_store_card.dart:432-465` kiralık kartta `İncele` + `Kirala` yan yana; normal kartta `Vitrini İncele` (`:507`) | `VitrinKarti.tsx:210-220` `İncele` + `Kirala` — metinler bekçili (`kesfet-esitlik-contract:100-113`) |
| Kirala sonucu | `app_router.dart:409-475` `navigateToRentDemo`: hesaplıysa `rent_demo_for_account` (kalıcı, 1 yıllık token) → owner URL; misafirse uyarı + `/rent-demo` köprü (reCAPTCHA, sahipsiz klon, 14 gün) | Faz C3: `Kirala` Keşfet'ten ayrılmıyor — inline `useKesfetKirala` paneli (`VitrinKarti.tsx:68,290-292`); `/rent-demo/page.tsx` hâlâ duruyor |
| Fiyat vaadi | `Aylık 299 TL` + `14 gün ücretsiz dene` (bekçili) | Aynı (bekçili) |

**KARAR (2026-09-03, Casper): köprü yolu → UYGULANDI (aynı gün).**
`/rent-demo` kanonik kiralama yoludur (orada zaten var); Flutter'a ikinci
kiralama yazılmaz. Doğrulama: Flutter'da tek Kirala kapısı
(`ExploreScreen:527` → `navigateToRentDemo`), hesaplı yol bile backend
RPC'dir (`DemoRentalService` — UI importu yok), misafir köprüye taşınır,
giriş zorlanmaz. Kilitler: `test/kiralama_kopru_contract_test.dart` (6 test:
tek kapı, tek URL builder, ince servis, kanonik `rent_demo_canonical`) +
`public_web/tests/kirala-kopru-senkron-contract.test.ts` (4 test: köprü
sayfası + inline akış aynı 3 çapada — hesap API, yedek jeton, owner-session
zinciri). Web inline paneline dokunulmadı (C3 kararı saklı); iki tarifin
ayrışma riski ("KASITLI KOPYA" notu) artık testle kilitli.

### Akış 3 — "Vitrinini aç / Detaylı formu aç" (yayın bitişi)

| | Flutter | Next |
|---|---|---|
| Bitiş butonu | `vixrex_onboarding_chat_screen.dart:569` `Vitrinini aç` (`busy ? 'Vitrinin açılıyor…'`) | `LandingAsistanSohbeti.tsx:757-762` `Vitrinini aç` → `/v/<slug>?owner=true`; altında `Detaylı formu aç` → `?owner=true&tab=profile` (`:763-768`) |
| Hesap bağlama | Sahiplik panelinde ayrı yüzey (`app_router` misafir uyarısı `:470-468`) | Bitiş ekranında inline panel: `Vitrinini hesabına bağla` + `Google ile bağla` (`:738-756`) — Flutter landing'inde yok (istisnada: `landingEsitlikIstisnalariWeb.ts:250-283`) |
| Kayıtsız bitiş | — | `ASISTAN_BITIS.dugme` → `/kayit` (`:725-733`) |

**KARAR (2026-09-03, Casper): olağan kullanıcı sırası → UYGULANDI (aynı gün).**
Bitiş + hesap bağlama zaten iki tarafta da AYNI panelmiş (spec'teki "Flutter'da
yok" tespiti bayattı — metinler onboarding done adımındaymış, çıkarıcı kapsamı
dışında). Yapılan: 5 metin kataloğa (`hesap_bagla_baslik/aciklama/buton/
yukleniyor/hata`, kilit 112→117); Flutter düğmeye `baglaniyor` yükleniyor
etiketi eklendi (Web'deki "Google açılıyor…" karşılığı — Flutter'da yoktu);
Web 4 literal + hata-yedeği kataloğa bağlandı; 5 istisna kaydı silindi;
`landing-hesap-baglama-paritesi` + `hesap_baglama_test` anahtar-üzerinden
doğrulamaya çevrildi (niyet güçlendi).
- Bilinçli farklar (dokunulmadı): bitiş yönü platforma özel (Flutter →
native owner workspace, Web → `/v/:slug?owner=true`); "Detaylı formu aç"
Flutter'da HomeShell sekmesine, Web'de vitrin profil sekmesine gider;
Flutter hata metinleri nedene özel, Web yedekte genel. Yasal-onay link
etiketleri (`Aydınlatma Metni` vb.) ayrı yüzey — istisnada duruyor.
- Kapılar: analyze temiz, Dart ilgili 6 dosya 42/42, web parite 6 dosya 45/45,
tam süit 1005+1 (tek fail önceden-kırık `owner-ui-contract`), eslint+tsc temiz.

## Bilinçli farklar (dokunulmaz)

- Web Keşfet ek cümlesi `Beğendiğin hazır vitrini kirala...` — SEO ziyaretçisi için, bekçili (`kesfet-esitlik-contract:37-54`).
- Renk token ayrımı: landing `lp-* #147DFF` = Flutter; vitrin `--primary #38A0E4` ayrı kalır (`globals.css:16-21`).
- Konum izni yüzeyi: Web `navigator.geolocation`, Flutter `Geolocator` (formda) — aynı `konum_onaylandi` olayına gider.
- Vitrin render yalnız Next'te (`/v/:slug`); Flutter yalnız yönlendirir (`app_router.dart:94-118`).

## Sonraki adım önerisi

1. Yukarıdaki 3 KARAR'ı ver (her biri tek cümle: hangi taraf referans).
2. Karar başına küçük PR: kod + istisna listesi güncellemesi + bekçi yeşil.
3. Kapılar her PR'da: `npm run lint`, `npx tsc --noEmit`, `npm run test`, `dart analyze`, ilgili `flutter test`.
4. Canlı yan-yana foto: `.\dev.ps1` (`:5000` + `:3000`) ile aynı girdilerle — `report.md` durum-eşitleme tablosundaki reçeteyle (ad/iş/WhatsApp/il/ilçe/adres aynı, GPS kapalı).
