# deepseek görevi — vitrin sayfası her ziyarette yeniden render ediliyor

Bu dosyanın tamamı tek seferde deepseek'e yapıştırılacak prompt'tur.
Aşağıdaki çizginin altındaki her şey kopyalanır.

---

Sen VixRex deposunda çalışıyorsun: `C:\Projects\vixrex`.

## 1. Sorun (ölçüldü, doğrulandı)

`public_web/src/app/v/[slug]/page.tsx` şu an:

```ts
export const revalidate = 60;
export const dynamic = "force-dynamic";
```

`force-dynamic` yüzünden **sayfanın tamamı her ziyarette sunucuda
yeniden render ediliyor** — statik/CDN'den anında dönen bir yanıt yok.
Sebebi kodda yazılı (satır 31-37): sayfa sahip oturumu çerezini
(`cookies()`) okuyor, Next.js "hem statik hem çereze göre değişsin"
isteğiyle çakışıp canlıda çöktüğü için tüm route dinamiğe alınmış.

Asıl veritabanı sorgusu (`_getStoreData`, satır ~247) ayrıca
`unstable_cache` ile 60 saniye önbelleklidir — o kısım zaten ucuz. Pahalı
olan, her istekte React'in sayfayı baştan kurması.

Proje **Next.js 16.2.11** kullanıyor — Cache Components (Partial
Prerendering) bu sürümde tam destekleniyor, `next.config.ts`'te henüz
açık değil.

## 2. En önemli kural — dokunma sınırı

**Sahip modu ile müşteri modu arasındaki sınır kutsaldır.** Sahibe özel
hiçbir işaret (`data-vixrex-editable`, düzenleme araçları,
`OwnerWorkspaceShell`) hiçbir koşulda önbelleklenmiş/statik bir yanıtın
içine sızıp **başka bir ziyaretçiye** gitmemeli. Bu VixRex'in en katı
kuralı (`VIXREX_RULES.md`, koruma sınırı 3). Emin olmadığın her an,
performanstan **ödün ver, güvenlikten verme.**

## 3. İki aşama — sırayla, birincisi bitmeden ikinciye geçme

### Aşama 1 — düşük risk, kesin yap

`_getStoreData`/`getStoreData` fonksiyonunu (satır ~247-257)
`unstable_cache`'ten Next.js 16'nın yeni `'use cache'` yönergesine taşı:

```ts
// önce (mevcut)
const getStoreData = (slug: string) =>
  unstable_cache(
    () => _getStoreData(slug),
    [`store-${slug}`],
    { tags: [`store-${slug}`, `products-${slug}`], revalidate: 60 }
  )();

// sonra
async function getStoreData(slug: string) {
  'use cache';
  cacheTag(`store-${slug}`, `products-${slug}`);
  cacheLife({ revalidate: 60 });
  return _getStoreData(slug);
}
```

`cacheTag`/`cacheLife`'ı `next/cache`'ten import et. **`cookies()` bu
fonksiyonun içinde asla çağrılmamalı** — zaten çağrılmıyor, öyle kalsın.

`public_web/src/app/api/revalidate/route.ts` şu an `revalidateTag`
kullanıyor — aynı tag isimleri korunduğu için değişmesine gerek
olmamalı, ama testini (varsa) çalıştırıp doğrula.

Bu aşama **route'u hâlâ `force-dynamic` bırakır** — henüz "her
ziyarette render" sorununu çözmez, ama eski/kaldırılan API'den
kurtulur ve ikinci aşamanın temelini atar. Aşama 1 bitince commit at,
testleri çalıştır, ondan sonra Aşama 2'ye geç.

### Aşama 2 — asıl kazanım, dikkatli yap

`next.config.ts`'e `cacheComponents: true` ekle.

Sonra `page.tsx`'te `export const dynamic = "force-dynamic"` satırını
kaldır. Bunu yapınca `cookies()` çağrısı (satır 329,
`StorePage` fonksiyonunun en üstünde) derleme/çalışma zamanı hatası
verecek çünkü artık statik/cache'li bir bağlamda çalışıyor — **bu
beklenen bir şey**, çözüm şu:

1. `StorePage` fonksiyonunun gövdesini ikiye ayır:
   - **Üst kısım:** `params` çöz, `getStoreData(slug)` çağır (Aşama
     1'den beri cache'li). Bu kısım cookie okumuyor, statik/cache'li
     kalabilir.
   - **Alt kısım:** `cookies()` okuyan, `isOwnerMode` hesaplayan,
     `VitrinProfileView` + (varsa) `OwnerWorkspaceShell`'i basan her
     şey — bunu **ayrı bir async bileşene** taşı (ör.
     `StorePageBody`), `store`/`data` bundle'ını prop olarak al.
2. `StorePage` içinde bu yeni bileşeni `<Suspense>` ile sar:
   ```tsx
   <Suspense fallback={<VitrinYuklemeIskeleti />}>
     <StorePageBody slug={params.slug} data={cachedData} />
   </Suspense>
   ```
   Yükleme iskeleti (fallback) basit tutulabilir — mevcut bir loading
   bileşeni varsa onu kullan, yoksa sade bir tane yaz.
3. `generateMetadata` fonksiyonu (satır ~281) zaten `cookies()`
   kullanıyorsa (kontrol et) onu da aynı mantıkla ele al — metadata
   statik kalabiliyorsa `ownerSession` kontrolünü oradan çıkar.

**Beklenen sonuç:** Veritabanı sorgusu + sayfanın çerezden bağımsız
iskeleti önbellekten/statik olarak anında döner; yalnız "sahip miyim"
kontrolü ve ona bağlı render her istekte taze çalışır (ki zaten ucuz —
sadece cookie okuma + prop'lardan render, ağ isteği yok).

**Bu aşamada bir şey netleşmiyorsa (ör. `generateMetadata`'nın
cookie'ye bağımlılığı, ya da Suspense sınırının nereye çekileceği emin
değilsen): zorlama, mevcut `force-dynamic` hâlini koru, raporda
"Aşama 2 yapılamadı, şu sebeple" yaz. Yarım/riskli bir sınır çekmek,
hiç çekmemekten kötüdür.**

## 4. Doğrula — bu görevde her zamankinden sıkı

Bu, sahip/müşteri ayrımının geçtiği en kritik dosya. Standart
`flutter analyze`/`test` bu görevde geçerli değil (bu tamamen
`public_web`, Next.js tarafı):

1. `npx tsc --noEmit` ve `npm run lint` temiz.
2. `npm run build` başarılı bitmeli — Cache Components hataları
   genelde build zamanında çıkar.
3. **Var olan Playwright E2E paketinin tamamı** (`npm run e2e`,
   `public_web` içinde) yeşil kalmalı — özellikle `03-sahip-oturumu`,
   `04-tikla-duzenle`, `06-yayinla-vazgec` senaryoları bu dosyayı
   doğrudan test ediyor.
4. **Ek manuel kontrol, testte yoksa bile yap:** iki ayrı tarayıcı
   bağlamıyla aynı `/v/:slug` adresini aç — biri sahip çerezli, biri
   çerezsiz. Çerezsiz bağlamda `view-source:` ile sayfa kaynağını aç,
   `data-vixrex-editable` veya sahibe özel hiçbir metin/işaret
   **olmamalı**. Bunu ekran görüntüsü veya HTML çıktısıyla kanıtla.

## 5. Kesin kurallar

1. Yalnız `public_web/src/app/v/[slug]/page.tsx` ve
   `public_web/next.config.ts` (gerekirse `generateMetadata` ile
   ilgili yan dosyalar). Flutter'a, `lib/`'e dokunma.
2. `VitrinProfileView.tsx`, `OwnerWorkspaceShell.tsx` içindeki mantığı
   değiştirme — yalnız onları çağıran üst yapıyı (page.tsx) düzenle.
3. `revalidateTag`/`cacheTag` isimlerini (`store-${slug}`,
   `products-${slug}`) değiştirme — `/api/revalidate` webhook'u bu
   isimlere bağlı.
4. Türkçe yaz, depo kuralına uy.

## 6. Dal

Yeni bir dal aç: `duzeltme/vitrin-cache-tazeleme` main'den (zaten
`C:\Projects\vixrex-cache-worktree` adında ayrı bir worktree hazırladım
bu dal için — orada çalışabilirsin, ya da kendi ortamında aynı isimle
yeni dal açabilirsin, ikisi de olur).

## 7. Nasıl rapor ver

Kanıtla, anlatma: `tsc`/`lint`/`build`/`e2e` çıktıları, manuel
sızıntı testinin kanıtı (madde 4.4), hangi aşamayı bitirdiğin,
Aşama 2'yi yapamadıysan neden. Uydurma yasak.
