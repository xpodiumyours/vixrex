# Vixrex — Bilinen Hatalar (Known Defects)

**Tarih:** 28 Temmuz 2026  
**Durum:** Kullanıcı onayı bekliyor  

Bu belge, mevcut kodda bilinen ve henüz düzeltilmemiş hataları listeler.  
"Çözüldü" işaretli maddeler doğrulanmayı beklemektedir.

---

## 1. Kapak Fotoğrafı Otomatik Yayınlama

| Alan | Değer |
|------|-------|
| Kaynak | `lib/controllers/store_editor_controller.dart` |
| Risk | Editörü açmak veya kapak seçmek publish tetikleyebilir |
| Durum | **Çözüldü (commit `a51ae6a`)** |
| Düzeltme | `setCoverUrl` ve `setCoverBytes`'dan publish çağrıları kaldırıldı |
| Doğrulama | Kullanıcı tarafından canlıda doğrulanmadı |

## 2. GPS Sırasında İl/İlçe Silinmesi

| Alan | Değer |
|------|-------|
| Kaynak | `lib/controllers/mixins/store_location_mixin.dart` |
| Risk | GPS başarısız olursa manuel girilen il/ilçe silinebilir |
| Durum | **Çözüldü (commit `a51ae6a`)** |
| Düzeltme | `StoreLocationStatus` state makinesi eklendi; başarısız durumlarda mevcut adres korunuyor |
| Doğrulama | Kullanıcı tarafından canlıda doğrulanmadı |

## 3. Blog Giriş Noktası Eksik

| Alan | Değer |
|------|-------|
| Kaynak | `lib/screens/blog_editor_screen.dart` |
| Risk | Blog editörü kodda var ancak kullanıcı bu ekrana ulaşamıyor |
| Durum | **Açık** — düzeltilmedi |
| Etki | Blog özelliği kullanılamaz durumda |
| Öncelik | P1 |

## 4. Admin Rolü İki Farklı Kaynakta

| Alan | Değer |
|------|-------|
| Kaynak | Flutter: `user_metadata.is_admin`, Veritabanı: `admins` tablosu |
| Risk | İki farklı yetkilendirme mekanizması tutarsız olabilir |
| Durum | **Açık** — düzeltilmedi |
| Etki | Admin yetkisi sunucu tarafında doğrulanamıyor |
| Öncelik | P0 (B2B için) |

## 5. Premium Yetkisi İstemciden Yazılabiliyor

| Alan | Değer |
|------|-------|
| Kaynak | `lib/services/premium_service.dart` |
| Risk | Ödeme doğrulanmadan premium yetkisi verilebilir |
| Durum | **Açık** — düzeltilmedi |
| Etki | B2B ürünü için kabul edilemez |
| Öncelik | P0 (B2B için) |

## 6. Veritabanı Migration Zinciri

| Alan | Değer |
|------|-------|
| Kaynak | `supabase/migrations/` |
| Risk | Migration sırası bozuk, `profiles` tablosu eksik |
| Durum | **Açık** — düzeltilmedi |
| Etki | Yeni ortam sıfırdan kurulamıyor |
| Öncelik | P0 (B2B için) |
