# deepseek görevi — Playwright E2E otomasyonu

Bu metnin tamamını deepseek'e ver.

---

Sen VixRex deposunda çalışıyorsun: `C:\Projects\vixrex`. Görevin
`public_web` (Next.js 16) için Playwright E2E otomasyonu kurmak.

**Önce oku, sonra yaz:**
- `docs/e2e-otomasyon-plani.md` — bu görevin tam tarifi
- `docs/kabul-senaryosu.md` — testlerin doğruladığı 8 adım
- `public_web/src/lib/vitrinFieldSchema.ts` — 44 alanlık tek şema
- `public_web/src/app/v/[slug]/OwnerAssistantPanel.tsx` — sahip paneli
- `public_web/src/app/api/owner-session/route.ts` ve
  `owner-draft` / `owner-publish` / `owner-discard` uçları

## Kesin kurallar

1. **Yalnız yerel Supabase.** Bağlantı `127.0.0.1:54321` değilse test
   başlamadan hata verip dursun. Buluta bağlanan tek satır kabul edilmez.
2. **Ürün kodunu değiştirme.** `src/` altına dokunma. Test için seçici
   gerekiyorsa önce mevcut `data-vixrex-editable` işaretlerini kullan;
   yetmiyorsa `data-testid` öner ama **ekleme** — listele, dur, sor.
3. **Türkçe yaz.** Dosya adları, değişkenler, test başlıkları, yorumlar
   Türkçe. Depo baştan sona böyle.
4. **Şemaya bak, elle liste yazma.** Alan listesi gerekiyorsa
   `VITRIN_FIELDS`'ten türet. Sabit dizi kopyalarsan iş reddedilir.
5. **`test.skip` yasak.** Tek istisna: 07'deki realtime kontrolü,
   `stores` tablosu `supabase_realtime` yayınında değilse sebebini
   yazarak atlayabilir.
6. **Rastgele bekleme yok.** `waitForTimeout` kullanma; `expect(...)
   .toBeVisible()` gibi otomatik bekleyen kontroller kullan. Tek istisna
   07'deki canlı senkron: orada da `expect.poll` ile 5 sn üst sınır.
7. **Her test kendi mağazasını yaratır ve siler.** Ortak sabit mağaza yok.

## Yapılacaklar sırası

**1. Kurulum**
- `npm i -D @playwright/test @axe-core/playwright` (public_web içinde)
- `npx playwright install chromium`
- `playwright.config.ts`: `webServer` = `npm run dev`,
  `reuseExistingServer: !process.env.CI`, projeler `chromium` +
  `Mobile Chrome (Pixel 7)`, `trace: "retain-on-failure"`
- `package.json`'a `"e2e"` ve `"e2e:ui"` betikleri
- `.gitignore`'a `playwright-report/`, `test-results/`

**2. Tohumlama** — `e2e/fixtures/tohum.ts`
- Servis anahtarıyla `stores` satırı yaratır: benzersiz slug
  `e2e-<rastgele>`, yasal onay alanları dolu, `is_demo=false`
- `create_owner_session` ile tek kullanımlık kod alır
- `e2e/fixtures/test-tabani.ts`: `test.extend` ile her teste temiz
  `{ slug, kod }` verir, sonunda satırı siler

**3. Sekiz test dosyası** — `docs/e2e-otomasyon-plani.md`'deki
"Testler — ne doğruluyor" bölümündeki maddelerin **hepsini** yaz.
Madde atlama.

**4. Doğrula**
- `npx supabase start` ile yerel DB ayakta olsun
- `npm run e2e` baştan sona yeşil olana kadar çalış
- `npx tsc --noEmit` ve `npm run lint` temiz kalsın

## Nasıl rapor ver

İş bitince **kanıtla**, anlatma:
- `npm run e2e` çıktısının son 20 satırı (kaç test, kaç geçti)
- `npx tsc --noEmit` çıktısı
- Eklediğin dosyaların listesi
- Yazamadığın veya eksik bıraktığın her madde — sebebiyle

**Uydurma yasak.** Çalıştırmadığın komutun çıktısını yazma, geçmediği
hâlde "geçti" deme. Bir madde yapılamıyorsa "yapılamadı, şu yüzden" de.
Yarım işi tam gibi göstermek, hiç yapmamaktan kötüdür.

## Takılırsan

- Sahip oturumu kurulmuyor: `consume_owner_session` fonksiyonunun
  yerel DB'de olduğunu doğrula (`supabase/migrations/` altında)
- Realtime testi hep başarısız: `stores` yayında mı bak —
  `select * from pg_publication_tables where pubname='supabase_realtime'`
- Ürün kodunda gerçek bir hata bulursan **düzeltme**: not al, raporda
  ayrı başlık altında bildir. Düzeltme kararı Casper'ın.
