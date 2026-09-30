# Faturadan dijital vitrin — faz durumu

Tarih: 30 Eylül 2026
Dal: `ccr-8ad6b7e9-suqdx6` (taban: `faturadankataloga` @ `9f0d8f51`). `main`'e alınmadı, canlıda değil.
Plan: [FATURADAN-VITRINE-MASTER-PLAN.md](FATURADAN-VITRINE-MASTER-PLAN.md)

Durumlar: başlamadı / sürüyor / **kod tamam** / gerçek akış doğrulandı. Hiçbir faz "gerçek akış doğrulandı" değildir; gerçek fatura, Preview veritabanı ve gerçek tüketici görünümü henüz denenmedi.

| Faz | Durum | Sürüm | Ne yapıldı | Kalan engel |
| --- | --- | --- | --- | --- |
| F0 | sürüyor | `9f0d8f51` | Tek dal üzerinde toplandı; hiçbir iş kaybolmadı | Güncel `main` (3 commit) henüz birleştirilmedi; `AGENTS.md` iki farklı sürümde, karar bekliyor |
| F1 | kod tamam | `28d5e22a` | Onay düğmesi kendi onayını beklemiyor; toplu onay stok onayını koşulsuz vermiyor; fatura kartı için tek doğrulanmış görsel yeterli | Gerçek ekranda görülmedi |
| F2 | kod tamam | `3dd1add4` | Belge türü/no/tarih, mal bedeli/KDV/indirim/ödenecek toplam ayrı; aynı alışveriş adayı ve esnaf teyidi | Okuyucunun yeni alanları gerçek faturada doğru okuyup okumadığı ölçülmedi |
| F3 | kod tamam (kısmi) | `24d3cf37`, `5da73242` | Hedefli kaynak araması, tam site haritası, erişim/süre durumu ayrı, firma kimliği doğrulaması (vergi no, adres, ad), marka kaynağında arama | Resmî PDF katalogdan ve sosyal hesaptan ürün OKUMA yok; yalnız bağlantılar toplanıyor |
| F4 | kod tamam | `049f9c36` | Görsel açılma/tür/boyut/boş/logo/banner kontrolü, kendi depoya alma, kaynağa geri bağ | En küçük kısa kenar (600 px) ölçülmeden seçildi; boş/logo tespiti sezgisel |
| F5 | kod tamam | `ef162427` | Satır sunucuda yeniden doğrulanır, satır-ürün kalıcı bağ, tekrarda aynı ürün, yarım kayıt geri alınır | Gerçek veritabanında denenmedi |
| F6 | kod tamam | `ed1a4263`, `1e16b9ce`, `7f497ca6` | Kapat-aç, otomatik kayıt, tek satır düzeltme, yayın sonrası tüketici sorgusu doğrulaması, önbellek yenileme, telefon için jeton ile aynı kapı | Telefon ekranı bağlandı (taslak kaydet + ayrı yayınla, web ile aynı sunucu kapısı; kategori olarak vitrinin ilk kategorisi kullanılır); Flutter derlenmedi, Dart testleri ve `dart format` çalıştırılmadı |
| F7 | kod tamam | `a7e84dc3` | Talep (ben / Vixrex), takip, tekrar talep engeli, yönetici cevap ucu, ret sonrası bağlı ürünlerin izlenebilir gizlenmesi | Yönetici ucu için `FIRMA_IZNI_YONETICI_ANAHTARI` ortam değişkeni gerekli; firmaya gerçek gönderim süreci yok |
| F8 | başlamadı | — | `tool/fatura_kabul.mjs` ölçüm aracı hazır | Gerçek fatura fotoğrafları, okuma anahtarı ve Preview ortamı gerekli |

## Uygulama sırası (veritabanı)

Kod, aşağıdaki dosyalar uygulanmadan fatura kaydını yazamaz. Sırayla uygulanır:

1. `20260929000000_fatura_islem_kaniti.sql` (etiketi atılmış; uygulanıp uygulanmadığı doğrulanmadı)
2. `20260930000000_fatura_yayin_kapisi.sql` (bu dalda görsel eşiği 1'e çekildi; henüz uygulanmadı)
3. `20260930100000_fatura_belge_kimligi.sql`
4. `20260930110000_fatura_satir_urun_baglantisi.sql`
5. `20260930120000_fatura_islem_geri_acma.sql`
6. `20260930130000_fatura_firma_izni.sql`

## Çalıştırılan kontroller

- Web: 264 dosya, 1996 test geçti; `tsc --noEmit` yalnız `xlsx` paketinin bu ortamda indirilememesinden kaynaklı 2 hata verir (değişikliklerden bağımsız).
- Flutter: hiç çalıştırılmadı (ortamda Flutter yok).
- Gerçek sağlayıcı, gerçek veritabanı, gerçek tarayıcı: çalıştırılmadı.
