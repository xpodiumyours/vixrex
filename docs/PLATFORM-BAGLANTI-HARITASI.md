# Vixrex platform ve bağlantı navigasyonu (Tek Adres Canlı Harita)

> **Güncel bağlantı envanteri (`2026-11-20`), salt okunur tespit.** Temel kod tabanı: `63ad4287` (`63ad428710c81c044ff939a12c42500f4180ba21`). Bu belge canlı fatura işleminin, canlı OpenRouter/Gemini kotalarının veya Graphify indeksinin çalışma kanıtı değildir; yalnız kodda doğrulanan bağlantıları ve kuralları gösterir. Makinece okunabilir eşlikçi: [platform-baglanti-haritasi.json](platform-baglanti-haritasi.json).

---

## Ajan için ilk yönlendirme

1. Önce [Ajan Başlangıç Haritası](AJAN-BASLANGIC.md) ve [AGENTS.md](../AGENTS.md) kurallarını oku.
2. **Kod** için GitHub'daki hedef dalın commit'ini; **canlı** için Vercel üretim `deploy-info.json` kaydını; **veritabanı (DB)** için Supabase canlı ölçümünü; **preset** için OpenRouter canlı sürümünü ayrı ölç. Bunları aynı kabul etme.
3. Bu dosyadaki değişken **adları** yol göstericidir; **hiçbir anahtar değeri, jeton, müşteri faturası, VKN/TCKN, adres veya telefon buraya yazılmaz** (Kural 6).
4. Kod değiştirmeden önce Graphify `graph_stats` bilgisini hedef commit ile karşılaştır; indeks gerideyse `dosya:satır` kanıtı ile ilerle.
5. Yeni paralel harita/özet belgesi açma (Kural 36); değişiklikler yalnız bu tek adreste güncellenir.

---

## 10 Adımlı Uçtan Uca Platform Zinciri (Faturadan Vitrine)

```text
[1] Web / Mobil Giriş (/api/fatura-oku)
     │  En fazla 3 sayfa, toplam 4 MB; JPG/PNG/WebP/PDF gerçek dosya bayt kontrolü
     ▼
[2] Yetki, Kota ve Parmak İzi Kilidi
     │  Sahip çerezi/editToken + saatlik 30 istek kotası (fail-closed) + SHA-256 parmak izi
     ▼
[3A] BİRİNCİL HAT: Google Gemini Doğrudan Priz (gemini-3.8-flash)
     │  Tek çağrıda: Fatura okuma + Google Search + URL Context + (opsiyonel File Search)
     │
     ├── (Gemini anahtarı yoksa veya çağrı düşerse — FOTOGRAFTA_YAZI_YOK hariç) ──┐
     │                                                                             ▼
     │                                             [3B] OTOMATİK YEDEK HAT (Failover)
     │                                                  Supabase pg_net/pg_cron -> OpenRouter
     │                                                  1) qwen3.5-flash (okuma)
     │                                                  2) deepseek-v4.1-flash + firecrawl (kart)
     ▼                                             └─────────── /api/cron/fatura-provider ───┘
[4] Bağımsız Doğrulama ve Kural 32 Ticari Sır Temizliği
     │  VKN/IBAN/adres/iskonto kazınır; pazaryeri siteleri (Trendyol, N11 vb.) elenir
     ▼
[5] Supabase Veritabanı Kalıcı Kaydı
     │  invoice_jobs + invoice_job_lines + invoice_image_rights + ürün kimlik/beden eşlemesi
     ▼
[6] 4'lü Paralel Taslak Hazırlama + Görsel İşleme (sharp -> shelf-images)
     │  En fazla 4'er satır paralel işlenir; görseller sıkıştırılıp depoya alınır (ürün gizli taslaktır)
     ▼
[7] Esnaf Kontrol Masası (/api/fatura-islem ve yardımcıları)
     │  Esnaf satış fiyatı, stok, kategori ve kendi görsellerini onaylar
     ▼
[8] B2B Üretici İzin Köprüsü (/api/izin-talebi ve /izin-talebi/[token])
     │  Üretici/marka 64 haneli tek kullanımlık bağlantıyla görsel/veri izni verir (30 gün)
     ▼
[9] Yayın Kapısı (/api/fatura-yayinla -> SQL publish_invoice_product)
     │  İzin varsa vitrinde görünür (yayinda); izin yoksa kilitli bekler (hazir)
     ▼
[10] Canlı Vitrin ve Ürün Detayı Fail-Closed Telif Maskesi
      Tüketici vitrininde izinsiz görseller telif kalkanı arkasında gizlenir; sahip taslağını görür
```

### Adımların Teknik ve Sade Karşılıkları

| Adım | Ne olur? (Sade Türkçe) | Kod / Veritabanı Kanıtı (`dosya:satır`) |
|---|---|---|
| **1. Web / Mobil Giriş** | Esnaf web panelinden veya Flutter mobil uygulamadan en fazla 3 sayfa (toplam 4 MB) fatura fotoğrafı veya PDF gönderir. Dosya uzantısına değil, dosya başındaki gerçek baytlara bakılır. | `public_web/src/app/api/fatura-oku/route.ts:16-29, 70-73` |
| **2. Yetki, Kota ve Parmak İzi** | Mağaza sahibi çerezi (`verifyOwnerSession`) veya mobil düzenleme anahtarı (`verifyStoreEditToken`) doğrulanır. Saatlik 30 istek sınırı (`consume_assistant_request`) çalışmıyorsa sistem güvenlik gereği 503 ile durur (**fail-closed**). Aynı fatura yeniden yüklenirse SHA-256 parmak izi (`belgeParmakIzi`) mevcut sonucu döndürür, ikinci kez ücretli yapay zekâ çağrısı açılmaz. | `public_web/src/app/api/fatura-oku/route.ts:42-87` |
| **3A. Birincil Hat: Google Gemini** | Sistem önce doğrudan Google Gemini (`gemini-3.8-flash` veya `GEMINI_FATURA_MODEL`) hattını dener. Google'ın yerleşik `googleSearch` (resmî site arama), `urlContext` (ürün sayfası okuma) ve tanımlıysa `fileSearch` (`GEMINI_FILE_SEARCH_STORE_NAMES`) araçlarıyla fatura satırlarını ve resmî marka kartlarını tek çağrıda katı JSON şemasıyla (`GOOGLE_FATURA_URUN_KARTI_SEMASI`) üretir. | `public_web/src/lib/faturaArkaPlanIslemi.ts:42-108` · `public_web/src/lib/faturaPriz.ts:17-27, 258-310, 456-545` |
| **3B. Otomatik Yedek Hat (OpenRouter)** | Gemini anahtarı yoksa veya birincil çağrı hata verirse (fotoğrafta hiç yazı olmaması hariç) akış otomatik olarak Supabase kuyruk tablosuna devredilir (`enqueue_invoice_provider_job`). Supabase `pg_net` ile önce OpenRouter okuma preset'ine (`@preset/vixrex-qwen-fatura-okuma-suzme` → `qwen/qwen3.5-flash-02-23`), yanıt gelince `pg_cron` + `/api/cron/fatura-provider` ve `advance_invoice_provider_job` üzerinden kart preset'ine (`@preset/urun-kart-olusturucu` veya `PRESET_AKIS=yeni` ile `@preset/vixrex-urun-karti-v2` → `deepseek/deepseek-v4.1-flash-1017` + `firecrawl`) geçer. | `public_web/src/lib/faturaArkaPlanIslemi.ts:109-126, 165-199` · `public_web/src/lib/faturaKartPreset.ts:15, 207` · `public_web/src/app/api/cron/fatura-provider/route.ts:13-43` · `supabase/migrations/20261105080000_fatura_v3_preset_akisi.sql:4-69` |
| **4. Doğrulama ve Kural 32 Temizliği** | Yapay zekâdan dönen tüm metin ve nesneler `kural32MetinTemizle` / `kural32NesneTemizle` filtresinden geçer; VKN/TCKN, IBAN, adres, fatura no, cari kodu ve özel iskonto gibi ticari sırlar kazınır. Trendyol, Hepsiburada, N11, Amazon vb. aracı/pazaryeri alan adları reddedilir (`PAZARYERI_VEYA_ARACI_ALANLAR`); yalnız resmî üretici/marka alan adı ve resmî CDN görselleri tutulur. | `public_web/src/lib/faturaPriz.ts:327-454` · `public_web/src/lib/faturaUrunHazirlama.ts:12-94, 195, 319-340` |
| **5. Supabase DB Kaydı** | Fatura işlemi (`invoice_jobs`), satırlar (`invoice_job_lines`) ve görsel hak kayıtları (`invoice_image_rights`) kaydedilir. Aynı ürünün farklı beden/varyantları `save_invoice_product` RPC'si içinde `size_text` ve `variant_name` katmanıyla doğru ürün kimliğine bağlanır. | `public_web/src/lib/faturaIslemKaydi.ts:125` · `public_web/src/lib/faturaArkaPlanIslemi.ts:87-108, 200-221` · `supabase/migrations/20261113224000_fatura_kimlik_beden_ek.sql:5-47` |
| **6. 4'lü Paralel Taslak + `sharp` + `shelf-images`** | Satırlar 4'er adetlik paralel gruplar halinde (`ESZAMANLI_TASLAK_SAYISI = 4`) ürün taslağına dönüştürülür. Kaynak görseller indirilip `sharp` ile doğrulanır/sıkıştırılır ve Supabase Storage `shelf-images` kovasına yüklenir. Tüm yeni kartlar vitrine kapalı taslak (`is_visible = false`) olarak açılır. | `public_web/src/lib/faturaOtomatikTaslakKaydi.ts:63, 143-180, 255` · `public_web/src/lib/faturaGorsel.ts:2, 136, 221-231` · `public_web/src/lib/gorselSikistir.ts:1` |
| **7. Esnaf Kontrol Masası** | Esnaf kendi panelinde taslakları görür, satış fiyatını/stoğunu düzenler, isterse kendi çektiği ürün fotoğrafını yükler ve bilgileri onaylar. | `public_web/src/app/api/fatura-islem/route.ts:22-100` · `public_web/src/app/api/fatura-okuyucu-durumu/route.ts:8-17` |
| **8. B2B Üretici İzin Köprüsü** | Esnaf üretici/markadan resmî görsel ve veri izni istemek için `/api/izin-talebi` üzerinden 64 haneli gizli token içeren 30 gün geçerli bir bağlantı üretir; üretici `/izin-talebi/[token]` sayfasından tek tıkla onay veya ret verir. | `public_web/src/app/api/izin-talebi/route.ts:26-160` · `public_web/src/app/izin-talebi/[token]/page.tsx` · `supabase/migrations/20261118190000_supplier_permission_requests.sql:1-250` |
| **9. Yayın Kapısı** | Esnaf "Yayınla" dediğinde `/api/fatura-yayinla` sunucuda ve SQL `publish_invoice_product` RPC'sinde fiyat, stok, onay, görsel kaynağı ve tedarikçi reddi kapılarını yeniden denetler. Görsel hakkı doğrulanmışsa (`verified_supplier_permission`, `verified_feed_terms` veya `merchant_owned_media`) ürün vitrine açılır (`yayinda`); izin henüz yoksa ürün **`hazir`** bekler (`is_visible = false`). | `public_web/src/app/api/fatura-yayinla/route.ts:28-160` · `supabase/migrations/20261107120000_fatura_gorsel_izni_yayin_kapisi.sql:1-134` |
| **10. Canlı Vitrin Fail-Closed Telif Maskesi** | Tüketici vitrini (`/v/[slug]`), ürün detay sayfası ve hızlı bakış penceresi, üretici görsel izni doğrulanmamış hiçbir ürünü tüketiciye açık görselle göstermez (`telif-kalkani` maskesi); yalnızca mağaza sahibi (`isOwner`) kendi taslak/hazır görsellerini görebilir. | `public_web/src/app/v/[slug]/page.tsx:296-330` · `public_web/src/app/v/[slug]/ProductCatalog.tsx:147-160` · `public_web/src/app/v/[slug]/urun/[productSlug]/page.tsx:209-298` · `public_web/src/components/ProductDetailExperienceBase.tsx:42-490` · `public_web/src/components/ProductQuickViewBase.tsx:103-535` |

---

## Otomatik Devam / Yedekleme (Fallback) ve 4 Tek Kırılma Noktası (SPOF)

### Otomatik Yedekleme (Sistem ne zaman kendi kendini kurtarır?)

| Düşen Halka | Otomatik Devralan Mekanizma | Kullanıcıya Yansıması ve Kanıt |
|---|---|---|
| **Google Gemini doğrudan priz** (ağ hatası, kota, zaman aşımı) | `faturaArkaPlanIslemi.ts:109-126` hatayı yakalar ve işi Supabase `enqueue_invoice_provider_job` → OpenRouter yedek kuyruğuna aktarır (`FOTOGRAFTA_YAZI_YOK` hariç). | İşlem iptal olmaz; esnaf aynı ekranda beklerken yedek hat sonucu üretir. |
| **OpenRouter ikinci aşama (`cards`) geçici hatası** | `TEKRAR_DENENEBILIR` (`faturaArkaPlanIslemi.ts:250`) ve `basarisizKartIsiniTekrarDene` (`fatura-oku/route.ts:85`) kayıtlı okuma cevabını harcamadan kart adımını yeniden çalıştırır. | Okuma ücreti tekrar yanmaz; yalnızca kart adımı tazelenir. |
| **Aynı faturanın mükerrer yüklenmesi** | `belgeParmakIzi` (`fatura-oku/route.ts:78-84`) aynı baytlardan üretilen önceki işlemi bulur ve mevcut sonucu döndürür. | İkinci yapay zekâ faturası kesilmez; önceki taslak kaldığı yerden açılır. |
| **Üretici görselinin indirilememesi** | `faturaOtomatikTaslakKaydi.ts:256-267` kartı `gorsel-yok` / `aktarim-bekliyor` olarak taslak tutar; tüm faturayı düşürmez. | Esnaf kendi fotoğrafını (`shelf-images`) yükleyerek ürünü yine yayınlayabilir. |

### 4 Tek Kırılma Noktası (SPOF — Düştüğünde Sistemin Güvenli Durduğu Yerler)

| Tek Kırılma Noktası | Neden tek kırılma noktasıdır? | Düştüğünde sistem ne yapar? (Fail-Closed) |
|---|---|---|
| **1. Supabase (`chfulefxczbgurtgavtp`)** | Kota sayacı (`consume_assistant_request`), iş/satır kayıtları, SQL yayın kapısı (`publish_invoice_product`) ve `shelf-images` görsel deposu tek merkez olarak Supabase'dedir. | Kota doğrulanamazsa `503` döner, dış AI çağrısı açılmaz (`fatura-oku/route.ts:60-68`). Veri yazılamazsa taslak oluşmaz. |
| **2. Vercel `vixrex-public` (Next.js Sunucu)** | API giriş noktaları, Gemini çağrısı, OpenRouter callback ucu (`/api/cron/fatura-provider`) ve vitrin SSR burada çalışır. | Yedek kuyruktaki işler bile son adımda Vercel callback/işlem ucu olmadan taslağa dönüşemez. |
| **3. Her İki AI Anahtarının Birden Eksik/Çalışmaz Olması** | Hem `GEMINI_API_KEY`/`GOOGLE_API_KEY` hem de `OPENROUTER_API_KEY`/`FATURA_PRIZ_API_KEY` yoksa veya kota dışındaysa yedeklenecek başka motor kalmaz. | `OKUYUCU_HAZIR_DEGIL` (`503`) ile güvenli durur (`faturaArkaPlanIslemi.ts:115`); uydurma veya boş ürün kartı üretmez. |
| **4. Üretici Görsel Telif İzni (`invoice_image_rights` / `supplier_permissions`)** | Resmî siteden alınan görsellerin tüketici vitrininde görünmesi üretici iznine (`verified_supplier_permission` vb.) bağlıdır. | İzin yoksa veya reddedilmişse ürün **`hazir`** bekler ya da tüketici ekranında `telif-kalkani` ile maskelenir; esnaf kendi fotoğrafını yüklemedikçe tüketiciye izinsiz görsel gösterilmez. |

---

## KIRMIZI BÖLGE vs. YEŞİL BÖLGE (Değişiklik Sınırı)

| Bölge | Kapsam | Kural |
|---|---|---|
| **KIRMIZI BÖLGE** *(Kilitli Çalışan Motor — Dokunulmayacaklar)* | • Fatura okuma & AI priz motoru (`faturaArkaPlanIslemi.ts`, `faturaPriz.ts`, `faturaUrunHazirlama.ts`, `faturaKartPreset.ts`)<br>• Kural 32 ticari sır temizliği (`kural32MetinTemizle` / `kural32NesneTemizle`) ve pazaryeri alan filtresi<br>• B2B izin token motoru (`/api/izin-talebi`, `/izin-talebi/[token]`, `20261118190000_supplier_permission_requests.sql`)<br>• Yayın ve telif kilidi (`faturaGorselHakDenetimi.ts`, `/api/fatura-yayinla`, `publish_invoice_product`, `telif-kalkani` maskeleme mantığı)<br>• Ürün kimlik/beden ve atomik kayıt RPC'leri (`20261113224000_fatura_kimlik_beden_ek.sql`) | Açık mimari sözleşme ve Casper onayı olmadan tek satır değiştirilmez; bu motorda hata düzeltilecekse tüm fatura/telif test paketi eksiksiz koşulur. |
| **YEŞİL BÖLGE** *(Ekran Tasarımı & Kurucu Marka Önceliği İçin Güvenli Yüzeyler)* | • Vitrin ve ana sayfa görsel yerleşimi, tipografi, kart düzeni ve mobil uyum (mevcut dosyalar içinde)<br>• Kurucu marka / öne çıkan vitrin sunum katmanı<br>• Esnaf kontrol masasının görsel okunabilirliği (API sözleşmesini ve onay kapısını bozmadan) | **Sınırlar:**<br>1) Paralel yeni sayfa/rota veya kopya harita açılmaz (Kural 36).<br>2) `telif-kalkani` ve `gorselIzinBekliyor` fail-closed kilidine asla dokunulmaz.<br>3) Altyapısı hazır olmayan sahte metrik/uyarı kutusu konulmaz ve ana iş akışının önüne barikat dikilmez (Kural 25-26). |

---

## Bağlı Platformlar, Güncel Migration'lar ve API Uçları

### Proje / Bağlantı Kanıtları

| İlişki | Kaynak / Kimlik | Yetki / Kritik Sınır |
|---|---|---|
| GitHub → Vercel `vixrex-public` | Proje kimliği `prj_dCMDIaefrTHg6ysiUDT7veiWI52h` (`public_web/`) | Canlı `vixrex.com` yayını buradandır; `deploy-info.json` ile ölçülür |
| GitHub → Vercel `vixrex-app` | Proje kimliği `prj_AfdnDnAcIwSCaJuBoCQh1TP1GvWR` (`lib/`) | Flutter kabuğu; test adresi olarak `vixrex-public` yerine verilmez (Kural 19) |
| Vercel `vixrex-public` → Google Gemini | `public_web/src/lib/faturaPriz.ts:21-27, 456-545` | Birincil fatura okuma + Google Search + URL Context (+ File Search) |
| Vercel `vixrex-public` → Supabase | `public_web/src/lib/supabaseAdmin.ts` | `SUPABASE_SERVICE_ROLE_KEY` yalnız sunucudadır; tarayıcıya verilmez |
| Vercel `vixrex-public` → Supabase RPC | `public_web/src/lib/faturaArkaPlanIslemi.ts:42-126, 169-175` | Yalnız yedek hatta `enqueue_invoice_provider_job` / `advance_invoice_provider_job` çağrılır; `OPENROUTER_API_KEY` loglanmaz |
| Supabase → OpenRouter (Yedek) | `20261023173000_fatura_kart_preset_uyumu.sql` + `20261105080000_fatura_v3_preset_akisi.sql` | `pg_net` HTTP POST; `@preset/vixrex-qwen-fatura-okuma-suzme`, `@preset/urun-kart-olusturucu`, `@preset/vixrex-urun-karti-v2` |
| Supabase → Vercel Callback (Yedek) | `public_web/src/app/api/cron/fatura-provider/route.ts:13-43` | `pg_cron` her dakika hazır işleri `https://vixrex.com/api/cron/fatura-provider` ucuna bildirir (`x-vixrex-callback` zaman sabitli karşılaştırma) |
| Ajan → Vercel / Supabase / Graphify | `.mcp.json` | MCP tanımı salt okunur bağlantı haritasıdır; aktif oturum kanıtı ayrı ölçülür |

### Fatura / İzin Hattının Son 4 Kritik Migration'ı

| Migration Dosyası | Ne iş yapar? (Sade Türkçe) |
|---|---|
| `supabase/migrations/20261105080000_fatura_v3_preset_akisi.sql` | OpenRouter yedek hattının kart aşamasında `mevcut` (`@preset/urun-kart-olusturucu`) ve `yeni` (`@preset/vixrex-urun-karti-v2`) preset akışlarını güvenli biçimde ayırır; aynı iş için çift ücretli çağrıyı engeller. |
| `supabase/migrations/20261107120000_fatura_gorsel_izni_yayin_kapisi.sql` | `publish_invoice_product` yayın kapısını sıkılaştırır: üretici reddetmişse engeller, görsel hakkı doğrulanmamışsa ürünü `is_visible=false` (`hazir`) tutar, yalnız izinli veya esnaf görselli kartı vitrine açar. |
| `supabase/migrations/20261113224000_fatura_kimlik_beden_ek.sql` | `save_invoice_product` içinde ürün kimliği (`md5`) hesaplanırken beden (`size_text`) ve varyant (`variant_name`) alanlarını ekler; farklı bedenlerin tek karta çakışmasını önler. |
| `supabase/migrations/20261118190000_supplier_permission_requests.sql` | `supplier_permission_requests` tablosunu ve `create_supplier_permission_request` / `get_supplier_permission_request` / `approve_supplier_permission_request` RPC'lerini kurar (B2B üretici izin köprüsü). |

### Fatura ve İzin Hattı API Uçları

- `/api/fatura-oku` (`public_web/src/app/api/fatura-oku/route.ts`) — Fatura görseli/PDF yükleme, kota, parmak izi ve birincil/yedek başlatma
- `/api/fatura-islem` (`public_web/src/app/api/fatura-islem/route.ts`) — İşlem durumu sorgulama, taslak raporu döndürme ve esnaf satır seçimlerini kaydetme
- `/api/fatura-okuyucu-durumu` (`public_web/src/app/api/fatura-okuyucu-durumu/route.ts`) — Priz anahtarı + `invoice_provider_ready` DB kontrolü (sır sızdırmaz)
- `/api/fatura-eslestirme` (`public_web/src/app/api/fatura-eslestirme/route.ts`) — Mevcut mağaza ürünüyle birleştirme/yeni kart ayırma kararı
- `/api/fatura-satir-duzelt` (`public_web/src/app/api/fatura-satir-duzelt/route.ts`) — Fatura satır düzeltme
- `/api/fatura-alisveris-teyit` (`public_web/src/app/api/fatura-alisveris-teyit/route.ts`) — Alışveriş/işlem teyit ucu
- `/api/fatura-yayinla` (`public_web/src/app/api/fatura-yayinla/route.ts`) — Fatura ürünlerini SQL yayın kapısından geçirip vitrine çıkarma veya `hazir` bekletme
- `/api/cron/fatura-provider` (`public_web/src/app/api/cron/fatura-provider/route.ts`) — Supabase `pg_net` / `pg_cron` yedek hat callback alıcısı
- `/api/izin-talebi` (`public_web/src/app/api/izin-talebi/route.ts`) ve sayfa `/izin-talebi/[token]` (`public_web/src/app/izin-talebi/[token]/page.tsx`) — Üretici görsel/veri izin bağlantısı oluşturma ve onaylama

---

## Ortam Değişkeni Envanteri (Yalnız ADLAR — Değer Asla Yazılmaz)

| Değişken Adı (değer YOK) | Nerede Kullanılır? | İşlev (Sade Türkçe) |
|---|---|---|
| `GEMINI_API_KEY` | `public_web/src/lib/faturaPriz.ts:26` (`vixrex-public` sunucu / `.env.local`) | Birincil Google Gemini fatura okuma ve kart oluşturma anahtarı |
| `GOOGLE_API_KEY` | `public_web/src/lib/faturaPriz.ts:26` | `GEMINI_API_KEY` tanımlı değilse kullanılan alternatif Google API anahtarı |
| `GEMINI_FATURA_MODEL` | `public_web/src/lib/faturaPriz.ts:18` | Kullanılacak Gemini model adı (boşsa varsayılan: `gemini-3.8-flash`) |
| `GEMINI_FILE_SEARCH_STORE_NAMES` | `public_web/src/lib/faturaPriz.ts:498` | Virgülle ayrılmış opsiyonel Google File Search katalog deposu adları |
| `FATURA_PRIZ_URL` | `public_web/src/lib/faturaPriz.ts:36, 63` | İstenirse özel priz adresi; `generativelanguage.googleapis.com` içeriyorsa Gemini aktif kalır |
| `FATURA_PRIZ_API_KEY` | `public_web/src/lib/faturaPriz.ts:30` | `OPENROUTER_API_KEY` yerine geçebilen özel yedek priz anahtarı |
| `OPENROUTER_FATURA_TIMEOUT_MS` | `public_web/src/lib/faturaPriz.ts:93` | AI priz isteği zaman aşımı (ms; `30000`–`900000`, varsayılan `240000`) |
| `PRESET_AKIS` | `public_web/src/lib/faturaKartPreset.ts:15` | Yedek kart preset seçimi: `"yeni"` (`vixrex-urun-karti-v2`) veya `"mevcut"` (`urun-kart-olusturucu`) |
| `OPENROUTER_API_KEY` | `vixrex-public` production / `public_web/.env.local` | Otomatik yedek hat OpenRouter çağrı anahtarı (sunucu sırrı) |
| `OPENROUTER_MANAGEMENT_API_KEY` | `tool/openrouter-preset.sh`, `tool/preset-karsilastir.py` | Yalnız yerel preset yönetim anahtarı; runtime yerine geçmez |
| `SUPABASE_SERVICE_ROLE_KEY` | `public_web/src/lib/supabaseAdmin.ts` | Ayrıcalıklı sunucu veritabanı anahtarı; tarayıcıya **asla** verilmez |
| `SUPABASE_URL` | Her iki Vercel projesi (`vixrex-public`, `vixrex-app`) | Supabase proje adresi |
| `SUPABASE_PUBLISHABLE_KEY` | Her iki Vercel projesi | Normal istemci erişimi (RLS kurallarına tabi) |
| `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY` | `vixrex-public` | Tarayıcıya açık eski uyumluluk değişkenleri (RLS gerekli) |

**Ortam ayrımı ve güvenlik notu:** Production'da bir değişken adının bulunması, önizleme (preview) dalında da bulunduğunu kanıtlamaz. Yerelde gerçek fatura/env değişkenleri yalnızca `public_web/.env.local` içinde tutulur; kök dizindeki test faturaları depoya girmemesi için `.olcum/yerel-test-faturalari/` altında izoledir ve `.gitignore` ile kilitlidir.

---

## Hangi Veriye Hangi Kaynaktan Bakılır?

| Soru | Yetkili Ölçüm | Sınır |
|---|---|---|
| Canlı hangi commit? | `https://vixrex-public.vercel.app/deploy-info.json` | PR önizlemesi üretim değildir |
| Hangi Vercel değişken **adları** tanımlı? | Vercel proje/env metadata (`decrypt=false`) | Değerin geçerliliğini tek başına kanıtlamaz |
| Supabase projesi ve migration'lar canlıda mı? | Supabase MCP / üretim RPC envanteri | Repodaki `.sql` dosyası canlıda uygulandığını tek başına kanıtlamaz |
| Fatura prizi hazır mı? | `GET /api/fatura-okuyucu-durumu` | Anahtar varlığı + `invoice_provider_ready` RPC sonucunu döner (`{ hazir }`) |
| OpenRouter canlı preset sürümü nedir? | OpenRouter hesabındaki canlı preset | `openrouter/*.json` dosyaları canlı sürüm kanıtı değildir |
| Graphify indeks commit'i güncel mi? | `graph_stats` | Dal/PR ve canlı çalışma davranışı buradan kanıtlanmaz |

**Güncellik sınırı:** Bu bağlantı kaydının güncel olduğu son kod tabanı `63ad4287` (`2026-11-20`) olarak doğrulanmıştır. Sonraki commit ve deploy'larda otomatik güncel sayılmaz; [Ajan Başlangıç Haritası](AJAN-BASLANGIC.md) ve kapı betiğiyle yeniden ölçülür.
