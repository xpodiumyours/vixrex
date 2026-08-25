# VixRex — Eksik Envanteri Komisyon Raporu (2026-08-25)

> Dört paralel komisyonun (İçerik&SEO, Ürün&Rakip, Güven&Operasyon, Teknik Sağlık)
> bulgularının birleşik envanteri. Tüm bulgular kod/canlı site/issue üzerinden
> doğrulandı; tahmin içermez. **Bütçe kuralı:** para isteyen her şey
> "ÜCRETLİ — SONRAYA" listesine ayrılır (sahibin kararı: domain dahil paralı
> işler ertelendi).

## A. Birleşik Öncelik Sırası (0-TL işler)

| # | Bulgu | Komisyon | Kanıt | Önerilen aksiyon |
|---|---|---|---|---|
| 1 | **Platform ana sayfası yok** — kök `/` Flutter paneline 307 ile yönlendiriyor; keşfet/dizin sayfası yok. Google'ın gördüğü anasayfa boş kabuk; tüm vitrinler iç link kredisiz | İçerik&SEO, Ürün | `public_web/src/app/page.tsx:5-6`; canlı test | Statik Next.js ana sayfa + `/kesfet` public dizini (yayınlanan vitrinleri listeleyen, iç link veren) |
| 2 | **Sitemap demo/kiralık vitrinlerle dolu** — 9 vitrinin tamamı `kiralik-*`/`demo-*`, priority 0.8 ile | İçerik&SEO, Güven | canlı `/sitemap.xml` | Sitemap'te `is_demo` filtresi + demo rotalara `noindex` |
| 3 | **Yasal sayfalara hiçbir bağlantı yok** — ana sayfada ve vitrinlerde gizlilik/şartlar linki sıfır | Güven | canlı HTML taraması: 0 geçiş | Ana sayfa + vitrin altbilgisine 3 link: Gizlilik · Şartlar · İçeriği Bildir |
| 4 | **Veri sorumlusu kimliği üç sayfada üç farklı** — "Vixrex, Aksakal Ticaret"/vixrex.app@gmail.com vs Xpodiumyours@gmail.com vs "Xpodiumyours"/privacy@vixrex.app | Güven | canlı `/privacy` §1,§7; canlı `/legal/privacy`; `lib/config/legal_config.dart:24` | Tek resmi kanal seçilip tüm metin/mailto'lara eşitlenecek |
| 5 | **Şikâyet kanalı yalnız blog** — vitrin/ürün/görsel bildirilemiyor; 5651 yer sağlayıcı yükümlülüğü savunmasız | Güven (#248) | `report-abuse/route.ts:19-22` | Ucu `target_type` parametreli genişlet + vitrin altbilgisine "İçeriği Bildir" |
| 6 | **BTK yer sağlayıcılığı bildirimi iz yok** — cezası 100 bin–1 M TL; e-Devlet ile ÜCRETSİZ | Güven | repoda iz yok | yersaglayici.btk.gov.tr üzerinden bildirim (Casper'a yarım saat) + trafik logu bilinci |
| 7 | **Canlı Kullanım Şartları 3 paragraflık zayıf sürüm; repo'daki 9 bölümlük metin canlıda değil** ve `LEGAL_DOCUMENTS.sql` hâlâ `[ŞİRKET ÜNVANI]` placeholder'lı taslak; çerez beyanı GA gerçeğini yansıtmıyor | Güven | canlı `/legal/terms` `terms-2026-07-05` vs `LEGAL_DOCUMENTS.sql` `terms-2026-07-07-v1` | Placeholder'lar doldurulup v1 canlıya aktif sürüm olarak uygulanır (onay tetikleyicisi yeniden onay akışı başlatır) |
| 8 | **Değer kanıtı yok** — esnaf 299 TL'nin karşılığını göremiyor; kaynak %100 "direct", WhatsApp tıklaması yazılmıyor | Ürün (#327) | issue + `publicStoreSelect.ts` | `detectSource()` referrer sınıflandırma + tıklama RPC'si + panelde dürüst aylık özet |
| 9 | **Gerçek müşteri yorumları yok** — yalnız puan/sayı alanı; rakiplerin table-stakes'i | Ürün (#295) | issue; `publicStoreSelect.ts:15-16` | Vitrinde "Google'da bize puan ver" CTA (`google_business_link` hazır) + randevu sonrası yorum adımı |
| 10 | **Ürünsüz vitrin yayına çıkabiliyor** — iki katmanda da ürün kontrolü yok | Teknik, Ürün (#328, ready-for-human) | `vitrinReadiness.ts:27-29`; `20260821144809...sql:15-49` | Karar yazısı: kategoriye bağlı ürün zorunluluğu (yarım gün doküman + uygulama) |

## B. Yüksek Önemli (0-TL)

1. **SEO araştırma dokümanındaki 3 ücretsiz kod aksiyonu hiç yapılmamış:** fiyat regex'i kırık ("150-200 TL"→150200), `offers.seller` @id'siz, VideoObject yok (`urun/[productSlug]/page.tsx:244`, `page.tsx:246-249`). Kanıt: `docs/research/vixrex-google-urun-yerel-seo-2026-08-15.md` §1.
2. **Search Console rutini yok:** sitemap submit + yeni vitrinde dizine ekleme isteği — Casper'a 5 dk'lık rutin.
3. **GBP rozeti:** kod güvenli ama canlıda tek örnek yok + GBP telefonu ↔ vitrin telefonu eşleşmesi yapılmıyor (`VitrinProfileView.tsx:462-471`; PR #289 kendi notu).
4. **Müşteriye randevu hatırlatma yok:** sahibe push var, müşteriye yok. 0-TL köprü: .ics indirme + WhatsApp hatırlatma deeplink'i.
5. **E2E kapsam boşluğu:** plan 8 senaryo+tohum fixture isterken gerçeklikte 5 spec, fixtures yok, config canlı prod'a karşı koşuyor; sahip oturumu/yayınla-vazgeç/erişilebilirlik akışları otomatik değil (`playwright.config.ts`).
6. **Destek beklentisi belirsiz:** mailto sonrası yanıt süresi taahhüdü yok — SSS'ye tek satır SLA cümlesi.

## C. Orta / Düşük (0-TL)

- Çoklu dil: vitrin içeriği tek dilli; statik arayüz çift dil iskeleti önerisi (rakiplerde standart).
- Elle tema seçimi yok (tema yalnız kategoriden) — şemaya renk aksanı `secim` alanı.
- Vitrinde "son güncelleme" göstergesi yok (`updated_at` DB'de var, UI'da yok).
- DPA beyanı belgesiz ("her sağlayıcıyla DPA yürütülüyor") — self-serve DPA'lar ücretsiz imzalanıp kayda geçilmeli, aksi halde #292 tekrarı.
- Kapak görseli CSS `background-image` → LCP riski; `next/image fill priority`ye alınmalı (`VitrinProfileView.tsx:426`).
- `Supabase.instance.client` doğrudan kullanımı 48→**49**'a çıkmış (#230 güncellenmeli); canlı DB'de search_path sabitsiz DEFINER sorgusu çekilip #230'a eklenmeli.
- Kategori etiket uyuşmazlığı iddiası ESKİMİŞ: etiketler artık ortak JSON'dan (`shared/business_categories.json`) geliyor; kalan ~12 sunum farkı (sectionTitle/CTA) bilinçli mi karar bekliyor.
- Deneme kötüye kullanımı: mevcut IP limitleri yeterli; haftalık elle anomali bakışı yeter.

## D. Doğrulanan GÜÇLÜ yönler (dokunma!)

- Sitemap/robots/metadata/JSON-LD altyapısı çalışıyor; #229 ve #264 çözülmüş.
- Skip'li test yok; CI son 8 koşuda yeşil; migration disiplini (20260817+) örneklemde kusursuz.
- Instagram entegrasyonu gate'i doğru kapıda (`INSTAGRAM_SYNC_ENABLED=false`, Meta App Review bekliyor).
- Randevu akışı, WhatsApp takibi, OCR, QR paylaşımı rakip seviyesinin üzerinde.

## E. ÜCRETLİ — SONRAYA

Özel domain · SMS/e-posta otomatik hatırlatma servisi · AI çeviri · Google Business Profile API · NFC kart ortaklığı · ticket sistemi · OTP/SMS doğrulama · profesyonel hukuk incelemesi · Merchant Center feed işletimi.

> Not: Domain bağlandığında tek noktadan düzeltme hazır (`siteUrl.ts` tek kaynak).

## F. Önerilen uygulama sırası (0-TL, etki/maliyet)

1. Ana sayfa + `/kesfet` dizini (Bulgu 1) — organik görünürlüğün kilidi
2. Demo'lara noindex + sitemap filtresi (2)
3. Footer yasal linkleri + tek KVKK kanalı + şablon/vitrin şikâyet kanalı (3,4,5)
4. BTK bildirimi (6) — Casper'a yarım saat
5. Legal v1 canlıya (7)
6. Değer kanıtı ölçümü (8) + Google yorum CTA (9)
7. #328 ürün zorunluluğu karar+uygulama (10)
8. SEO dokümanındaki 3 kod düzeltmesi (B.1) + Search Console rutini (B.2)
