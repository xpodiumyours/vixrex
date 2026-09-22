# Faturadan Kataloğa — Durum Defteri

Çalışma dalı: `work/fatura-katalog-e2e-20260922`  
Kilitli hedef: `docs/fatura-katalog/KILITLI-HEDEF.md`  
Üretici standardı: `docs/fatura-katalog/URETICI-UYUMLULUK-STANDARDI.md`  
Önceki ayrıntılı teknik plan: `docs/fatura-katalog/TAMAMLAMA-PLANI.md`  
Başlangıç main SHA: `0034fe06942c4fdbe625f24bc338ef8cfa6e8a0b`

Bu dosya kullanıcıya çalışma dalında ne değiştiğini görünür tutar.

## Anlık durum

| Alan | Durum |
|---|---|
| Ana hedef | Faturadan güvenilir ve izinli dijital ürün kataloğu |
| Aktif teknik adım | Ortak kanıt/izin sözleşmesi + Vixrex uyumlu üretici standardı |
| Ana davranış | Güçlü iz → hazırla; kısmi iz → sor; zayıf iz → tahmin etme |
| İlk uçtan uca kanıt | Tek uyumlu üreticide gerçek fatura → dijital ürün → izin → taslak kart |
| Üretici havuzu | Ertelendi; çalışan kanıttan sonra |
| Main değişikliği | Yok |
| Canlı Supabase değişikliği | Yok |
| PR | Yok |
| Merge | Yok |
| Deploy / Preview | Yok |
| Dış AI gerçek fatura çağrısı | Yok |

## Hedef kilidi — 2026-09-22

Kullanıcıyla kilitlenen sıra:

1. Üretici uyumluluk standardını belirle.
2. Ürün/tedarikçi/izin için ortak kanıt sözleşmesini kur.
3. Tek bir uyumlu üreticide fatura → dijital ürün → izin → taslak ürün kartı zincirini gerçekten çalıştır.
4. Gerçek demo ortaya çıktıktan sonra üreticilere kurumsal izin modeliyle git.
5. İzin veren üreticileri daha sonra doğrulanmış üretici havuzuna al.
6. İlk hedef kitleyi bu üreticilerden mal alan küçük esnaflar oluşturur.

Test ve benchmark yalnız yanlış yola girmemek için kısa kabul kapısıdır; ana çalışma hattı değildir.

## Tamamlanan teknik parçalar

### Ölçüm motoru — destek aracı

Daha önce bağımsız ölçüm motoru kuruldu. Referans fatura 13 ürün / 75 adet / 6.034,00 TL doğru cevapla ölçülebiliyor. Bu araç korunur ancak çalışma test bataklığına çevrilmez.

### Kanıt ve üretici standardı — bu adım

**Neyi geliştirdik**  
Kilitli iş hedefini, Vixrex uyumlu üretici standardını ve makine tarafından okunabilir ortak kanıt/izin sözleşmesini tek yerde tanımladık.

**Neyi değiştirdik**  
Yalnız çalışma dalında dokümantasyon ve `shared/fatura_katalog_kanit_sozlesmesi.json` eklendi/güncellendi. Production OCR, Product CORE, veritabanı ve ekran davranışı değişmedi.

**Ne elde ettik**  
Bundan sonraki kodun tek kuralı sabitlendi: güçlü iz otomatik, kısmi iz soru, zayıf iz tahminsiz duruş. Üretici havuzu yerine önce bir üreticide uçtan uca kanıt hedefi kilitlendi.

**Neye dokunmadık**  
Main, canlı Supabase, Vercel production/preview, PR, mevcut vitrinler, ödeme, 46 alan ve asistan NLU.

**Kanıt / test durumu**  
JSON sözleşmesi yazılmadan önce parse doğrulamasından geçirildi. Bu adım production kodu değiştirmediği için Flutter/Next.js CI tetiklenmedi.

## Sıradaki tek teknik iş

Ortak sözleşmeyi gerçek koda taşımak:

- `InvoiceProductDraft` veri modelini oluşturmak,
- her kritik alan için kaynak + güven + kanıt bilgisini taşıyabilmek,
- `auto_prepare_draft / ask_missing / stop_no_guess` kararını tek yerde üretmek,
- mevcut Product CORE'a henüz yazmamak.

Bu adımda parser, UI, DB ve canlı sistem değiştirilmez. Önce doğru veri ve karar omurgası kurulur.

## Güvenlik / tetikleyici kontrolü

Bu branch için repo yapılandırmasına göre:
- GitHub CI yalnız PR ve `main` push'ında otomatik çalışır.
- Android APK workflow yalnız elle başlatılır.
- Vercel genel branch deployment kapalıdır; yalnız `main` ve özel `verify-*` branch'leri açıktır.

Bu nedenle bu çalışma dalındaki normal commit PR/CI/APK/Vercel preview tetiklemez. PR, merge, deploy ve canlı migration ayrı kullanıcı onayı gerektirir.
