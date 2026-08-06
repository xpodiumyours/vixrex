# VixRex — E2E Otomasyon Planı (Playwright)

Amaç: `docs/kabul-senaryosu.md`'deki 8 adımın **makineyle yürünebilen
kısmını** her seferinde otomatik yürütmek. Böylece Casper'ın gözü yalnız
gerçekten göz gerektiren işe (D2 — arayüzün ince işçiliği) kalır.

## Kural — neyi otomatikleştiriyoruz, neyi değil

| Kabul adımı | Otomatik? | Neden |
|---|---|---|
| 1. Karşılaşma (vitrin açılışı) | ✅ Playwright | Next.js, gerçek DOM |
| 2. Karar ve giriş | ✅ Playwright | `/v/:slug` üzerindeki davet bandı |
| 3. Kurulum sohbeti | ❌ elle | Flutter; web'de tuval, seçici yok |
| 4. İlk vitrin | ✅ Playwright | Sunucu render, doğrulanabilir |
| 5. Kişiselleştirme | ✅ Playwright | Sahip paneli tamamen DOM |
| 6. Yayınlama | ✅ Playwright | Yayınla/vazgeç uçları |
| 7. Geri dönüş / canlı senkron | ⚠️ yarısı | Tarayıcı→tarayıcı otomatik; Flutter tarafı elle |
| 8. Kiralama | ❌ | Ödeme yok |

**Flutter tarafı Playwright'a sokulmaz.** Flutter web tuvale çiziyor;
seçici yazmak kırılgan, bakımı pahalı. Flutter tarafının bekçisi zaten
`flutter test` + sözleşme testleri.

## Nerede koşar

**Yalnız yerel Supabase** (`127.0.0.1:54321`). Testler veri yaratıp
siliyor; buluta asla bağlanmaz. Bu sert kural: bağlantı adresi
`127.0.0.1` değilse test kendini durdurur.

## Kurulum

```
public_web/
  playwright.config.ts
  e2e/
    fixtures/
      tohum.ts          # servis anahtarıyla mağaza + sahip oturumu yaratır
      test-tabani.ts    # her testin başında temiz mağaza veren fixture
    01-vitrin-acilis.spec.ts
    02-davet-bandi.spec.ts
    03-sahip-oturumu.spec.ts
    04-tikla-duzenle.spec.ts
    05-gorsel-ve-sablon.spec.ts
    06-yayinla-vazgec.spec.ts
    07-canli-senkron.spec.ts
    08-erisilebilirlik-ve-mobil.spec.ts
```

`package.json`: `"e2e": "playwright test"`, `"e2e:ui": "playwright test --ui"`.

`playwright.config.ts`:
- `webServer`: `next dev`, `reuseExistingServer: !process.env.CI`
- projeler: `chromium` (masaüstü) + `Mobile Chrome` (Pixel 7) — esnafın
  müşterisi telefondan geliyor, mobil ikinci sınıf değil
- `trace: "retain-on-failure"`, `screenshot: "only-on-failure"`

## Tohumlama (fixtures)

`tohum.ts` servis anahtarıyla doğrudan Supabase'e yazar:

1. `stores` satırı yarat — slug benzersiz (`e2e-<rastgele>`), yasal
   onaylar dolu (tetikleyici reddetmesin), `is_demo=false`
2. `create_owner_session` ile tek kullanımlık kod al
3. Testte `/v/:slug?kod=...` ile girilir → çerez kurulur
4. `afterEach`: yaratılan slug silinir

**Sabit bir "test mağazası" kullanılmaz.** Her test kendi mağazasını
yaratır; testler birbirinin verisini bozamaz, sıra bağımlılığı olmaz.

## Testler — ne doğruluyor

### 01 — Vitrin açılışı
- `/v/:slug` 200 döner, işletme adı `<h1>`'de
- Konsolda hata yok
- Koymadığı görsel yok: `img[src*="unsplash"]` **sıfır** (B1 nöbetçisi)
- LCP < 2.5 sn (yerelde ölçüm, eşik gevşek)

### 02 — Davet bandı
- Kiralama bandı görünür: `#kirala`, "499 TL", "14 gün"
- Sahip oturumu yokken **yalnız** demo vitrinlerde çıkar

### 03 — Sahip oturumu
- Geçerli kodla panel açılır, doluluk yüzdesi görünür
- **Aynı kod ikinci kez çalışmaz** (tek kullanımlık)
- Kod olmadan `/api/owner-draft` 401

### 04 — Tıkla-düzenle
- Şemadaki **her** düzenlenebilir alan için:
  `[data-vixrex-editable="<anahtar>"]` DOM'da var mı
- Bir alana tıkla → panel o alanı seçer, etiket doğru
- Yeni değer yaz → sayfada görünür, **yayınlanmamış** (ikinci bir
  tarayıcıda eski hâl duruyor)
- Yasak alan denemesi 400 döner

### 05 — Görsel ve hazır şablon
- Görsel alanına tıkla → hazır kütüphane **aynı sayfada** açılır,
  yeni sekme/yönlendirme yok (C1 nöbetçisi)
- Kütüphane vitrinin kategorisine ait görselleri getirir
- Dosya yükle → taslakta adres güncellenir

### 06 — Yayınla / vazgeç
- Yayınla → ziyaretçi (çerezsiz ikinci bağlam) yeni hâli görür
- Vazgeç → taslak silinir, yayın hâli değişmez
- Yasal onay eksikse yayın reddedilir, mesaj anlaşılır

### 07 — Canlı senkron
- İki tarayıcı bağlamı: A sahip, B ziyaretçi
- A yayınlar → B **yenilenmeden** yeni hâli gösterir (5 sn içinde)
- Bu testin ön koşulu: `stores` tablosu `supabase_realtime`
  yayınında. Değilse test **atlanır ve sebebini yazar** — sessizce
  yeşil olmaz.

### 08 — Erişilebilirlik ve mobil
- `@axe-core/playwright`: kritik ihlal sıfır
- Pixel 7 boyutunda yatay kaydırma yok (`scrollWidth <= clientWidth`)
- Dokunma hedefleri ≥ 44px
- Bu test **D2'nin ölçülebilir kısmıdır.** Geri kalanı hâlâ göz işi.

## Ne yapmaz

- Ödeme, PayTR, premium (yok)
- Flutter ekranları
- Gerçek e-posta / SMS
- Görsel karşılaştırma (screenshot diff) — **ilk turda hayır.**
  Tasarım hâlâ oturuyor; her küçük değişiklikte kırmızı yanan bir
  test kimseye yardım etmez. Tasarım dondurulunca eklenir.

## Kabul ölçütü

`npm run e2e` yerelde baştan sona yeşil. Bir tek test bile
`test.skip` ile susturulmamış olacak (07'nin realtime kontrolü hariç —
o kendi sebebini yazarak atlar).
