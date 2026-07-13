# Vixrex public vitrin mimarisi: sorunlar, kararlar ve temizleme planı

> Son güncelleme: 14 Temmuz 2026
> Durum: Uygulama aşamasında
> Kapsam: Flutter işletme uygulaması ile Next.js müşteri vitrini arasındaki route sahipliği
> Değişmez kural: Mobil kullanıcı Flutter uygulamasından dışarı atılmaz.

## 1. Amaç

Bu belge, demo döneminden kalan paralel vitrin yollarını kaldırmak ve public
vitrinin tek sahibini belirlemek için bağlayıcı çalışma planıdır. Yeni özellik
planı değildir. Bu çalışma tamamlanana kadar kapsam dışı UI, veri modeli veya
ürün özelliği eklenmez.

## 2. Bağlayıcı mimari kararı

### ADR-001 — Public web vitrininin tek sahibi Next.js'tir

| Ortam | Sahip | Beklenen davranış |
|---|---|---|
| Mobil uygulama | Flutter | Vitrin uygulama içinde `PublicVitrinScreen` ile açılır. |
| Flutter web editör | Flutter | Yönetim ve editör yüzeyidir; müşteri vitrini public Next.js URL'sinde açılır. |
| Web müşteri linki | Next.js `public_web` | `/v/:slug` ve bütün alt rotalar Next.js tarafından render edilir. |
| SEO | Next.js `public_web` | Metadata, canonical, schema, sitemap ve robots tek kaynaktan üretilir. |
| Veritabanı | Supabase | Her iki istemci aynı veriyi kullanabilir; public HTML sahipliği yine Next.js'tedir. |

Aktif geçici domainler:

- Flutter işletme uygulaması: `https://vixrex-app.vercel.app`
- Next.js public vitrin: `https://vixrex-public.vercel.app`

Gelecekte özel domain satın alındığında yalnızca bu origin değerleri değişir;
route sahipliği değişmez.

## 3. Net sorun tespiti

### P0 — Aynı route iki uygulamaya ait

- Flutter router `/v/:slug` yolunu `PublicVitrinScreen` ile açıyor.
- Kök `vercel.json`, `/v/:slug` isteğini `api/v/[slug].js` dosyasına rewrite ediyor.
- `api/v/[slug].js` SEO HTML'i üretip Flutter web'i başlatıyor.
- Next.js de aynı `/v/:slug` ve alt rotaları render ediyor.

Sonuç: Route'un sahibi path ile değil, isteğin geldiği host ile tesadüfen
belirleniyor.

### P1 — Next.js geçişi eklemeli yapılmış

Next.js public vitrin eklendiğinde aşağıdaki demo katmanları emekli edilmemiş:

- `api/v/[slug].js`
- `api/sitemap.js`
- `api/robots.js`
- Flutter web için public `/v/*` sunumu

Sonuç: Yeni ürün mimarisi eski demo mimarisinin yerine geçmemiş, yanına eklenmiş.

### P2 — Önizleme ve gerçek müşteri vitrini farklı

- Flutter içindeki “Vitrini Gör” ve Keşfet dokunuşu Flutter vitrini açıyor.
- Link kopyalama, QR ve WhatsApp paylaşımı `PUBLIC_SITE_URL` üzerinden Next.js
  vitrini gönderiyor.

Sonuç: İşletme sahibinin onayladığı görünüm ile müşterinin gördüğü görünüm aynı
değil.

### P3 — Mimari environment variable ve fallback'lara bırakılmış

- Flutter fallback'i satın alınmamış `https://vixrex.app` adresi.
- Next.js uygulama fallback'i eski `https://vixrex-two.vercel.app` adresi.
- Environment eksik olduğunda sistem hata vermek yerine yanlış domaine düşüyor.

Sonuç: Preview, local ve production aynı koddan farklı mimari davranış üretebilir.

### P4 — SEO ve cache iki kez uygulanıyor

- Eski API shell 30 dakika CDN cache kullanıyor.
- Next.js mağaza sayfası 60 saniye revalidation kullanıyor.
- İki sitemap, iki robots ve birden fazla metadata üretim noktası var.

Sonuç: Aynı mağaza için eski metadata, yeni içerik ve farklı canonical değerler
aynı anda görülebilir.

### P5 — Dokümantasyon çalışan kodu tarif etmiyor

README, Flutter projesindeki public isteklerin Next.js'e yönlendirildiğini
söylüyor; mevcut `vercel.json` ise bunları yerel API shell'e rewrite ediyor.

Sonuç: Geliştirici hedef mimariyi okuyor fakat canlı kalan eski yolu değiştiriyor.

## 4. Kök neden

Flutter ve Next.js'in birlikte bulunması hata değildir. Kök neden, public vitrin
URL'si, UI'ı, SEO'su ve cache'inin iki uygulamaya birden verilmesi ve Next.js
geçişi sırasında eski demo katmanlarının kaldırılmamasıdır.

## 5. Kapsam dışı ve korunacak davranışlar

- Mobil `PublicVitrinScreen` silinmeyecek.
- Mobil Keşfet → vitrin akışı dış tarayıcı açmayacak.
- Supabase tablo şeması ve mağaza verisi bu çalışma kapsamında değişmeyecek.
- Deneme projesi `Vitrinx-Pro` ve durmuş Supabase `vitrinx Pro` değiştirilmeyecek.
- Özel domain satın alma bu çalışmanın ön koşulu değildir.
- UI parite çalışması bu route temizliğinin içine karıştırılmayacak.

## 6. Uygulama planı ve tamamlanma kapıları

Bir madde ancak kod, otomatik test ve ilgili çalışma zamanı doğrulaması
tamamlandıktan sonra `[x]` yapılır.

### Faz A — Mimari sözleşme

- [x] Public web vitrininin tek sahibini Next.js olarak kaydet.
- [x] Mobil Flutter vitrinini korunacak yüzey olarak kaydet.
- [x] Aktif geçici app/public domainlerini kaydet.
- [x] Route sahipliğini otomatik test ile koruma altına al.

### Faz B — Vercel route temizliği

- [x] Flutter Vercel projesinde `/v/:path*` → public Next.js origin redirect.
- [x] Flutter Vercel projesinde `/sitemap.xml` → Next.js sitemap redirect.
- [x] Flutter Vercel projesinde `/robots.txt` → Next.js robots redirect.
- [x] `/v/*` için Flutter API rewrite'ını kaldır.
- [x] Redirect'in query string ve alt route'ları koruduğunu doğrula.

Redirect kullanılmasının nedeni: App hostu public içeriği kendi origin'i altında
göstermemeli; tarayıcı ve arama motoru canonical public hostu açıkça görmelidir.

### Faz C — Eski SEO katmanını emekli etme

- [x] `api/v/[slug].js` kaldır.
- [x] `api/sitemap.js` kaldır.
- [x] `api/robots.js` kaldır.
- [x] Repo taramasında bu handler'lara çalışan kod referansı kalmadığını doğrula.

### Faz D — Web ve native navigasyonu ayırma

- [x] Flutter web'deki “Vitrini Gör” public Next.js linkini açacak şekilde ayrıldı.
- [x] Flutter web Keşfet mağaza dokunuşu public Next.js linkini açacak şekilde ayrıldı.
- [x] Native kod yolu aynı aksiyonlarda Flutter `PublicVitrinScreen` içinde kalıyor.
- [x] Web açılışı başarısız olursa sessizce Flutter public rotasına düşmüyor.

### Faz E — Domain ve dokümantasyon temizliği

- [x] Kod fallback'larını aktif `vixrex-app.vercel.app` ve
  `vixrex-public.vercel.app` originleriyle eşitle.
- [x] README'yi aktif geçici domainler ve gelecekteki özel domainlerle ayır.
- [x] README ile `vercel.json` route tablosunun birebir aynı olduğunu doğrula.
- [x] Eski `vixrex-two.vercel.app` fallback'ini kaldır.

### Faz F — Doğrulama

- [x] Mimari route sözleşme testleri geçiyor.
- [x] `dart analyze` hatasız.
- [x] İlgili Flutter testleri geçiyor.
- [ ] Next.js lint ve production build geçiyor.
- [x] Next.js production build geçiyor.
- [x] Flutter web production build geçiyor.
- [ ] App host `/v/vixrex` public hosta redirect oluyor.
- [ ] Public host `/v/vixrex` Next.js HTML döndürüyor; Flutter bootstrap içermiyor.
- [ ] App host sitemap ve robots public hosta redirect oluyor.
- [ ] Mobil vitrin uygulama içinde kalıyor.

## 7. Plan sapması kontrolü

Her değişiklikten önce ve sonra şu sorular cevaplanır:

1. Bu değişiklik public route sahipliğini tekleştiriyor mu?
2. Mobil kullanıcıyı uygulama dışına çıkarıyor mu?
3. Yeni bir renderer, fallback veya SEO kaynağı ekliyor mu?
4. Dokümantasyon ve otomatik test aynı kararı doğruluyor mu?
5. Değişiklik bu belgedeki aktif fazın dışında mı?

Sorulardan 2, 3 veya 5 için riskli cevap varsa değişiklik durdurulur ve plan
güncellenmeden uygulanmaz.

## 8. Başarı tanımı

Çalışma yalnızca aşağıdaki durum birlikte sağlandığında tamamlanır:

- Web müşterisi için tek renderer Next.js.
- Flutter web app hostu public HTML üretmiyor.
- Mobil vitrin Flutter içinde çalışıyor.
- SEO, canonical, sitemap ve robots yalnızca Next.js'ten geliyor.
- Eski API shell dosyaları repoda yok.
- Yanlış environment fallback'i ikinci bir yol oluşturamıyor.
- README, testler, Vercel route'ları ve canlı davranış aynı mimariyi anlatıyor.

## 9. Değişiklik günlüğü

| Tarih | Aşama | Sonuç |
|---|---|---|
| 14 Temmuz 2026 | Teşhis | Çift route sahipliği ve yarım Next.js geçişi doğrulandı. |
| 14 Temmuz 2026 | Plan | Tek sahiplik kararı ve temizleme kapıları bu belgeye kaydedildi. |
| 14 Temmuz 2026 | Yerel uygulama | App redirect'leri eklendi, eski SEO handler'ları kaldırıldı, web/native navigasyonu ayrıldı. |
| 14 Temmuz 2026 | Yerel doğrulama | Dart analyze, hedefli Flutter testleri, Flutter web build ve Next.js build geçti. |
| 14 Temmuz 2026 | Vercel önizleme | App `/v/*`, sitemap ve robots 307 redirect verdi; alt yol ve query string korundu. Public yanıtın Next.js olduğu ve Flutter bootstrap içermediği doğrulandı. |

## 10. Bilinen doğrulama borçları

- `npm run lint`, bu çalışmada değişmeyen Instagram testleri, cookie consent ve
  mevcut TSX dosyalarındaki 28 hata nedeniyle kırık. Mimari diff yeni lint hatası
  eklemedi; bu borç ayrı bir kalite çalışmasında temizlenmeli.
- Tam `widget_test.dart` koşusunda mevcut Supabase mock eksikleri ve bilinmeyen
  tek-segment route'un slug kabul edilmesi nedeniyle üç test kırık. Bu çalışma
  sırasında görülen landing taşması kapsam dışı değişiklik geri alınarak giderildi.
- Canlı redirect ve mobil davranış kutuları deployment ve cihaz doğrulaması
  yapılmadan tamamlandı sayılmaz.
