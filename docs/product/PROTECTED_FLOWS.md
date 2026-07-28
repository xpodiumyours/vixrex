# Vixrex — Korunan Akışlar (Protected Flows)

**Tarih:** 28 Temmuz 2026  
**Durum:** Kullanıcı onayı bekliyor  

Bu belge, hiçbir değişikliğin bozmaması gereken mevcut kullanıcı akışlarını tanımlar.

---

## 1. Auth ve Hesap Akışları

| # | Akış | Kritik Davranış |
|---|------|-----------------|
| 1.1 | Kayıt (email + şifre) | Kullanıcı hesabı oluşur, profil kaydı varsa bağlanır |
| 1.2 | Giriş (email + şifre) | Supabase Auth ile oturum açılır |
| 1.3 | Google ile giriş | OAuth akışı tamamlanır, callback doğru yönlendirir |
| 1.4 | Şifre sıfırlama | Email üzerinden şifre yenilenir |
| 1.5 | Oturum yenileme | Token süresi dolunca yenilenir, kullanıcı atılmaz |
| 1.6 | Hesap silme | Kullanıcı vitrini ve auth kaydı temizlenir |

## 2. Vitrin Editörü Akışları

| # | Akış | Kritik Davranış |
|---|------|-----------------|
| 2.1 | Editörü açma | Supabase'e yazma veya publish çağrısı yapılmaz |
| 2.2 | Vitrin adı düzenleme | Yerel taslak kaydedilir, publish tetiklenmez |
| 2.3 | Kategori değiştirme | Tema ve içerik uygun şekilde güncellenir |
| 2.4 | Kapak fotoğrafı seçme | Editör önizlemesinde görünür, publish tetiklenmez |
| 2.5 | Logo seçme | Editörde görünür, publish tetiklenmez |
| 2.6 | Galeri resmi ekleme/silme | Taslakta kalır, publish tetiklenmez |
| 2.7 | Ürün ekleme/düzenleme/silme | Taslakta kalır |
| 2.8 | İletişim bilgileri düzenleme | Taslakta kalır |
| 2.9 | Açık "Kaydet" eylemi | Yerel depolamaya yazılır, publish olmaz |
| 2.10 | Açık "Yayınla" eylemi | Public vitrin güncellenir, tam olarak bir kez |

## 3. GPS ve Konum Akışları

| # | Akış | Kritik Davranış |
|---|------|-----------------|
| 3.1 | Manuel il/ilçe seçimi | GPS'ten bağımsız çalışır, kaydedilir |
| 3.2 | GPS başlatma | Manuel adres varsa korunur |
| 3.3 | GPS izin reddi | Mevcut adres silinmez, kullanıcıya mesaj gösterilir |
| 3.4 | GPS servis kapalı | Mevcut adres korunur |
| 3.5 | GPS başarılı kesin konum | İl/ilçe eşleşirse adres güncellenir |
| 3.6 | GPS yaklaşık konum (>2km sapma) | Koordinat kaydedilir, elle adres girişi önerilir |
| 3.7 | GPS adres çözümleme başarısız | Koordinat kaydedilir, mevcut adres korunur |

## 4. Public Vitrin (Next.js) Akışları

| # | Akış | Kritik Davranış |
|---|------|-----------------|
| 4.1 | `/v/[slug]` sayfası | Vitrin profili, ürünler, galeri gösterilir |
| 4.2 | `/v/[slug]/urun/[productSlug]` | Ürün detay sayfası |
| 4.3 | `/v/[slug]/yazilar` | Blog listesi |
| 4.4 | `/v/[slug]/yazilar/[articleSlug]` | Blog detayı |
| 4.5 | Randevu yolları | Çalışır durumda |
| 4.6 | SEO metadata | `sitemap.xml`, `robots.txt`, structured data |
| 4.7 | Keşfet kartından public link | Doğru vitrine yönlendirir |

## 5. Kiralık Vitrin Akışları

| # | Akış | Kritik Davranış |
|---|------|-----------------|
| 5.1 | Kiralık rozeti gösterme | Görsel KİRALIK etiketi vitrin kartında görünür |
| 5.2 | Kiralık vitrin önizleme | Keşfet'te açılabilir |
| 5.3 | WhatsApp iletişim | Kiralık kartlarda alt eylem WhatsApp olarak kalır |

## 6. Blog Akışları

| # | Akış | Kritik Davranış |
|---|------|-----------------|
| 6.1 | Blog editörü | Kodda mevcut, giriş noktası eksik |
| 6.2 | Blog moderasyonu | Admin onay/red, kodda mevcut |
| 6.3 | Public blog görünümü | Liste ve detay sayfaları mevcut |

## 7. Admin Akışları (Flutter içi)

| # | Akış | Kritik Davranış |
|---|------|-----------------|
| 7.1 | Moderasyon sekmesi | `is_admin` metadata'sına göre görünür |
| 7.2 | Yazı onaylama/reddetme | Blog moderasyon ekranı |
