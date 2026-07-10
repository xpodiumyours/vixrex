# VixRex Görev Listesi
> Oluşturma: 10 Temmuz 2026, 23:50
> Durum: MVP → Production geçiş tamamlandı, manuel işlemler bekleniyor

---

## TAMAMLANAN GÖREVLER

### Faz 1: Güvenlik & Yasal Uyum ✅
| Görev | Açıklama | Tarih | Dosya |
|---|---|---|---|
| T1.1 | Core schema SQL'i oluşturuldu | 10.07.2026 23:15 | `supabase/migrations/20260710_0000_core_schema_documented.sql` |
| T1.2 | PII güvenliği — RLS sıkılaştırıldı | 10.07.2026 23:20 | `supabase/migrations/20260710_fix_appointment_rls_and_pii.sql` |
| T1.3 | KVKK — delete_user_account cascade düzeltildi | 10.07.2026 23:10 | `supabase/migrations/20260710_fix_delete_user_account_cascade.sql` |
| T1.4 | OCR limit RPC'ye taşındı | 10.07.2026 23:25 | `supabase/migrations/20260710_add_ocr_limit_rpc.sql` |

### Faz 2: Ürün Kalitesi ✅
| Görev | Açıklama | Tarih | Dosya |
|---|---|---|---|
| T2.1 | Silent catch düzeltildi | 10.07.2026 23:30 | `lib/controllers/mixins/store_core_mixin.dart` |
| T2.2 | WhatsApp/URL validasyonu eklendi | 10.07.2026 23:35 | `lib/utils/validators.dart`, `lib/widgets/editor/form_contact_info.dart` |
| T2.3 | Görsel optimizasyon 1MB'e düşürüldü | 10.07.2026 23:38 | `lib/services/image_optimization_service.dart` |

### Faz 3: SEO & Performance ✅
| Görev | Açıklama | Tarih | Dosya |
|---|---|---|---|
| T3.1 | Publish sonrası revalidation eklendi | 10.07.2026 23:40 | `lib/controllers/store_editor_controller.dart` |

### Faz 4: Push Notification ✅
| Görev | Açıklama | Tarih | Dosya |
|---|---|---|---|
| T4 | OneSignal entegrasyonu (ücretsiz) | 10.07.2026 23:42 | `pubspec.yaml`, `lib/main.dart` |

### Faz 5: Crash Reporting ✅
| Görev | Açıklama | Tarih | Dosya |
|---|---|---|---|
| T5 | Sentry entegrasyonu (ücretsiz) | 10.07.2026 23:42 | `pubspec.yaml`, `lib/main.dart` |

### Faz 6: Mağaza Başvuruları ✅
| Görev | Açıklama | Tarih | Dosya |
|---|---|---|---|
| T6.1 | Privacy policy sayfası oluşturuldu | 10.07.2026 23:45 | `public_web/src/app/privacy/page.tsx` |
| T6.2 | Android release signing config eklendi | 10.07.2026 23:43 | `android/app/build.gradle.kts`, `android/key.properties.template` |

### Toplu Ürün Yükleme ✅
| Görev | Açıklama | Tarih | Dosya |
|---|---|---|---|
| — | Excel/CSV parse servisi | 10.07.2026 22:30 | `lib/services/bulk_product_upload_service.dart` |
| — | Bulk upload controller | 10.07.2026 22:32 | `lib/controllers/bulk_product_upload_controller.dart` |
| — | Bulk upload ekranı | 10.07.2026 22:35 | `lib/screens/bulk_product_upload_screen.dart` |
| — | Ürün yönetimine entegrasyon | 10.07.2026 22:38 | `lib/widgets/product/product_management_sheet.dart` |

### Domain & DNS ✅
| Görev | Açıklama | Tarih | Durum |
|---|---|---|---|
| T7 | Vercel'e bağlı | — | Tamamlandı |

---

## BEKLEYEN MANUEL GÖREVLER

### T8: Google Play Developer Hesabı ⏸️
| Alan | Değer |
|---|---|
| **Ne yapılacak** | play.google.com/console'dan hesap oluşturulacak |
| **Maliyet** | $25 (bir kerelik) |
| **Gerekli** | Vergi numarası, banka kartı |
| **Süre** | Hesap onayı 1-2 gün sürebilir |
| **Durum** | Bekleniyor |

### T9: App Store Developer Hesabı ⏸️
| Alan | Değer |
|---|---|
| **Ne yapılacak** | developer.apple.com'dan hesap oluşturulacak |
| **Maliyet** | $99/yıl |
| **Gerekli** | Apple ID, D-UŞN veya vergi numarası |
| **Süre** | Hesap onayı 24-48 saat |
| **Durum** | Bekleniyor |

### T10: Reklam Hesabı ⏸️
| Alan | Değer |
|---|---|
| **Ne yapılacak** | Google Ads ve/veya Meta Ads hesabı |
| **Maliyet** | Bütçeye bağlı |
| **Öneri** | İlk ay için ₺500-1000 deneme bütçesi |
| **Durum** | Bütçe kararı bekleniyor |

### T11: Vergi ve Yasal ⏸️
| Alan | Değer |
|---|---|
| **Ne yapılacak** | Vergi numarası, e-ticaret bildirimi |
| **Gerekli** | Şirket kurulumu veya şahıs vergi levhası |
| **Önem** | Google Play/App Store'da uygulama yayınlayabilmek için zorunlu |
| **Durum** | Şirket/şahıs kararı bekleniyor |

### T12: API Key'ler ⏸️
| Alan | Değer |
|---|---|
| **OneSignal** | Ücretsiz hesap → ONESIGNAL_APP_ID alınacak |
| **Sentry** | Ücretsiz hesap → SENTRY_DSN alınacak |
| **Kullanım** | `--dart-define` ile build'e eklenecek |
| **Durum** | Hesap açınca tamamlanır |

---

## DOSYA ÖZETİ

### Yeni Oluşturulan Dosyalar
```
supabase/migrations/20260710_0000_core_schema_documented.sql
supabase/migrations/20260710_fix_delete_user_account_cascade.sql
supabase/migrations/20260710_fix_appointment_rls_and_pii.sql
supabase/migrations/20260710_add_ocr_limit_rpc.sql
lib/utils/validators.dart
lib/services/bulk_product_upload_service.dart
lib/controllers/bulk_product_upload_controller.dart
lib/screens/bulk_product_upload_screen.dart
public_web/src/app/privacy/page.tsx
android/key.properties.template
```

### Güncellenen Dosyalar
```
pubspec.yaml (onesignal + sentry eklendi)
lib/main.dart (OneSignal + Sentry init)
lib/services/premium_service.dart (RPC'ye geçiş)
lib/services/image_optimization_service.dart (1MB limit)
lib/controllers/store_editor_controller.dart (revalidation + SEO service import)
lib/controllers/mixins/store_core_mixin.dart (error logging)
lib/widgets/editor/form_contact_info.dart (validasyon)
lib/widgets/product/product_management_sheet.dart (toplu yükleme entegrasyonu)
android/app/build.gradle.kts (signing config)
.gitignore (key.properties eklendi)
ENGINEERING.md (güncel durum tablosu)
```

---

## SONRAKI ADIMLAR

1. **T12** → OneSignal + Sentry hesap aç, API key al
2. **T11** → Vergi numarası_durumunu netleştir
3. **T8** → Google Play Developer hesabı aç ($25)
4. **T9** → App Store Developer hesabı aç ($99/yıl)
5. **Mağaza girişi** → Screenshots, açıklama, içerik derecelendirmesi hazırlanacak
6. **T10** → Reklam bütçesi belirlenecek
