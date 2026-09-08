# VIXREX UYUM SÖZLEŞMESİ

Bu dizin Vixrex'in Flutter + Next.js + Supabase + Vercel yapısındaki davranış eşitliği ve yayın güvenliği için merkezi indekstir.

## Temel kural

Bu dosya **matrisin kendisi değildir**. İnsan tarafından okunabilen indeks ve kapsam haritasıdır.

Gerçek matris; `public_web/tests`, Flutter `test/`, Supabase migration/policy kontrolleri ve CI/yayın kapılarındaki **çalıştırılabilir doğrulamalardır**.

Bir satır yalnız bu belgede yazıyorsa doğrulanmış sayılmaz. İlgili otomatik test veya ölçüm yoksa durum `EKSİK` kalır.

## Kaynak önceliği

1. Flutter kaynak ekranı/bileşeni — ortak uygulama görünümü ve kullanıcı davranışı referansı.
2. `shared/` sözleşmeleri — ortak alan/niyet/veri sözleşmeleri.
3. Supabase migration/RLS/RPC — kalıcı veri, sahiplik ve yetki gerçeği.
4. Next.js public/SEO ve web uygulama karşılıkları.
5. Testler — yukarıdaki sözleşmelerin sapmasını engelleyen çalıştırılabilir kanıt.
6. Vercel Preview/Production ve CI — yayın kapısı.

## Durum işaretleri

- `GÜÇLÜ`: merkezi kaynak ve birden fazla çalıştırılabilir koruma mevcut.
- `KISMİ`: kaynak/koruma var ancak bütün yüzeyler tek sözleşmede değil.
- `EKSİK`: merkezi ve çalıştırılabilir matris henüz yok.

## 17 matris

| # | Matris | Cevapladığı soru | Main'de doğrulanmış mevcut dayanak | Başlangıç durumu |
|---|---|---|---|---|
| 01 | İşlev | Flutter'daki işlevin gerekli web/ortak sistem karşılığı var mı? | `public_web/tests/landing-vitrin-akisi-equality.test.ts`; eşitlik/contract testleri mevcut | KISMİ |
| 02 | Ekran ve Menü | Ana ve alt ekranlar ile menü sırası/sahipliği sözleşmeye bağlı mı? | Flutter `lib/screens/home_shell_screen.dart`; shell/eşitlik testleri mevcut | KISMİ |
| 03 | UI Görünüm | Renk, tipografi, ikon, kart, alan, boşluk ve ölçüler kaynakla aynı mı? | Flutter `lib/theme/app_theme.dart`; UI parite testleri parçalı | KISMİ |
| 04 | UX Akış | Aynı kullanıcı işlemi iki yüzeyde aynı sonuca ve devamlılığa ulaşıyor mu? | `public_web/tests/landing-vitrin-akisi-equality.test.ts`; asistan devamlılık testleri | KISMİ |
| 05 | Responsive | Telefon/tablet/masaüstü kırılımları ve yerleşim davranışı sözleşmeli mi? | `public_web/tests/uyum-sozlesmesi-responsive.test.ts` shell breakpoint/sidebar/alt-nav sözleşmesini Flutter kaynağına karşı kilitler; alt ekran responsive kapsamı henüz tamamlanmadı | KISMİ |
| 06 | Durum | Misafir, vitrinsiz, taslak, yayınlanmamış, yayınlı vb. durumların UI/işlem sonucu tanımlı mı? | Parçalı state/contract testleri var; bütün ürün durumu tek tabloda değil | KISMİ |
| 07 | 46 Alan | Her vitrin alanının anahtarı, tipi, doğrulaması, yeri ve kalıcı veri karşılığı kilitli mi? | `public_web/src/lib/vitrinFieldSchema.ts`; `shared/vitrin_alanlari.json`; `public_web/tests/vitrin-field-schema-render.test.ts`; alan erişilebilirliği testleri | GÜÇLÜ |
| 08 | Tek Veri / Senkronizasyon | Her veri için tek doğru kaynak nedir; cihaz/oturum değişince nasıl geri yüklenir? | `docs/tek-kaynak-gecis.md`; `public_web/tests/tek-kaynak-baseline.test.ts`; `public_web/tests/adres-tek-kaynak.test.ts`; Supabase `store_working_drafts`, `owner_flow_states`, `assistant_conversations/messages` | KISMİ |
| 09 | Doğrulama ve İş Kuralı | Hangi değer kabul edilir ve hangi koşulda işlem/yayın yapılabilir? | `public_web/tests/address-validator-parity.test.ts`; alan şeması doğrulamaları; Flutter/Next doğrulama kaynakları | KISMİ |
| 10 | Bağlantı / Servis | Flutter ve Next aynı iş için hangi RPC/API/veri yolunu kullanıyor? | Asistan handoff/core contract testleri ve tek-kaynak RPC'leri mevcut; merkezi servis haritası yok | KISMİ |
| 11 | Yetki ve Güvenlik | Kim hangi satırı/dosyayı/işlemi görebilir, değiştirebilir veya silebilir? | Supabase RLS/migration'ları; GRANT/secret/auth güvenlik contract testleri mevcut | KISMİ |
| 12 | Hata / Yükleniyor / Boş Durum | Ağ, yetki, 404, kayıt ve boş veri durumlarında kullanıcı ne görür ve nasıl devam eder? | Next `not-found.tsx` mevcut; merkezi çapraz-yüzey hata matrisi yok | EKSİK |
| 13 | Görsel ve Dosya | Görsel yükleme, sıkıştırma, format, boyut, storage yolu ve yetki kuralları aynı mı? | Görsel sıkıştırma testleri ve Storage kuralları parçalı | KISMİ |
| 14 | Erişilebilirlik | Klavye, focus, label, kontrast, hedef alanı ve büyütme sözleşmeli mi? | Tekil a11y kontrolleri var; merkezi çalıştırılabilir matris yok | EKSİK |
| 15 | SEO ve Public Vitrin | Index/canonical/metadata/OG/sitemap/robots/structured-data ve taslak görünürlüğü doğru mu? | Next public yüzeyleri, `opengraph-image.tsx`, blog SEO testleri mevcut; tam public-vitrin matrisi yok | KISMİ |
| 16 | Performans | Sayfa, API, DB, görsel ve JS maliyeti için ölçülebilir sınırlar var mı? | Parçalı build/görsel kontrolleri var; merkezi bütçe/ölçüm matrisi yok | EKSİK |
| 17 | Test ve Yayına Alma | Bir değişiklik hangi kanıtlar olmadan `main`e giremez? | `.github/workflows/ci.yml`, Preview/Production ayrımı ve çok sayıda contract testi var; 17 matrise bağlı merkezi merge kapısı yok | KISMİ |

## Öncelik sırası

İlk tamamlanacak matrisler, Flutter–Next ayrışmasını doğrudan kontrol edenlerdir:

`01 İşlev → 02 Ekran/Menü → 03 UI → 04 UX → 06 Durum → 08 Tek Veri`

Bunlardan sonra güvenlik ve yayın açısından kapı olanlar tamamlanır:

`09 Doğrulama → 10 Servis → 11 Yetki → 12 Hata → 13 Görsel → 14 Erişilebilirlik → 15 SEO → 16 Performans → 17 Test/Yayın`

`07 46 Alan` mevcut güçlü sözleşmenin referanslaştırılması ve eksik kenarların kapatılması olarak yürütülür.

## PR kuralı

Her PR açıklamasında veya otomatik kontrolde aşağıdaki bilgi üretilebilmelidir:

```text
Değişen dosyalar
↓
Etkilenen matris ID'leri
↓
Kaynak/oracle
↓
Çalıştırılabilir test/ölçüm
↓
Sonuç
↓
Preview gerekiyorsa doğrulama
↓
MAIN uygun / BLOCK
```

Bir PR'ın etkilediği matris için çalıştırılabilir kanıt yoksa `BLOCK` olmalıdır; yalnız doküman açıklaması PASS kanıtı değildir.

## Bu çalışma dalının hedefi

Bu başlangıç dalı ürün davranışını değiştirmez. Amaç:

1. 17 matrisi tek indeks altında sabitlemek.
2. Main'deki mevcut gerçek testleri ilgili matrislere bağlamak.
3. `EKSİK` ve `KISMİ` alanlar için yeni fail-closed contract testleri eklemek.
4. Son aşamada PR değişiklik yüzeyini ilgili matris testlerine bağlayan yayın kapısını oluşturmak.

Her matris tamamlandıkça bu indeks yalnız gerçek test/ölçüm kanıtına dayanarak güncellenecektir.
