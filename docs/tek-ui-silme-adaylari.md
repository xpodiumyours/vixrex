# Tek UI — silme adayları

> DURUM: SADECE ADAY LİSTESİ. Bu dosyada adı geçen hiçbir dosya bu aşamada silinmez.

## Kesin kural

Legacy Next.js uygulama yüzeyi ancak aşağıdaki kapıların TAMAMI geçildikten sonra kaldırılabilir:

1. Flutter Web `/app` tek uygulama kabuğu olarak çalışıyor.
2. APK mevcut Flutter ekranlarıyla çalışmaya devam ediyor.
3. `vixrex.com` üzerinde oturum açmış kalıcı kullanıcı Flutter Web'e geçtiğinde aynı hesabı devralıyor.
4. Kullanıcının mevcut vitrini, sahipliği ve düzenleme hakkı Flutter Web'de geri yükleniyor.
5. Oturumsuz/yeni kullanıcı akışı gerilemiyor.
6. Flutter Web'deki Vitrinim / Keşfet / Vixrex / Profil ve bunlara bağlı yönetim işleri eksiksiz çalışıyor.
7. Public/SEO Next.js yüzeyleri (`/`, public Keşfet/kategoriler, `/v/[slug]`, blog) çalışmaya devam ediyor.
8. Önizleme/canlı ortamda görsel ve davranış kontrolü tamamlanıyor.
9. Furkan uygulamayı görüp hedeflenen yapıyı açıkça onaylıyor.
10. Silinecek her dosya için son kullanım taraması yapılıyor; başka canlı yüzey tarafından kullanılan dosya silinmiyor.

Bu kapılardan biri bile eksikse silme yapılmaz.

## A — Güçlü silme adayları: legacy Next.js uygulama rotaları

Bunlar Flutter Web uygulama kabuğunun Next.js tarafındaki ikinci karşılıklarıdır. Şimdilik korunurlar.

- `public_web/src/app/app/layout.tsx`
- `public_web/src/app/app/page.tsx` — legacy Vitrinim / sahip yönetim ana yüzeyi
- `public_web/src/app/app/profil/page.tsx`
- `public_web/src/app/app/vixrex/page.tsx`
- `public_web/src/app/app/ayarlar/page.tsx`
- `public_web/src/app/app/bildirimler/page.tsx`
- `public_web/src/app/app/hesap/page.tsx`
- `public_web/src/app/app/urunler/page.tsx`

Not: Bir rotanın Flutter'daki karşılığı eksikse rota silinmez; eksik işlev önce Flutter'a tamamlanır.

## B — Güçlü silme adayları: Next.js uygulama kabuğu

Bu parçalar Flutter `HomeShellScreen` davranışını Next.js'te tekrar oluşturmak için var. Public Keşfet bağımlılıkları ayrılmadan silinmezler.

- `public_web/src/components/app/AppShellBoundary.tsx`
- `public_web/src/components/app/AppShellContext.tsx`
- `public_web/src/components/app/AppSidebar.tsx`

Silmeden önce yapılacak: public `KesfetIcerik` ve `StatusBar` bu kabuktan bağımsız çalışabilir hale gelmiş olmalı.

## C — İncelenecek adaylar: yalnız legacy uygulama kalırsa gereksizleşebilecek parçalar

Bunlar otomatik silme adayı DEĞİLDİR. Kullanım taraması ve Flutter karşılık kontrolü gerekir.

- `public_web/src/components/owner/VitrinimEditor.tsx`
- `public_web/src/components/owner/OwnerProductManager.tsx`
- `public_web/src/components/owner/OwnerDashboardMetrics.tsx`
- `public_web/src/components/owner/OwnerNotificationLink.tsx`

Kural: Bu dosyaların içindeki iş kuralları, veri işlemleri veya public vitrin bileşenleri silinmez. Gereken ortak mantık tutulur; yalnız gerçekten kullanılmayan UI katmanı son aşamada kaldırılır.

## D — Şimdilik KORU

- `public_web/src/components/app/AppEntryLink.tsx` — public web -> Flutter Web tek uygulama girişi.
- `public_web/src/app/api/app-handoff/route.ts` — güvenli hesap geçişi.
- `public_web/src/components/kesfet/KesfetIcerik.tsx` — public/SEO Keşfet için gerekli.
- `public_web/src/components/kesfet/StatusBar.tsx` — public Keşfet kullanımı bitmeden silinmez.
- `public_web/src/components/app/VitrinQrSheet.tsx` — `StatusBar` tarafından kullanılıyor; kullanım bitmeden silinmez.
- `public_web/src/app/v/[slug]/**` — public vitrin / SEO yüzeyi.
- blog, kategori ve diğer public Next.js sayfaları.
- Supabase API rotaları, veri modeli, RLS, ortak 46 alan şeması, doğrulamalar ve asistan/veri katmanı.
- Flutter uygulama ekranları ve servisleri.

## E — Testler: silme değil, son aşamada yeniden sınıflandırma

Legacy Next.js UI kaldırıldığında aşağıdaki testlerin bazıları eski çift-UI eşitliğini test ediyor olabilir. Plan tamamlanmadan silinmezler. Son aşamada her biri ya yeni tek-UI kuralına çevrilir ya da gerçekten karşılığı kalmadıysa kaldırılır.

- `public_web/tests/f5-shell-parite.test.ts`
- `public_web/tests/kesfet-esitlik-contract.test.ts`
- `public_web/tests/shared-vixrex-assistant-contract.test.ts`
- `public_web/tests/f2c-bos-form.test.ts`
- `public_web/tests/vitrin-field-schema-render.test.ts`
- `public_web/tests/f3-medya-urun-kuyruk.test.ts`
- `public_web/tests/owner-ui-contract.test.ts`
- `public_web/tests/notification-inbox-contract.test.ts`

Veri güvenliği, API, 46 alan, ürün, bildirim veya public vitrin davranışını koruyan testler yalnız eski UI'ya bağlı bir satır var diye komple silinmez; gerekli kontroller ayrıştırılır.

## Son silme yöntemi

Plan ve görsel onay tamamlandıktan sonra:

1. Her aday için repo genelinde kullanım taraması.
2. Kullanımı kalan aday = silme yok.
3. Kullanımı yalnız kaldırılacak legacy UI'da kalan aday = silmeye uygun.
4. Önce route/kabuk kaldırılır.
5. Ardından gerçekten sahipsiz kalan bileşen/import/test temizlenir.
6. Son kullanım taraması tekrar yapılır.
7. Build/test başarılı olmadan merge yapılmaz.

Amaç: legacy UI kaldırıldığında arkamızda ne çağrılan ölü kod ne de yanlışlıkla kesilmiş ortak işlev bırakmak.
