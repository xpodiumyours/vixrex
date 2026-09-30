# Faturadan Ürün Kartı — Tamamlama Teslim Notu (2026-09-30)

## Yapılan iş (kod, bu dalda, commitsiz)

Preview dalındaki 9 commit (`preview/faturadan-urun-karti-p1`: P1 ürün adı + ham satır,
P2 dinamik iz + 4 sonuç + çelişki, P3 kalıcı işlem, P4 taslak kart, P5 iki yüzey eşitleme)
çalışma ağacına alındı. Üzerine P5 kalanı + P6 + yeni testler yazıldı:

- **Ayrı Yayınla (P5 kalanı):** `InvoiceToProducts` artık iki ayrı eylem sunar —
  "taslak kaydet" (bilgi onayı, görünmez) ve "yayınla". Sonuç ekranında taslaklar
  için ayrı "taslakları yayınla" düğmesi var (`POST /api/fatura-yayinla`).
- **Sunucu kapısı:** `products/batch` fatura satırını önce taslak kurar, `fatura_kanit`
  (`kartDurumu`, `stokOnaylandi`) yazar; görünürlük yalnız `yayinIstegi=true` +
  bütün kapılar + `publish_invoice_product` başarısıyla olur. Fatura dışı
  (Excel/CSV/XML, tekil, kopya) davranış değişmedi.
- **Yeni uç:** `POST /api/fatura-yayinla` — çerez (web) veya edit_token (telefon)
  ile aynı kapı; izinsiz üretici fotoğrafını ve kapı dışı satırı reddeder.
- **PATCH koruması:** fatura taslağı fotoğraf tamamlansa bile sıradan düzenlemeyle
  yayına çıkmaz; yayındaki fatura ürünü düzenlemeyle taslağa düşmez.
- **DB son kapı:** `supabase/migrations/20260930000000_fatura_yayin_kapisi.sql` —
  INSERT/UPDATE tetiği (`fatura_yayin_kilidi`) + `publish_invoice_product` RPC.
  Mevcut görünür satırlara dokunmaz (tek UPDATE, `where id =` ile).
- **Telefon:** `FaturaYayinlaServisi` (slug + edit_token) + 5 birim testi; taslaklar
  telefonda da görünmez kurulur, 4 durum + işlem kimliği aynen taşınır.

## Koşan kanıtlar (bu makinede)

- Web: 16 dosya / **114 test geçti** (fatura kapısı, toplu, rastgele uçtan uca,
  yayınla ucu, PATCH koruması, kabul matrisi, 2 migration sözleşmesi, kart durumu,
  dijital iz, işlem kaydı, taslak, tek uç, master sözleşme, foto politikası, auth).
- `tsc --noEmit`: temiz. `flutter analyze` (yeni dosyalar): temiz.
- Flutter: `fatura_yayinla_servisi` (5) + `fatura_oku_servisi` (7) geçti.

## Elle test sırası (Preview deploy sonrası)

1. Google ile gir (`/giris`), misafir veri varsa `/hesap-bagla`.
2. Vitrin → "Faturadan Ekle" (anahtar yoksa düğme görünmez — doğru davranış).
3. Foto yükle → 4 sonucu gör → fiyat + stok onayla → **taslak kaydet**
   (vitrinde görünmediğini tüketici gözüyle doğrula) → **yayınla**.
4. Telefonla aynı vitrinde aynı durumları gör.

## Kilitli kapsam güncellemesi (2026-09-30)

- Havuz SADECE hızlı yol (jeton tasarrufu): yeni `firmaArama` modülü listedeki
  olmayan firmanın resmi sitesini internette aratır (Brave, ücretsiz katman,
  sonuç kalıcı saklanmaz); bulunursa aynı keşif oradan yürür. Anahtar yoksa
  akış durmaz; esnaf site ipucu yazabilir (yükleme ekranında alan var).
- Üretici fotoğrafı karta girer ve yayınlanır; kullanım izni sonra istenir.
  Takip: `fatura_kanit.ureticiGorsel` + `invoice_image_rights` (`unknown` =
  izin turu bekliyor). Engelleyen testler yeni kapsama çevrildi.
- Belge toplamı tutmazsa akış durmaz: satırlar `belgeUyarisi` bandıyla taşınır
  (el yazısı bizi bağlamaz). Sıfır satırsa yine 422.

## Kalanlar (kod dışı, ayrı onay gerektirir)

- Canlı `OPENROUTER_API_KEY` girilmeden gerçek okuma denenemez (#561 açık iş).
- 2 migration (`..._fatura_islem_kaniti`, `..._fatura_yayin_kapisi`) önce Preview
  DB'ye `migration-uygula/` etiketiyle, canlıya ayrı kararla uygulanacak.
- R1–R10 + R2a gerçek fatura kanıtı: kullanıcı faturaları + mobil ekran görüntüleri
  bekleniyor; sunucu sözleşmesi `fatura-kabul-matrisi.test.ts` içinde kilitli.
- Arama sağlayıcısı kararı (Brave alternatifi) verilmedi — P2 mevcut 55 alan adı +
  resmi sayfa okuyucuyla kapanır; harici arama ayrı iştir.
- Ücretli çağrı yapılmadı; gerçek sağlayıcı sonucu `doğrulanamadı` sayılır.

## Geri alma

- Uygulama kodu: ilgili dosya revert edilir; sunucu kapısı kalır, izinsiz yayın açılmaz.
- DB: migration dosyasındaki ROLLBACK SQL (tetik + RPC düşürme); mevcut görünür
  ürünler etkilenmez.
