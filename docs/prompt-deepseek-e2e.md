# deepseek görevi — Playwright E2E otomasyonu

Bu dosyanın tamamı tek seferde deepseek'e yapıştırılacak prompt'tur.
Aşağıdaki çizginin altındaki her şey kopyalanır.

---

Sen VixRex deposunda çalışıyorsun: `C:\Projects\vixrex`.

VixRex, Türkiye'deki küçük esnaf için hazır dijital vitrin platformu.
İki parça var: `lib/` (Flutter — esnafın uygulaması) ve `public_web/`
(Next.js 16 — müşterinin gördüğü vitrin, `/v/:slug`). Veritabanı Supabase.

**Görevin:** `public_web` için Playwright E2E otomasyonu kurmak.
Kod yazmaya başlamadan önce aşağıdaki her şeyi oku.

## 1. Önce oku

- `docs/kabul-senaryosu.md` — testlerin doğruladığı 8 adımlık esnaf yolu
- `docs/e2e-otomasyon-plani.md` — bu görevin ayrıntılı tarifi
- `public_web/src/lib/vitrinFieldSchema.ts` — 44 alanlık **tek** şema
- `public_web/src/app/v/[slug]/OwnerAssistantPanel.tsx` — sahip paneli
- `public_web/src/app/api/owner-session/route.ts`
- `public_web/src/app/api/owner-draft/route.ts`
- `public_web/src/app/api/owner-publish/route.ts`
- `public_web/src/app/api/owner-discard/route.ts`

## 2. Kesin kurallar

1. **Yalnız yerel Supabase** (`127.0.0.1:54321`). Bağlantı adresi bu
   değilse test başlamadan hata verip dursun. Buluta bağlanan tek satır
   kabul edilmez.
2. **Ürün kodunu değiştirme.** `src/` ve `lib/` altına dokunma. Seçici
   gerekiyorsa önce mevcut `data-vixrex-editable` işaretlerini kullan;
   yetmiyorsa `data-testid` **ekleme** — listele ve raporda bildir.
3. **Türkçe yaz.** Dosya adları, değişkenler, test başlıkları, yorumlar
   Türkçe. Depo baştan sona böyle.
4. **Şemaya bak, elle liste yazma.** Alan listesi gerekiyorsa
   `VITRIN_FIELDS`'ten türet. Sabit dizi kopyalarsan iş reddedilir.
5. **`test.skip` yasak.** Tek istisna: 07'deki realtime kontrolü,
   `stores` tablosu `supabase_realtime` yayınında değilse **sebebini
   yazarak** atlayabilir. Sessizce yeşil olmaz.
6. **Rastgele bekleme yok.** `waitForTimeout` kullanma; `expect(...)
   .toBeVisible()` gibi otomatik bekleyen kontroller kullan. Tek istisna
   07: orada `expect.poll` ile 5 sn üst sınır.
7. **Her test kendi mağazasını yaratır ve siler.** Ortak sabit test
   mağazası yok — testler birbirinin verisini bozmasın, sıraya bağlı olmasın.

## 3. Kurulum

`public_web` içinde:
- `npm i -D @playwright/test @axe-core/playwright`
- `npx playwright install chromium`
- `playwright.config.ts`: `webServer` = `npm run dev`,
  `reuseExistingServer: !process.env.CI`, projeler `chromium` +
  `Mobile Chrome (Pixel 7)`, `trace: "retain-on-failure"`,
  `screenshot: "only-on-failure"`
- `package.json`: `"e2e": "playwright test"`, `"e2e:ui": "playwright test --ui"`
- `.gitignore`: `playwright-report/`, `test-results/`

Hedef dosya düzeni:

```
public_web/
  playwright.config.ts
  e2e/
    fixtures/
      tohum.ts
      test-tabani.ts
    01-vitrin-acilis.spec.ts
    02-davet-bandi.spec.ts
    03-sahip-oturumu.spec.ts
    04-tikla-duzenle.spec.ts
    05-gorsel-ve-sablon.spec.ts
    06-yayinla-vazgec.spec.ts
    07-canli-senkron.spec.ts
    08-erisilebilirlik-ve-mobil.spec.ts
```

## 4. Tohumlama — `e2e/fixtures/tohum.ts`

- Servis anahtarıyla doğrudan Supabase'e `stores` satırı yazar:
  benzersiz slug `e2e-<rastgele>`, yasal onay alanları dolu
  (tetikleyici reddetmesin), `is_demo=false`
- `create_owner_session` ile tek kullanımlık kod alır
- Testte `/v/:slug?kod=...` ile girilir → çerez kurulur
- `test-tabani.ts`: `test.extend` ile her teste temiz `{ slug, kod }`
  verir, test bitince satırı siler

## 5. Sekiz test — maddelerin hepsini yaz, atlama

**01 — Vitrin açılışı**
- `/v/:slug` 200 döner, işletme adı `<h1>` içinde
- Konsolda hata yok
- Esnafın koymadığı görsel yok: `img[src*="unsplash"]` sayısı **sıfır**
- LCP < 2.5 sn (yerelde, eşik gevşek)

**02 — Davet bandı**
- Kiralama bandı görünür: `#kirala`, "499 TL", "14 gün"
- Sahip oturumu yokken yalnız demo vitrinlerde çıkar

**03 — Sahip oturumu**
- Geçerli kodla panel açılır, doluluk yüzdesi görünür
- **Aynı kod ikinci kez çalışmaz** (tek kullanımlık)
- Kod olmadan `/api/owner-draft` 401 döner

**04 — Tıkla-düzenle**
- Şemadaki her düzenlenebilir alan için
  `[data-vixrex-editable="<anahtar>"]` DOM'da var mı
- Bir alana tıkla → panel o alanı seçer, etiket doğru
- Yeni değer yaz → sayfada görünür ama **yayınlanmamış**: çerezsiz
  ikinci tarayıcı bağlamında eski hâl duruyor
- Yasak alan denemesi 400 döner

**05 — Görsel ve hazır şablon**
- Görsel alanına tıkla → hazır kütüphane **aynı sayfada** açılır;
  yeni sekme veya yönlendirme yok
- Kütüphane vitrinin kategorisine ait görselleri getirir
- Dosya yükle → taslakta adres güncellenir

**06 — Yayınla / vazgeç**
- Yayınla → çerezsiz ikinci bağlam yeni hâli görür
- Vazgeç → taslak silinir, yayın hâli değişmez
- Yasal onay eksikse yayın reddedilir, mesaj anlaşılır

**07 — Canlı senkron**
- İki tarayıcı bağlamı: A sahip, B ziyaretçi
- A yayınlar → B **sayfa yenilemeden** 5 sn içinde yeni hâli gösterir
- Ön koşul: `stores` tablosu `supabase_realtime` yayınında.
  Değilse test sebebini yazarak atlanır.

**08 — Erişilebilirlik ve mobil**
- `@axe-core/playwright`: kritik ihlal sıfır
- Pixel 7 boyutunda yatay kaydırma yok (`scrollWidth <= clientWidth`)
- Dokunma hedefleri ≥ 44px

## 6. Kapsam dışı — yapma

- Flutter ekranları. Flutter web tuvale çiziyor; seçici yazmak kırılgan
  ve bakımı pahalı. Onun bekçisi `flutter test` olarak kalır.
- Ödeme, PayTR, premium — henüz yok.
- Gerçek e-posta / SMS.
- Görsel karşılaştırma (screenshot diff). Tasarım hâlâ oturuyor; her
  küçük değişiklikte kırmızı yanan test kimseye yardım etmez.

## 7. Doğrula

- `npx supabase start` — yerel veritabanı ayakta olsun
- `npm run e2e` baştan sona yeşil olana kadar çalış
- `npx tsc --noEmit` ve `npm run lint` temiz kalsın

## 8. Nasıl rapor ver

İş bitince **kanıtla**, anlatma:
- `npm run e2e` çıktısının son 20 satırı (kaç test, kaç geçti)
- `npx tsc --noEmit` çıktısı
- Eklediğin dosyaların listesi
- Yazamadığın veya eksik bıraktığın her madde — sebebiyle

**Uydurma yasak.** Çalıştırmadığın komutun çıktısını yazma; geçmediği
hâlde "geçti" deme. Bir madde yapılamıyorsa "yapılamadı, şu yüzden" de.
Yarım işi tam gibi göstermek, hiç yapmamaktan kötüdür.

## 9. Takılırsan

- Sahip oturumu kurulmuyor: `consume_owner_session` fonksiyonu yerel
  veritabanında var mı bak (`supabase/migrations/` altında)
- Realtime testi hep başarısız:
  `select * from pg_publication_tables where pubname='supabase_realtime'`
- Ürün kodunda gerçek bir hata bulursan **düzeltme**: not al, raporda
  ayrı başlık altında bildir. Düzeltme kararı Casper'ın.
