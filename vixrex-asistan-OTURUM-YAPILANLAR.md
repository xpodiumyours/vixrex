# Vixrex Asistan — Bu Oturumda Yapılanlar + Mimari

**Tarih:** 16 Temmuz 2026  
**Commit durumu:** Henüz commit yok (Furkan onayı bekleniyor).  
**Güvenli taban:** `35b5593` (yalnız doküman commit’i).  
**Üst plan:** `vixrex-asistan.md` (bu dosya özet defterdir; planı değiştirmez).

---

## 1. Mimari (nasıl kuruldu)

### 1.1 Değişmez sahiplik (mevcut ürün)

| Yüzey | Sahip | Not |
|--------|--------|-----|
| Mobil / web uygulama (editör, kabuk) | Flutter | Vitrin düzenleme, yayın, VixRex sekmesi |
| Public müşteri vitrini | Next.js `public_web` | `/v/:slug` — app host render etmez |
| Kayıt / yayın | `StoreEditorController` → `StorePublishService` | İkinci yayın motoru yok |
| Konum UI | `FormLocationInfo` → `LocationEditorSection` | İkinci GPS yolu yok |
| Yasal UI | `LegalConsentSection` | Sessiz onay yok |
| Rehber önerileri | `VixRexGuidanceService` + `VixRexScreen` | İkinci FAQ botu yok |

### 1.2 Asistanın yerleştirildiği yer

Asistan **yeni bir ürün değil**; mevcut uygulamaya **giriş + rehber kapısı** olarak eklendi.

```
Landing
  ├─ "Vixrex Oluştur" / rozet ──► /onboarding-chat  (kurulum filmi)
  │                                    │
  │                                    ├─ ad / WhatsApp (sohbet)
  │                                    ├─ FormLocationInfo (editör)
  │                                    ├─ LegalConsentSection (editör)
  │                                    └─ StoreEditorController.publish()
  │                                           │
  │                                           └─ create_store_with_token (Supabase RPC)
  │
  └─ (kayıtlı vitrin) ──► HomeShell

HomeShell
  ├─ Rozet ──► VixRex sekmesi (index 2)   ← overlay FAQ kapalı
  ├─ VixRex sekmesi ──► VixRexGuidanceService önerileri
  │                         ├─ kapak şablonu → openCoverTemplatePicker
  │                         ├─ galeri / açıklama → scrollTo*
  │                         ├─ ürün → scrollToProducts
  │                         ├─ OCR → openOcrScanner
  │                         ├─ randevu → scrollToCategory
  │                         └─ paylaş / QR → mevcut aksiyonlar
  └─ Vitrinim ──► MyVitrinScreen (editör, dokunulmaz akışlar korunur)
```

### 1.3 Bilinçli kurallar

- **İkinci yol yok:** aynı iş için ikinci publish / GPS / asistan motoru yok.
- **Kurulum modu** = `VixRexOnboardingChatScreen` (`/onboarding-chat`).
- **Özellik modu** = mevcut `VixRexScreen` + `VixRexAction` handler’ları.
- Public HTML render hâlâ yalnız `public_web`.

---

## 2. Yapılanlar (tek tek)

### Faz 0 — Plan

1. Tek kaynak plan: `vixrex-asistan.md`
2. HTML tarz örneği mevcut (`vixrex-asistan-ornek.html`)
3. Bu oturumda plan dosyasına sonradan “tamamlandı” işaretleri şişirilmedi (Furkan isteği)

### Faz 1 — Yayın temeli

4. Sorun doğrulandı: misafir `stores.insert` RLS engelli; token Auth ile kopuktu  
5. Migration eklendi: `supabase/migrations/20260716_create_store_with_token.sql`  
6. `StorePublishService`: yeni kayıt → `create_store_with_token` RPC (paralel insert yok)  
7. `supabase_store_repository.insertStore` aynı RPC’ye alındı  
8. Token mirror: `last_published_edit_token` + `vitrin_edit_token` / `store_edit_token`  
9. Auth: `last_published_edit_token` öncelikli okuma  
10. Testler: `store_publish_service_test`, `guest_publish_token_align_test`  
11. **Canlı Supabase:** RPC uygulandı ve doğrulandı  
12. **Canlı Supabase:** eksik yasal kolonlar eklendi (`publication_consent_accepted`, `terms_*`, `privacy_notice_*`)

### Faz 2 — Kurulum sohbeti

13. Ekran: `lib/screens/vixrex_onboarding_chat_screen.dart`  
14. Route: `/onboarding-chat` + `AppRouter.navigateToOnboardingChat`  
15. Landing “Vixrex Oluştur” → onboarding (forma dump yok)  
16. Landing işletme adı kutusu → `initialName` (varsa ad adımı atlanır)  
17. Akış: Evet → ad → WhatsApp → konum → yasal → yayın → link  
18. Konum: **`FormLocationInfo`** (editörle aynı; ayrı GPS kaldırıldı)  
19. Yasal: **`LegalConsentSection`** (`isLegalPublishReady` ile Yayınla)  
20. Yayın: **`StoreEditorController.publish()`**  
21. Link: `PublicSiteConfig` ile kopyala / canlı aç  
22. “Hesabımı güvenceye al” → Auth  
23. “Vitrinime git” → HomeShell  

### Faz 3 — Tek kapı

24. Landing rozet → aynı onboarding (`ChatbotBadge.onOpen`)  
25. Uygulama içi rozet → VixRex sekmesi (eski overlay FAQ girişleri kapalı)  
26. VixRex “Başla” (snapshot yok) → onboarding  
27. Snapshot varken → mevcut rehber / Vitrinim / scroll aksiyonları  
28. Sözleşme testi: rozet `onOpen` overlay açmaz  

### Faz 4 — Görünüm (mevcut yollara bağlı)

29. Yayın sonrası sohbet: kapak teşviki metni  
30. “Kapak şablonu seç” → HomeShell + `VixRexAction.openCoverTemplatePicker`  
31. “Rehberde devam et” → VixRex sekmesi (index 2)  
32. `HomeShellScreen.initialVixRexAction` ile asistan aksiyonu tek handler’a düşer  
33. Guidance kapak önerisi → şablon seçici (scroll yerine)  
34. Kalite listesinde kapak aksiyonu → şablon seçici  

### Faz 5 — Ürün (mevcut yollara bağlı)

35. Guidance: ürün alanı + **OCR / fiş tarayıcı** önerisi  
36. VixRex sekmesi: “Fiş veya etiketle ürün ekle” kartı → `openOcrScanner`  

### Faz 6 — Randevu / paylaşım (mevcut yollara bağlı)

37. VixRex: WhatsApp paylaş / QR kartları (yayınlıysa)  
38. VixRex: randevu → `scrollToCategory` (editör paket yolu)  

### Destek / düzeltmeler

39. GPS mixin: Chrome “yaklaşık konum” kabulü (editörle hizalı)  
40. `FormLocationInfo`: GPS’te lat/lng yazımı (önceden kaçıyordu)  
41. Ayrı asistan GPS / elle il-ilçe eşleme **kaldırıldı** (paralel yoldu)  
42. Chrome test oturumu: `http://localhost:5570` (Supabase define ile)  
43. Yayın hatası teşhisi: eksik kolon → kolonlar eklendi; kullanıcı tekrar deneyebilir  

---

## 3. Bilinçli olarak yapılmayanlar

- Git commit / push  
- Eski `VixRexOverlay` dosyasının tamamen silinmesi (girişler kapalı; kod duruyor)  
- Faz 7 tam “sürekli koç” döngüsü (Instagram/SEO mesajları vb. derinleşmedi)  
- TTL, offline, puan/rozet, analytics, AutoVitrinBuilder  
- Plan dosyasına sürekli “tamamlandı” işareti basmak (Furkan “plana dokunma / güncelleme” dediği turlar oldu)

---

## 4. Nasıl test edilir (kısa)

1. Chrome: `http://localhost:5570` (veya güncel flutter run portu)  
2. Landing → Vixrex Oluştur → ad / WA / konum / yasal → Yayınla  
3. Link görünsün → Kapak şablonu / Rehberde devam  
4. Uygulama içi rozet → VixRex sekmesi  
5. İsteğe bağlı: Hesabımı güvenceye al → Auth  

---

## 5. Değişen / eklenen başlıca dosyalar

| Dosya | Rol |
|--------|-----|
| `lib/screens/vixrex_onboarding_chat_screen.dart` | Kurulum sohbeti |
| `lib/config/app_router.dart` | `/onboarding-chat`, home initial action |
| `lib/screens/landing_screen.dart` | CTA + rozet → onboarding |
| `lib/screens/home_shell_screen.dart` | Rozet → VixRex sekmesi; initial action |
| `lib/widgets/chatbot_badge.dart` | `onOpen` tek kapı |
| `lib/widgets/editor/form_location_info.dart` | GPS lat/lng |
| `lib/controllers/mixins/store_location_mixin.dart` | Yaklaşık konum |
| `lib/services/store_publish_service.dart` | Create RPC |
| `lib/repositories/supabase_store_repository.dart` | Create RPC |
| `lib/services/store_local_storage_service.dart` | Token mirror |
| `lib/screens/auth_screen.dart` | Token okuma hizası |
| `lib/services/vixrex_guidance_service.dart` | Kapak/ürün/OCR önerileri |
| `lib/screens/vixrex_screen.dart` | OCR / paylaş / QR / randevu kartları |
| `supabase/migrations/20260716_create_store_with_token.sql` | Misafir create RPC |
| Testler | publish, token, route, rozet onOpen |

---

## 6. Durum özeti

| Katman | Durum |
|--------|--------|
| Mimari bağlama (tek motor / mevcut parçalar) | Yapıldı |
| Supabase RPC + yasal kolonlar | Canlıda uygulandı |
| Kurulum → yayın → rehber köprüsü | Kodda hazır |
| Güvenli yol (G0–G5) | `vixrex-asistan.md` §5’te kilitli |
| G1: VixRex sıradaki adım = sohbet + quick reply | Yapıldı (aynı Guidance + Action) |
| Furkan Chrome kabulü (G0) | Kullanıcı testinde |
| Commit | Yok — onay sonrası |
