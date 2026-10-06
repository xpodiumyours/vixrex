# Faturadan ürün kartı — katmanlı mimari, entegrasyon planı ve temizlik listesi

Tarih: 6 Ekim 2026

Durum: **Tasarım ve planlama belgesi.** Bu belge sistemin tamamlandığını değil, nasıl
kurulacağını anlatır. Hiçbir kod bu belgeyle değiştirilmedi.

Bağlı olduğu ürün hedefi ve faz listesi: **[Faturadan Vitrine Master Plan](FATURADAN-VITRINE-MASTER-PLAN.md)**
(F0–F8). Bu belge o planın **yerine geçmez**; master planın ürün/kabul tarafının altına
inen **teknik mimari eki**dir. Yeni bir plan veya paralel ürün akışı kurmaz.

Kapsam: küçük esnafın **tek fatura fotoğrafından** doğrulanmış, görselli, tüketiciye
gösterilebilir ürün kartına giden zincir. Kapsam sınırı bu belgede daraltılmaz.

---

## 1. Bugünkü durumun ölçülmüş özeti

Bu bölüm, depodaki gerçek dosyalardan okunmuştur. Canlı servis veya veritabanı
doğrulaması değildir.

### 1.1 Zaten var olan bileşenler (tekrar yazılmayacak)

| Katman | Dosya / tablo | Bugünkü işi |
| --- | --- | --- |
| Belge girişi | `public_web/src/app/api/fatura-oku/route.ts` | Tek uç. Çerez (web) veya `edit_token` (telefon) kimliği, 5 MB sınırı, gerçek dosya türü denetimi, vitrin/IP oran sınırı, retry. |
| Belge anlama | `public_web/src/lib/faturaGoru.ts` | OpenRouter üzerinden `openai/gpt-5.6-luna`, yapılandırılmış satır çıkarımı, `usage.cost`. |
| Belge gerçeği | `public_web/src/lib/faturaSatirAyikla.ts` | `belgeGercegiUyuyorMu`: satır toplamını belgenin kendi toplamıyla karşılaştırır. |
| Kimlik ve keşif | `faturaDijitalIz.ts`, `ureticiKatalog.ts`, `firmaArama.ts`, `faturaEslestir.ts` | Shopify/Woo/JSON-LD/sitemap (SSRF korumalı), 55 firmalık havuz + 16 katalog, Brave site araması, kod/barkod ile eşleştirme, dört sonuç. |
| Kanıt/işlem | `faturaIslemKaydi.ts` + `invoice_jobs`, `invoice_job_lines`, `invoice_line_evidence`, `invoice_line_candidates`, `invoice_image_rights` | Belge parmak izi, satır, alan kanıtı, aday kaynak, görsel izin durumu. |
| Kart kapısı | `faturaKartDurumu.ts`, `faturaTaslagi.ts` | Yayına hazırlık değerlendirmesi, taslak üretimi. |
| Yazma/yayın | `products/batch`, `fatura-yayinla`, `productCoreServer.ts`, `publish_invoice_product` RPC + `fatura_yayin_kilidi` tetiği | Taslak yazma, ayrı Yayınla, veritabanı son kapısı. |
| Yüzeyler | `InvoiceToProducts.tsx`, `OwnerProductManager.tsx`, Flutter `fatura_oku_servisi` / `fatura_yayinla_servisi`, `/v/:slug` | Esnaf akışı ve tüketici vitrini. |

Son ilgili commit: `9f0d8f51` ("urun karti calismalarini ve master plani kaydet");
öncesi `8ef16500` (#560).

### 1.2 Zayıf noktalar (bu belgenin çözdüğü iş)

- **Model çıktısı yapılandırılmış değil, metin içinden ayıklanıyor.** `faturaGoru.ts`
  JSON'u ilk `{` ile son `}` arasından çıkarıyor. Sağlayıcının şema garantili çıktısı
  (structured outputs) kullanılmıyor.
- **Görsel modele ham boyutta gidiyor.** 5 MB'a kadar kaynak doğrudan modele
  gönderiliyor; küçültme/sıkıştırma yok. Bu, görüntü token maliyetini yükseltir
  (`sharp` bağımlılığı zaten var).
- **Maliyet satır başına ölçülüp kaydedilmiyor.** `usage.cost` yakalanıyor ama
  `invoice_jobs`'a yazılmıyor; fatura başına gerçek maliyet kanıtı yok.
- **İçerik/halihazırda var olan tekrar okuma yok.** Aynı belge tekrar yüklenirse
  parmak iziyle iş kaydı yeniden açılır ama model çağrısının tekrarını engelleyen
  bir "okuma önbelleği" yok.
- **Kimlik doğrulaması düz metin edit_token** ile yapılıyor (`verifyStoreEditToken`);
  sahiplik zinciri sandığı kadar güçlü değil (mevcut sistem, değiştirilmesi ayrı karar).

---

## 2. Katmanlı mimari

Amaç: **her katmanın tek bir işi olsun, karar tek yerde verilsin.** Aynı kararın iki
kopyası (iki okuyucu, iki eşleştirme kuralı) bu depoda 2026-09-26'da bir kez zarar
verdi; mimari bunu yapısal olarak engeller.

```
┌─ L7  Yüzeyler ───────────────────────────────────────────────┐
│  Web (InvoiceToProducts)   Flutter (fatura_*_servisi)   /v/:slug  │
│  Karar vermez; L5 sonucunu gösterir, esnaf girdisini toplar.      │
└───────────────────────────▲───────────────┬───────────────────────┘
                            │               │ onay (fiyat/stok/kart/yayın)
┌─ L6  Yazma & Yayın ───────┴───────────────▼───────────────────────┐
│  /api/products/batch · /api/fatura-yayinla · productCoreServer     │
│  DB SON KAPISI: publish_invoice_product RPC + fatura_yayin_kilidi   │
└───────────────────────────▲───────────────────────────────────────┘
                            │ yayına hazır mı? (tek karar)
┌─ L5  Kart Kapısı ─────────┴───────────────────────────────────────┐
│  faturaKartDurumu.ts: kartDegerlendir / yayinEksikleri             │
│  Arayüz bu kararı yeniden yazmaz; sunucu ve DB aynı kaynağı okur.  │
└───────────────────────────▲───────────────────────────────────────┘
                            │ satır + kanıt + katalog
┌─ L4  Kanıt & İşlem Kaydı ─┴───────────────────────────────────────┐
│  faturaIslemKaydi.ts + invoice_* tabloları                        │
│  Her alan: değer, kaynak, kanıt gücü, doğrulama zamanı.           │
└───────────────────────────▲───────────────────────────────────────┘
                            │ kimlik + katalog adayı
┌─ L3  Kimlik & Keşif ──────┴───────────────────────────────────────┐
│  faturaEslestir.ts (orkestrasyon) → faturaDijitalIz (Shopify/Woo/  │
│  JSON-LD/sitemap) · ureticiKatalog (havuz+katalog) · firmaArama     │
│  4 sonuç: kanitli · eksik · celiski · iz-yok. Tahmin yok.          │
└───────────────────────────▲───────────────────────────────────────┘
                            │ yapılandırılmış satırlar
┌─ L2  Deterministik Doğrulama ┴────────────────────────────────────┐
│  faturaSatirAyikla.ts: belge gerçeği (adet/tutar mutabakatı), TR   │
│  sayı ayrıştırma. Model YOK. Uyuşmazsa akış durmaz, uyarı taşınır. │
└───────────────────────────▲───────────────────────────────────────┘
                            │ şemaya uygun JSON
┌─ L1  Belge Anlama (TEK BEYİN) ┴──────────────────────────────────┐
│  faturaGoru.ts — sağlayıcı adaptörü. Aşağıda §3.                   │
└───────────────────────────▲───────────────────────────────────────┘
                            │ normalize edilmiş görüntü
┌─ L0  Belge Girişi ────────┴───────────────────────────────────────┐
│  /api/fatura-oku: kimlik, boyut, gerçek tür, oran sınırı, parmak   │
│  izi, görüntü normalizasyonu (küçültme).                            │
└────────────────────────────────────────────────────────────────────┘

Yatay: shared/*.json tek kaynak + üreteç · CI kapıları · sır yönetimi · maliyet defteri
```

**Değişmez kural:** L1 tek okuyucudur. Telefon, web ve ileride başka bir yüzey aynı
uçtan ve aynı fonksiyondan geçer. İkinci bir "okuma beyni" veya ikinci bir "hangi ürün
bu" kararı hiçbir katmanda açılmaz.

---

## 3. OpenAI entegrasyon tasarımı (verimli ve maliyet kontrollü)

Sağlayıcı seçimi ve sıra: bugünkü kod OpenRouter üzerinden OpenAI modeli kullanıyor.
Amaç bunu **tek adaptör** arkasında tutmak; doğrudan OpenAI ile OpenRouter arasındaki
tercih bir **karar** olduğu için bu belgede ölçülecek bir seçenek olarak bırakılır,
kendiliğinden değiştirilmez.

### 3.1 Sağlayıcı adaptörü (L1 içi)

```
BelgeAnlama (arayüz)
  ├─ OpenRouterSaglayici   (bugünkü: OPENROUTER_API_KEY, openai/gpt-5.6-luna)
  └─ OpenAISaglayici       (seçenek: OPENAI_API_KEY, doğrudan OpenAI)
```
- İki adaptör **aynı** `GoruSonucu` tipini döndürür. Üst katmanlar hangi sağlayıcının
  kullanıldığını bilmez.
- Anahtar yoksa okuyucu 503 verir; akış "hazır değil" der, çökmez (bugünkü davranış korunur).
- **İkinci bir okuyucu yazılmaz.** 2026-09-26 dersi: web'de ayrı bir OpenAI zinciri
  denenmiş, anahtar olmadığı için hiç çalışmamıştı.

### 3.2 Yapılandırılmış çıktı (structured outputs)

- Model, `faturaGoru.ts` içindeki mevcut JSON şemasına **şema garantili** döner
  (OpenAI Responses/Chat Completions `response_format` json_schema, `strict: true`).
- Bugünkü "ilk `{` ile son `}` arasını al" ayrıştırması kaldırılır; şema ihlali
  sağlayıcı seviyesinde reddedilir.
- Şema, `shared/fatura_katalog_kanit_sozlesmesi.json` içindeki
  `invoice_product_draft_required_concepts` ile hizalanır (ham satır, tedarikçi kimliği,
  model/barkod, varyant, adet, alış fiyatı, kanıt…).

### 3.3 Görüntü token maliyetini düşürme

- L0'da `sharp` ile görüntü **modele gitmeden önce** küçültülür: uzun kenar sınırlı,
  JPEG kalitesi ölçülerek seçilir. 5 MB kaynak asla ham gitmez.
- Düşük `detail` ile yalnız geniş tablo okunacaksa; el yazısı/yoğun tablo satırında
  gerekirse yüksek `detail` — **ölçülerek**, tahminle değil.
- Kaynak dosyanın kendisi (kalite denetimi için) mevcut politika sınırlarıyla saklanır;
  modele giden görüntü ayrı bir "okuma kopyası"dır.

### 3.4 Maliyet ve gecikme kontrolleri

| Teknik | Ne zaman | Beklenen etki |
| --- | --- | --- |
| Prompt caching | Sabit talimat bloğu her çağrıda aynı | Girdi token'ı için indirimli kademe |
| Batch API | Toplu yeniden işleme (geçmiş faturalar) | Etkileşimli yolun dışında toplu indirim |
| Yeniden okuma önbelleği | Aynı belge parmak izi tekrar | Tekrar model çağrısı yok |
| Retry yalnız belge gerçeği tutmazsa | `belgeGercegiUyuyorMu` false | Bugünkü üst sınır 3 korunur |
| Model sabitleme | Model değişimi | Aynı gerçek faturayla yeniden ölçüm şartı |
| Maliyet defteri | Her okuma | `invoice_jobs`'a token + gerçek maliyet yazılır |

**Ölçüm kuralı:** Model, token, süre veya tasarruf yüzdesi **ölçülmeden** iddia edilmez.
Bugünkü `faturaGoru.ts` yorumundaki 2026-09-26 ölçümü (3 kez hatasız, ~7 kuruş) geçerli
bir geçmiş kanıttır ama **yeni entegrasyonun** kanıtı değildir; değişiklik sonrası tekrar
ölçülür.

### 3.5 Sınırlar (güvenlik ve dürüstlük)

- Model **kod/barkod uydurmaz**; kesin eşleşme L3'te katalog indeksinden yapılır.
- Alış fiyatı, fatura fotoğrafı, müşteri kimliği ve iç eşleştirme notları tüketici
  kartına sızmaz.
- **Gerçek ürün görseli yerine yapay görsel üretilmez.** Görsel üretimi yalnız ürün
  kanıtı olmayan dekoratif alanlar için ve açıkça işaretlenerek kullanılabilir; faturadan
  çıkan gerçek kartın kanıt görseli daima üreticinin resmî kaynağından gelir.

---

## 4. Esnafın uçtan uca akışı (yüzeyler arası)

1. **Fotoğraf** → L0 (`/api/fatura-oku`).
2. **Hazırlık** → L1 (model) → L2 (belge gerçeği) → L3 (firma/ürün/görsel keşfi).
   İşlem kaybolmaz; L4'e yazılır.
3. **Kartları gör** → L5 dört sonucu ve yayına hazırlığı gösterir. Kaynak ve eşleşme
   esnaf panelinde izlenebilir; tüketiciye teknik kanıt gösterilmez.
4. **Esnafa ait bilgiler** → yalnız satış fiyatı ve stok onayı. Ürün açıklaması, görsel
   arama ve firma araştırması esnafa geri yüklenmez.
5. **Taslak / Yayınla** → L6. İki ayrı eylem; düğmeler birbirini kilitlemez.
6. **İzin takibi** → kart hazır olduktan sonra, mevcut kartlar korunarak başlatılır.

Fatura hazırlama, firma izni ve yayın durumu **ayrı** anlam taşır. İzin sorulmadı diye
keşif/görsel/kalıcı kart/tüketici görünümü doğrulaması durmaz.

---

## 5. Entegrasyon planı — master plan F0–F8 eşlemesi

Yeni iş kalemi açılmaz; aşağısı master plandaki fazlara **teknik ayrıntı** ekler.

| Faz | Bu belgenin eklediği teknik iş | Bitiş kanıtı |
| --- | --- | --- |
| **F0** Uygulama tabanı | Taban dalı **uzaktan main**'den alınır (kural §9). Fatura commit'leri (`9f0d8f51` ve öncesi) tek envantere alınır; `.scratch` içindeki kaydedilmemiş iş taranır. | Tek sürüm envanteri; hangi commit'in hangi dosyayı taşıdığı listesi. |
| **F1** Onay/görsel/yayın kuralları | **Görsel sayısı çelişkisi** giderilir (§6.1): faturaya özel yayın tek doğru görselle çalışır; üç görsel kuralı diğer girişleri bağlar. | Tekil onayla, tek görselli satır gerçek karta dönüşür. |
| **F2** Belge ↔ alışveriş | Belge türü/numarası/tarih ile çoklu fotoğraf ilişkilendirme; parmak izi + kısa teyit. Mal bedeli/KDV/indirim ayrımı. | Işılay bilgi fişi + e-Arşiv aynı alımı 8 adet olarak temsil eder. |
| **F3** Havuz dışı keşif | `firmaArama` sağlayıcı kararı ve sonuç saklama koşulu netleşir; model/barkod hedefli arama, kısmi tarama devamı. | Havuz dışı ve çok markalı gerçek eşleşmeler. |
| **F4** Görseli karta taşıma | Seçilen görselin resmî öğeye bağı; kırık/logo/boş görsel reddi; gerçek görselin yönetilen medyaya alınması (süreli dış bağlantı kartı bozmaz). | Kaynakla bağlı, açılan doğru ürün görseli. |
| **F5** Kalıcı karta yazma | Sunucu, sahiplik/eşleşme/görsel/durumu satır ve işlem kimliğinden yeniden okur; tarayıcı "kanıtlı" etiketine güvenilmez. | Tekrarda çoğalmayan, kaynağına gidilebilen kart. |
| **F6** Taslak/geri açma/telefon | Flutter `fatura_yayinla_servisi` gerçek kimliklerle bağlanır; web ve telefon aynı sunucu doğrulamasını kullanır; önbellek yenilemesi. | İki cihazda aynı kart + gerçek tüketici görünümü. |
| **F7** İzin talebi | Mevcut `invoice_image_rights` + `fatura_kanit.ureticiGorsel` alanları üzerinden talep/cevap süreci; durumlar birbirine çevrilmez. | Kim sorumlu, gönderildi mi, cevap ne — izlenebilir. |
| **F8** Gerçek kabul | Kabul matrisi gerçek sağlayıcı + kalıcı kayıt + tüketici görünümü ile tamamlanır. | Firma bazında kanıt paketi. |

### 5.1 Güvenli geliştirme zinciri (her commit karta katkı sağlar)

Bu zincir, master plan §9'daki durum etiketleriyle birlikte uygulanır:
**başlamadı / sürüyor / kod tamam / gerçek akış doğrulandı.**

1. **Taban:** Yeni iş **uzaktan main**'den açılan tek çalışma dalında yapılır. Sipariş/
   tahsilat dalı (`freebuff/siparis-tahsilat-20260926`) fatura işinin tabanı **değildir**;
   kullanılmaz. Aynı klasörde iki ajan çalıştırılmaz.
2. **Dosya sahipliği:** Aynı anda aynı dosyaya yazan iki iş olmaz. Özellikle
   `faturaEslestir.ts`, `productCoreServer.ts`, `products/batch` üzerinde tek sahip.
3. **Dikey dilim (vertical slice):** Her commit, **çalışan zincirin bir halkasını**
   tamamlar — daima "fotoğraf → kart" yolunun bir adımını çalışır bırakır. Yalnız
   refaktör veya yalnız iskele commit'i karta katkı sağlamıyorsa bu dala girmez.
4. **Kapılar (gerçek çıktı yazılır):** `bash tool/merge-hazir.sh` — Next lint, `tsc --noEmit`,
   `vitest`, üretim derlemesi, Dart format/analyze/test, şema sapması, gitleaks.
   Tek dosya testi değil; sonuç sayısı raporlanır.
5. **Sözleşme testi:** `fatura-kabul-matrisi.test.ts` ve `rastgele-fatura-uctan-uca.test.ts`
   faturaya özel yayın koşulunu (tek doğru görsel dahil) kapsayacak şekilde genişletilir.
   Model/servis taklidi, gerçek sağlayıcı kanıtı sayılmaz.
6. **Veritabanı:** Migration önce **Preview** DB'ye `migration-uygula/` etiketiyle; canlıya
   ayrı kararla. RLS/GRANT değişikliği kırmızı sınıftır, kullanıcı onayı ister.
7. **Sır:** Anahtar `.env`'e gömülmez; ortam değişkeni adına değil değerin şekline güvenilir.
   `OPENROUTER_API_KEY` / `BRAVE_SEARCH_API_KEY` yokluğu "bozuk" değil "yapılandırılmadı"
   olarak raporlanır.
8. **Görsel kanıt:** Görünen her değişiklikte öncesi/sonrası ekran; gerçek panele
   girilemiyorsa bunu açıkça söyle, izole kopya çiz ve "gerçek ekran değil" diye belirt.
9. **Konum bildirimi:** Dal / ana dal / canlı ayrımı üç kelimeyle, test adresi ve geri
   alma komutu her teslimde yazılır.

---

## 6. Çakışan ve engelleyen unsurlar + temizlik listesi

Aşağıdaki maddeler **ölçülmüş** dosya/durumlardır. Hepsi "öneri"dir; hiçbiri bu belgeyle
uygulanmadı. Silme/dal işlemi kullanıcı onayı ister.

### 6.1 Çakışan unsurlar (hedefi doğrudan engelleyen)

| # | Nerede | Çelişki | Etki | Öneri |
| --- | --- | --- | --- | --- |
| A1 | `shared/product_image_policy.json` (`minImages: 3`) → `yayinEksikleri` + `publish_invoice_product` RPC (`jsonb_array_length(v_images) < 3`) | Master plan F1: faturada **tek doğru görsel** yeterli. Kod + DB **en az 3** istiyor. | Tek fotoğraflı gerçek fatura yayına çıkamaz; F1 kapanamaz. | Faturaya özel yayın kuralı (≥1 doğru görsel) web, telefon ve DB'de tek kaynaktan tanımlansın; diğer girişlerin 3 görsel kuralı değişmesin. |
| A2 | `shared/fatura_katalog_kanit_sozlesmesi.json` | `external_media_requires_rights_basis` (unknown/denied → görseli engelle) ve `first_proof: Tutku / manufacturer_pool_deferred: true` | AGENTS.md kilitli kapsamıyla çelişir: izin sonra istenir, Tutku yalnız örnektir, havuz kapsam sınırı değildir. | Sözleşme JSON'u kilitli kapsama hizalanır; `first_proof` alanı kapsam sınırı gibi okunmayacak şekilde düzeltilir. |
| A3 | `src/app/api/fatura-oku/route.ts` başlık yorumu | "vixrex-fatura-goru (Kilo, ücretsiz, anahtarsız) → ham metin → faturaSatirAyikla.ts" yazıyor; kod ise `faturayiOku` (OpenRouter `openai/gpt-5.6-luna`) çağırıyor. | Yeni geliştirici yanlış zinciri kopyalar; ikinci okuyucu riski. | Yanlış hâle gelmiş yorum düzeltilir (onayla). |
| A4 | `ureticiKatalog.ts` üst yorum: "İZİN KAPISI — fotoğraflar ancak izinDurumu 'var' olduğunda kullanılır" | `gorselKapisi()` artık görseli engellemiyor (kilitli kapsam). Yorum fiilen yanlış. | Okuyan, izni geri engel olarak koyabilir. | Yorum kilitli kapsama göre düzeltilir (onayla). |
| A5 | `invoice_image_rights` yorumu: "denied/unknown … tüketici kartına girmez" | Kod üretici görselini karta koyup yayınlıyor. | İki zıt kural aynı dosyada. | Yorum kilitli kapsama hizalanır (onayla). |
| A6 | Flutter `lib/services/ocr/*` (ocr_invoice_parser, ocr_product_matcher, ocr_fuzzy_matcher, ocr_template_detector…) | Master plan tek okuyucunun web `/api/fatura-oku` olduğunu söylüyor; Flutter'da yerel OCR/eşleştirme yığını duruyor. | İkinci "hangi ürün bu" kararı riski. | Hangi sınıfların gerçekten kullanıldığı ölçülür; kullanılmayan yerel eşleştirme yolu kayda geçirilir, sessizce ikinci beyin bırakılmaz. |
| A7 | Freebuff ortamı bu depoyu "Vite + React + Convex" varsayıyor | Depo Flutter + Next.js + Supabase. | Yanlış yığınla kod üretme riski. | Bu depoda Vite/Convex eklenmez; mevcut Next.js + Supabase korunur. |

### 6.2 Engelleyen / bozuk durumlar

| # | Nerede | Durum | Etki | Öneri |
| --- | --- | --- | --- | --- |
| B1 | Çalışma dalı `freebuff/siparis-tahsilat-20260926` | `origin/main`'e göre **22 ileri / 21 geri**; fatura işinin tabanı değil. | Fatura commit'i yanlış tabanda kalır; merge çakışması. | Fatura işi uzaktan main'den ayrı dala alınır; sipariş dalı karıştırılmaz. |
| B2 | `git status` | Yalnız `public_web/package-lock.json` değişik (kaydedilmemiş). | Ölçüm/CI farklı sonuç verebilir. | Sipariş işine ait; fatura dalına taşınmaz. |
| B3 | `.scratch/siparis-hat` (34 MB, kendi `.git`'i ile tam kopya) + `.scratch/vixrex-yedek-20260929` (patch + tar) | Gitignore'da; "bitmemiş iş burada beklemez" kuralını ihlal ediyor. | Kaydedilmemiş emek kaybolabilir; aynı klasörde ikinci `.git` karışıklık. | İçindeki `degisiklikler.patch` / `yeni-dosyalar.tar.gz` incelenir, sahipli işe taşınır, sonra `.scratch` temizlenir. |
| B4 | `test-sonuc/fatura-tamamlama-notu.md` (takip edilen dosya) | Kod "bu dalda, commitsiz" diyor; "harici arama ayrı iştir" gibi eski, hedefi daraltan notlar var; test sayıları yeniden koşulmadı. | Eski belge çelişki kaynağı oluyor (AGENTS §14). | Kanıt durumuna göre güncellenir veya arşive alınır; eski notlar kapsam kararı sayılmaz. |
| B5 | README, `VIXREX_RULES.md` ve `CONTEXT.md`'ye yönlendiriyor | **İki dosya da depoda yok.** Ayrıca `.github/scripts/verify_pr_scope.py` ve `verify_supabase_erisim_ratchet.py` de yok. | Yeni gelen yanlış yere bakar; "tek adres" kuralı sarsılır. | README'nin ölü atıfları gerçek kaynağa (AGENTS.md / master plan) çevrilir. |
| B6 | `control-map-system/protocol.md` | Base44 + `control-map-system` dalı + GitHub Issues merkezli **paralel yönetim omurgası**; AGENTS.md "tek adres" ve tek dal disipliniyle çakışır. Dal yerelde yok. | İki ayrı gerçek/iki sıra takibi. | Kanonik omurga kararı netleşir; kullanılmayacaksa arşive alınır. |
| B7 | Migration `20260929000000_fatura_islem_kaniti`, `20260930000000_fatura_yayin_kapisi` | Preview/canlı DB'ye uygulanıp uygulanmadığı belirsiz; kod bunlara bağlı. | Kod var, DB yoksa kart yazımı/yayını sessizce başarısız olur. | Önce Preview'a etiketle, canlıya ayrı kararla; uygulanma kanıtı kaydedilir. |
| B8 | `OPENROUTER_API_KEY`, `BRAVE_SEARCH_API_KEY` | Anahtarların canlıda tanımlı olduğu doğrulanmadı. | Okuyucu 503, firma araması sessizce kapalı. | `freebuff-env list` ile **ad** denetimi; eksikse kullanıcıdan istenir. Değer okunmaz/yazılmaz. |
| B9 | `.claude/settings.json` (3 bayt) + AGENTS.md notu | `/.claude/hooks/` kaldırılmış; kural metinleri kancasız. | Ölçülmeyen kural. | Kanca geri getirme kararı kullanıcıya ait; belge bunu "ölçülmüş" saymaz. |

### 6.3 Temizlik sırası (öneri)

1. **Önce kurtar, sonra sil:** `.scratch` içindeki iş `git`'e alınmadan hiçbir şey silinmez (B3).
2. **Tabanı sabitle:** Uzaktan main'den temiz fatura dalı; sipariş dalı ayrı kalır (B1, B2).
3. **Çelişkiyi tek kaynağa indir:** Görsel sayısı A1, sözleşme JSON A2 — tek kaynak + üreteç.
4. **Yanlış yorumları düzelt:** A3–A5 (yalnız ilgili yorum, onayla).
5. **Yerel ikinci beyni netleştir:** Flutter OCR yığını A6 — kullanılan/kullanılmayan ayrımı.
6. **Ölü atıfları düzelt:** README B5; paralel omurga kararı B6.
7. **Ölçüm ve DB kapıları:** B7, B8 doğrulanır; sonuç raporlanır.

---

## 7. Kapsam dışı ve kısıt

- Bu belge **yalnız tasarım ve plandır.** Kod, branch, migration, model çağrısı, push,
  deploy veya firmaya mesaj bu işin parçası değildir.
- Canlı servis, veritabanı ve dağıtım doğrulaması yapılmamıştır; "çalışıyor" iddiası yoktur.
- F0–F8 durumları master plan tablosundaki gibidir; bu belge onları ilerletmiş saymaz.
- Sıradaki uygulama işi, kullanıcı onayıyla ve §5.1 zinciriyle başlar.
