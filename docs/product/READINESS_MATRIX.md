# Vixrex — Hazır Oluş Matrisi (Readiness Matrix)

**Tarih:** 28 Temmuz 2026  
**Durum:** Taslak — her madde için kanıt seviyesi belirtilmiştir  

Kanıt seviyeleri:
- 📁 Kodda görüldü
- ✅ Statik kontrol geçti
- 🔬 Otomatik test geçti
- 💻 Yerelde doğrulandı
- 🌐 Canlıda doğrulandı

---

## 1. Auth ve Hesap

| Özellik | Seviye | Not |
|---------|--------|-----|
| Email/şifre kayıt | 🌐 | |
| Email/şifre giriş | 🌐 | |
| Google OAuth giriş | 🌐 | |
| Şifre sıfırlama | 📁 | |
| Oturum yenileme | 🌐 | |
| Hesap silme | 📁 | |

## 2. Vitrin Editörü

| Özellik | Seviye | Not |
|---------|--------|-----|
| Editör açma (publish tetiklemez) | 💻 | `a51ae6a` ile düzeltildi |
| Kapak seçme (publish tetiklemez) | 💻 | `a51ae6a` ile düzeltildi |
| Ürün ekleme/düzenleme | 📁 | |
| Galeri yönetimi | 📁 | |
| Taslak kaydetme | 📁 | |
| Yayınlama | 📁 | |

## 3. GPS ve Konum

| Özellik | Seviye | Not |
|---------|--------|-----|
| GPS ile konum alma | 💻 | `a51ae6a` ile düzeltildi |
| Manuel il/ilçe seçimi | 📁 | |
| Hata/izin reddinde adres koruma | 💻 | `a51ae6a` ile düzeltildi |
| Yaklaşık konum yönetimi | 💻 | `a51ae6a` ile eklendi |

## 4. Public Vitrin

| Özellik | Seviye | Not |
|---------|--------|-----|
| `/v/[slug]` profil | 🌐 | vixrex-public.vercel.app |
| `/v/[slug]/urun/` | 🌐 | |
| Blog listesi/detay | 🌐 | |
| Randevu | 🌐 | |
| Sitemap/robots | 🌐 | |
| SEO metadata | 🌐 | |

## 5. B2B Özellikleri

| Özellik | Seviye | Not |
|---------|--------|-----|
| Kiralık rozet | 📁 | Görsel işaret mevcut |
| Kiralık/satılık alan modeli | ❌ | Henüz yok |
| Sipariş sistemi | ❌ | Henüz yok |
| PayTR ödeme | ❌ | Henüz yok |
| Vitrin atama | ❌ | Henüz yok |
| Admin panel (Next.js) | 💻 | Ayrı repo, local'de çalışıyor |

## 6. Altyapı

| Özellik | Seviye | Not |
|---------|--------|-----|
| Flutter analyze | ✅ | |
| Flutter test | 🔬 | 52 test dosyası |
| Flutter web build | ✅ | |
| Next.js lint | ✅ | |
| Next.js build | ✅ | |
| Supabase migration | 📁 | Zincir sorunlu |
| Supabase RLS | 📁 | |
| GitHub branch protection | ❌ | Yok |
| CODEOWNERS | ❌ | Yok |
