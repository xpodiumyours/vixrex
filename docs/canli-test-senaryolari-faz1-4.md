# Canlı Test Senaryoları — Faz 1-4

**Tarih:** 27 Ağustos 2026
**Test Hesabı:** `vixrex.deneme.1787845811686@gmail.com` (şifre bu dosyadan
kaldırıldı — 2026-08-30 denetimi, VIXREX_RULES.md madde 7; şifreyi hesabı
tutan kişiden ayrı kanaldan al)
**Vitrin:** `deneme-kuafor-salonu-mtbp9tip` (taslak, Keşfet'te görünmez)
**Canlı Adres:** `https://vixrex-public.vercel.app`

---

## ⚠️ ÖNEMLİ

- Bu testler **deploy sonrası** yapılmalıdır (commit'ler henüz remote'da değil)
- Hesap silme testi **en sona** bırakılmalıdır (geri alınamaz)
- Test sırasında hata görülürse: hata mesajı, URL ve tarayıcı bilgisi not edilmeli

---

## Faz 1 — Blog Yazısı ✍️

### Önsöz
Web'de blog yazılarını gerçekten oluşturup düzenleyebiliyor muyuz?

| # | Adım | Beklenen | Gerçek |
|---|------|----------|--------|
| 1 | `https://vixrex-public.vercel.app/giris` → e-posta ve şifre gir, "Giriş Yap" | `/app` panosuna yönlendirilir | ☐ |
| 2 | `https://vixrex-public.vercel.app/v/deneme-kuafor-salonu-mtbp9tip/blog-yonetim` adresine git | Yazı listesi görünür (boş olabilir) | ☐ |
| 3 | "Yeni Yazı Oluştur" tıkla | Blog düzenleme sayfası açılır | ☐ |
| 4 | Başlık alanına yaz: "Deneme Blog" | — | ☐ |
| 5 | İçerik alanına yaz: "Bu bir deneme yazısıdır. Web'den oluşturuldu." | — | ☐ |
| 6 | "Yayınla" butonuna tıkla | Başarı mesajı görünür, sayfa listinge döner | ☐ |
| 7 | `/v/deneme-kuafor-salonu-mtbp9tip/yazilar` adresine git | "Deneme Blog" listede görünür | ☐ |
| 8 | "Deneme Blog" başlığına tıkla | Yazı detay sayfası açılır, içerik görünür | ☐ |
| 9 | Blog-yonetim'e dön, "Deneme Blog"'u sil | Yazı listeden kaybolur | ☐ |

### Başarısız Olursa
- `PATCH /api/articles` 401 dönerse: sahip oturumu kurulmamış olabilir → `/app`'e dönüp kontrol et
- Yazı yayınlanamıyorsa: `store_articles` tablosunda `status: published` yazıldığından emin ol (Supabase Dashboard)

---

## Faz 2 — Hesap ve Vitrin Silme (KVKK) ⚠️

### Önsöz
Bu test **geri alınamaz**. Vitrin, ürünler ve hesap silinir. **En sona bırakın.**
Yeni test hesabı gerekebilir.

| # | Adım | Beklenen | Gerçek |
|---|------|----------|--------|
| 1 | `https://vixrex-public.vercel.app/app/hesap` adresine git | Hesap yönetimi sayfası açılır | ☐ |
| 2 | "Vitrini Yayından Kaldır" bölümüne git | Uyarı metni görünür | ☐ |
| 3 | Onay alanına yaz: "YAYINDAN KALDIR" | — | ☐ |
| 4 | "Yayından Kaldır" butonuna tıkla | Vitrin taslağa döner, "Yayında" etiketi kaybolur | ☐ |
| 5 | `/v/deneme-kuafor-salonu-mtbp9tip` adresine git | Vitrin artık görüntülenemez (404 veya redirect) | ☐ |
| 6 | `/app/hesap`'e dön, "Vitrini Kalıcı Sil" bölümüne git | Uyarı metni görünür | ☐ |
| 7 | Onay alanına yaz: "SİL" | — | ☐ |
| 8 | "Vitrini Sil" butonuna tıkla | Vitrin silinir, sayfa yenilenir | ☐ |
| 9 | `/app` panosuna dön | Vitrin listesi boş görünür | ☐ |
| 10 | "Hesabı Kalıcı Sil" bölümüne git | Uyarı metni görünür | ☐ |
| 11 | Onay alanına yaz: "SİL" | — | ☐ |
| 12 | "Hesabı Sil" butonuna tıkla | Hesap silinir, çıkış yapılır | ☐ |
| 13 | Aynı e-posta ve şifreyle giriş dene | Giriş başarısız olur | ☐ |

### Doğrulama (İsteğe bağlı — Supabase Dashboard)
- `stores` tablosunda `deneme-kuafor-salonu-mtbp9tip` satırı yok
- `products` tablosunda bu store'a ait satır yok
- `auth.users`'da bu e-posta kaydı yok

---

## Faz 3 — Toplu Ürün Yükleme 📄

### Önsöz
Excel/CSV dosyasından ürünleri toplu olarak ekleyebiliyor muyuz?

### Hazırlık: Deneme CSV Dosyası
Aşağıdaki içeriği `deneme-urunler.csv` olarak kaydedin:
```csv
Ürün Adı,Fiyat,Açıklama,Kategori,Stok Durumu
Saç Kesimi,150,Kısa saç kesimi hizmeti,Hizmet,Mevcut
Saç Boyama,250,Tek renk saç boyama,Hizmet,Mevcut
Manikür,100,El bakımı ve oje,Hizmet,Son birkaç adet
```

| # | Adım | Beklenen | Gerçek |
|---|------|----------|--------|
| 1 | `https://vixrex-public.vercel.app/app` → "📄 Toplu Yükle" tıkla | Dosya seçme ekranı açılır | ☐ |
| 2 | "CSV Şablonu İndir" butonuna tıkla | CSV dosyası indirilir | ☐ |
| 3 | `deneme-urunler.csv` dosyasını seç (sürükle-bırak veya tıkla) | Sütun eşleme ekranı görünür | ☐ |
| 4 | Eşlemeyi kontrol et: Ürün Adı → name, Fiyat → price_text, vb. | Otomatik eşleşme doğru | ☐ |
| 5 | "Önizle (3 ürün)" tıkla | Ürünler tabloda görünür | ☐ |
| 6 | Tablodaki × butonuyla bir ürünü kaldır | Ürün listeden kaybolur, sayı 2'ye düşer | ☐ |
| 7 | "2 Ürünü Kaydet" tıkla | Başarı mesajı: "2 ürün kaydedildi" | ☐ |
| 8 | Ürün listesini kontrol et | 2 yeni ürün görünür | ☐ |

### Ürün Sıralaması

| # | Adım | Beklenen | Gerçek |
|---|------|----------|--------|
| 9 | Ürün kartlarındaki ↑↓ butonlarını kullan | Ürünlerin sırası değişir | ☐ |
| 10 | İlk ürünü ↓ ile aşağı taşı | İkinci sıraya geçer | ☐ |
| 11 | Aynı ürünü ↑ ile yukarı taşı | Tekrar ilk sıraya döner | ☐ |

### Teklı Ürün Ekleme (Karşılaştırma)

| # | Adım | Beklenen | Gerçek |
|---|------|----------|--------|
| 12 | "+ Ürün Ekle" tıkla | Form açılır | ☐ |
| 13 | Ad: "Fön", Fiyat: "80 TL" yaz, kaydet | Ürün eklenir | ☐ |
| 14 | Düzenle butonuyla "Fön" ürününü seç, fiyatını "90 TL" yap | Ürün güncellenir | ☐ |
| 15 | Sil butonuyla "Fön" ürününü sil | Onay iste, "Kalıcı Sil" ile sil | ☐ |

### Başarısız Olursa
- `batch_create_products` 401 dönerse: sahip oturumu kurulmamış olabilir
- Dosya okunamıyorsa: tarayıcı konsoluna bak (F12 → Console)
- Sıralama çalışmıyorsa: `reorder_store_products` RPC yetki hatası olabilir

---

## Faz 4 — Profil / Şifre Değiştirme 🔐

### Önsöz
Web'den şifre değiştirip yeni şifreyle giriş yapabiliyor muyuz?

| # | Adım | Beklenen | Gerçek |
|---|------|----------|--------|
| 1 | `https://vixrex-public.vercel.app/app/profil` adresine git | Profil sayfası açılır | ☐ |
| 2 | E-posta adresini kontrol et | `vixrex.deneme...@gmail.com` görünür | ☐ |
| 3 | "Vitrin Bağlantısı" bölümünü kontrol et | Link görünür | ☐ |
| 4 | "Kopyala" butonuna tıkla | "Panoya kopyalandı" mesajı | ☐ |
| 5 | "Vitrini Gör" butonuna tıkla | Yeni sekmede vitrin açılır | ☐ |
| 6 | Şifre değiştirme: "Yeni Şifre" alanına kendi seçtiğin geçici bir şifre yaz | — | ☐ |
| 7 | "Yeni Şifre (Tekrar)" alanına aynı geçici şifreyi yaz | — | ☐ |
| 8 | "Şifreyi Değiştir" tıkla | "Şifre başarıyla değiştirildi" mesajı | ☐ |
| 9 | "Çıkış Yap" tıkla | Çıkış yapılır, `/`'ye yönlendirilir | ☐ |
| 10 | Eski şifreyle giriş dene | Giriş başarısız olur | ☐ |
| 11 | Yeni (geçici) şifreyle giriş dene | Giriş başarılı olur | ☐ |
| 12 | **ÖNEMLİ:** Eski şifreyi geri değiştir | Profil sayfasında şifreyi test hesabının bilinen eski şifresine döndür | ☐ |

### Başarısız Olursa
- Şifre değiştirme 400 dönerse: Supabase Auth minimum 6 karakter zorunlu
- Yeni şifreyle giriş yapılamıyorsa: token yenileme gecikmesi olabilir → 30 sn bekle

---

## Faz 4 — Ayarlar / KVKK Veri Dışa Aktarma 📥

### Önsopenh
KVKK kapsamında verilerimizi indirebiliyor muyuz?

| # | Adım | Beklenen | Gerçek |
|---|------|----------|--------|
| 1 | `https://vixrex-public.vercel.app/app/ayarlar` adresine git | Ayarlar sayfası açılır | ☐ |
| 2 | "Profil" bağlantısına tıkla | `/app/profil` sayfasına gider | ☐ |
| 3 | Geri dön, "Hesap Yönetimi" bağlantısına tıkla | `/app/hesap` sayfasına gider | ☐ |
| 4 | Geri dön, "📥 Verilerimi İndir" tıkla | JSON dosyası indirilir | ☐ |
| 5 | İndirilen JSON'u aç (VS Code veya tarayıcı) | İçerik şu alanları içermeli: | ☐ |

**JSON'da olması gerekenler:**
- `exported_at` — tarih
- `store` — vitrin bilgileri (name, slug, kategori, vb.)
- `products` — ürün listesi (varsa)
- `articles` — blog yazıları (varsa)

---

## Test Sırası (Öneri)

```
1. Blog yaz (Faz 1)           → risk yok, geri alınabilir
2. Toplu ürün yükle (Faz 3)   → risk yok, ürünler silinebilir
3. Şifre değiştir (Faz 4)     → risk düşük, geri değiştirilebilir
4. Veri dışa aktar (Faz 4)    → risk yok, dosya indirilir
5. Hesap silme (Faz 2)        → RİSKLİ, geri alınamaz, EN SON
```

---

## Sonuç Tablosu

| Faz | Durum | Not |
|-----|-------|-----|
| Faz 1 — Blog | ☐ | |
| Faz 2 — Hesap Silme | ☐ | EN SON |
| Faz 3 — Toplu Ürün | ☐ | |
| Faz 3 — Sıralama | ☐ | |
| Faz 4 — Profil | ☐ | |
| Faz 4 — Şifre | ☐ | |
| Faz 4 — KVKK | ☐ | |
| **GENEL** | ☐ | |
