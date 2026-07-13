# VixRex Oturum Özeti (Not Defteri)

> **Son güncelleme:** 2026-07-11  
> **Amaç:** Yeni session’da önce bunu oku. Büyük operasyon yok; küçük dilim.

---

## 1. Ürün vaadi (çekirdek — sapma yok)

Kullanıcının kafası:

1. Fotoğraf / şablon ile vitrin  
2. Hızlı ürün ekleme  
3. Yayınla  
4. Link + QR → müşteri görsün  

Tek cümle: *“Rafını çek, ürünlerini ekle, yayınla — müşteri link/QR ile görsün.”*

**Özellik modeli:** Ayarlardan seçilmez. **Kategori = paket** (sessiz otomatik).  
Kuaför/güzellik → randevu paketi açık. Butik/fırın/giyim → randevu yok, UI’da görünmez.

---

## 2. Nasıl çalışıyoruz (zorunlu disiplin)

| Kural | Anlamı |
|-------|--------|
| Küçük dilim | Max 1–3 dosya; “her şeyi düzelt” yasak |
| Kullanıcı teknik değil | Adım adım, ekranda ne göreceği; jargon yok |
| Önce sor / netleştir | Ambiguous ise uygulama |
| Commit/push | Sadece isterse |
| Analyze/test | Kullanıcı isterse veya dilim doğrulama için kısa |

---

## 3. Bu oturumda yapılanlar (özet)

### Public link / parity
- Path URL strategy (`usePathUrlStrategy`) — `/v/slug` profil açar  
- Link onarımı (hash/localhost → `vixrex.app/v/slug`)  
- Randevu URL birleşimi: `/v/:slug/randevu` + `/v/:slug/randevu/:token`  
- Public fetch: `logo_url`, `google_business_link`  
- “Web Sitesi” = gerçek website (vitrin self-link değil)  
- `PublicBookingScreen` + `mapStoreFromSupabase` Widget’ta  

### Kategori → özellik paketi (dilimler)
- `BusinessCategoryConfig.supportsBookingPackage`  
  Açık: kuafor, saglik_yasam, spor_fitness, egitim_ders, ev_temizlik, pet, teknik_servis, oto  
  Kapalı: butik, giyim, **fırın**, gıda, …  
- Ayarlar: “Randevu bildirimleri” yalnız paket açıksa  
- `selectCategory` → `bookingSettings.isEnabled` otomatik  
- Editör `WorkingHoursEditor` aynı matrise bağlı  

### SEO / Google
- Flutter `web/index.html` → `noindex` (editör indekslenmesin)  
- Google Haritalar rehber kartı editörden kaldırıldı  
- Public meta sıkılaştırıldı (OG/Twitter, robots index) — `public_web`  
- Search Console: önceki geçici Vercel aliası doğrulandı; aktif hedef `vixrex-public.vercel.app`
- Sitemap kutuya **sadece** `sitemap.xml` yazılır (tam URL yazılmaz)  
- Asıl SEO hedefi uzun vadede: **`vixrex.app/v/{slug}`** (public), Flutter `/app` değil  

### Commit notu
- `a9e1014` — Search Console doğrulama dosyası push edildi  
- Diğer parity/paket/SEO değişikliklerinin çoğu **henüz commit edilmemiş** olabilir — `git status` kontrol et  

---

## 4. Sıradaki dilimler (öncelik)

1. **Commit checkpoint** — birikmiş değişiklikleri güvenli commit (kullanıcı isterse)  
2. **Search Console** — sitemap durumu “Başarılı” olana kadar bekle / gerekirse yeniden `sitemap.xml`  
3. İleride: **`vixrex.app`** property + sitemap (asıl SEO)  
4. Bildirim varsayılanı (kuaför seçilince push tercihi sessiz) — isteğe bağlı  
5. Keşfet / VixRex sekmesi / blog — çekirdek dışı; dondur veya ayrı karar  

---

## 5. Bilinçli web-only / Flutter-only

| Web-only | Flutter-only |
|----------|--------------|
| Public `/v/slug` SSR, SEO, çerez, GA4 | Editör, Keşfet, Ayarlar, push inbox |

---

## 6. Kritik dosyalar (hızlı referans)

- `lib/config/business_category_config.dart` — kategori + `supportsBookingPackage`  
- `lib/config/public_site_config.dart` — canonical link / randevu path  
- `lib/controllers/store_editor_controller.dart` — `selectCategory` paket  
- `lib/screens/app_settings_screen.dart` — randevu bildirimi gizle  
- `lib/screens/my_vitrin/sections/vitrin_form_section.dart` — randevu UI gizle  
- `web/index.html` — noindex  
- `public_web/src/app/v/[slug]/page.tsx` — public SEO meta  
- `DEMO_MVP_GERCEK_URUN_GECIS_HARITASI.md` — checkbox harita  

---

## 7. Yeni session açılış prompt’u (kopyala)

```
ÖNCE OKU: VIXREX_OTURUM_OZETI.md (çekirdek + son dilimler)

Bugün sadece: [TEK DİLİM].
Büyük operasyon yok. Kullanıcı teknik değil — adım adım anlat.
```

---

*Bu dosya kod değil; oturum belleğidir. Her önemli dilim sonrası 5 satır güncelle.*
