# KİLİTLİ PLAN — Web ↔ Mobil Eşitleme

**Durum:** KİLİTLİ · **Yön:** Flutter → Next.js (tek yön) · **Kaynak:** VIXREX_RULES.md §1
**Referans:** `lib/` (Dart) canlı referans, `public_web/` (TypeScript) eşitlenecek taraf
**Ortak omurga:** Supabase (Auth + RLS + RPC) · **Vitrin render:** yalnızca Next.js `/v/:slug`
**Tarih:** 2026-08-31 · **Sahip:** Casper
**Dayanak:** `docs/akis-envanteri.md`, `docs/plan-web-apk-esitleme.md`, `VIXREX_RULES.md`

---

## 0. DURDUR — Kilit Kuralları (hemen)

1. `lib/` donduruldu — çalışan Flutter Web/APK referansı bozulmaz. Dokunma.
2. `public_web/app` içine rastgele yeni ekran yok. Her ekran bu plandaki faza bağlı olacak.
3. Aynı anda tek ajan, tek faz, tek klasör. İki ajan aynı dosyayı ezmeyecek.
4. Vitrin alanları için ikinci form paneli açılmayacak — düzenleme yalnızca `OwnerAssistantPanel` (asistan) üzerinden. Kural: `VIXREX_RULES.md §1` + `docs/vitrin-alan-semasi.md`.
5. İş kuralları iki yerde yazılmayacak. Kaynak Supabase RLS/RPC; istemciler sadece çağırır.
6. PR limiti 12 dosya / 600 satır. Aşarsa `Kapsam-Onay:` gerekçesi zorunlu.
7. Her faz `npm run lint && npm test && npm run build` yerelde yeşil olmadan merge yok.
8. Commit öncesi `git fetch` + `origin/main` kontrolü zorunlu (geçmişte yanlış dalda build hatası yaşandı).

İhlal → PR reddedilir.

---

## 1. ENVANTER — Gerçek Durum (doğrulandı)

`docs/akis-envanteri.md` güncel envanterdir. Özet:

**VAR (parite tamam):** kayıt/giriş/çıkış, vitrin kurma, vitrin düzenleme (asistan), ürün ekle/düzenle/sil/sırala, toplu ürün yükleme (Excel/CSV, XML yok), vitrin/blog görseli yükleme, taslak önizleme, yayınlama, yayından kaldırma, yasal onay, public vitrin, randevu alma/takip/yönetme, blog CRUD, bildirim kutusu, keşfet+ kategori, kiralama, profil/ayarlar/hesap silme, yardım.

**YARIM (öncelikli):**
- Premium ödeme/yenileme (API var, düğme yok) — ORTA
- Şifre sıfırlama (web e-posta isteyemiyor) — KÜÇÜK
- Çalışma saatleri (haftalık yapı yok) — ORTA
- Ürün görseli cihazdan yükleme (sadece URL) — ORTA
- Section visibility (2 alan var, tamamı yok) — ORTA
- Keşfet arama/favoriler — ORTA

> **Düzeltme 2026-08-31:** `docs/akis-envanteri.md` Landing satırında yazan `/basla` kırığı kodda **artık yok**. `HeroSection.tsx:108-113` ve `BottomCta.tsx:39-45` artık `onStartAssistant` ile telefon mockup içindeki asistana bağlanıyor; `/basla` form action'ı kaldırıldı (commit `83c85ce`, `c3b5387`). `LandingAsistanSohbeti.tsx:185-186` taslağı `vixrex_asistan_taslak` ile `/kayit`'a taşıyor. Envanterdeki o satır stale — Faz 1 bu yüzden aşağıda "doğrulama" olarak güncellendi.

**YOK (öncelikli):**
- Randevu hizmetleri/kapasite/takvim ayarları
- Ürün kategori yönetimi (oluştur/adlandır/sırala/sil)
- Galeri yönetimi
- SSS maddeleri yönetimi
- Pazaryeri serbest link listesi
- Push tercih ekranı
- Google ile giriş
- Instagram bağlama ekranı

**BİLİNÇLİ YOK (dokunma):** OCR, çevrimdışı manuel panel, ikinci vitrin formu — Flutter uzmanlığında kalır.

> Not: `docs/plan-web-apk-esitleme.md` Faz 1-4'ün çoğu kapanmış görünüyor; yukarıdaki YARIM/YOK listesi güncel envantere göre fazları yeniden sıralar.

---

## 2. HARİTA — Fazlara Dönüşüm

| Faz | Kapsam | Envanter karşılığı | Bitiş şartı (canlı kanıt) |
|-----|--------|-------------------|---------------------------|
| **Faz 1** | Landing → Kayıt akışı doğrulaması | Landing DOĞRULANDI (eski `/basla` kırığı düzeltildi) | Landing CTA → asistan → `/kayit` taslak taşıma canlıda kesintisiz — browser testiyle kilitlenir |
| **Faz 2** | Şifre sıfırlama + Google giriş | Şifre YARIM, Google YOK | Web'den sıfırlama e-postası iste + yeni şifreyle giriş; Google ile giriş çalışıyor |
| **Faz 3** | Randevu yapılandırması | Randevu YOK + Çalışma saatleri YARIM | Next.js-only yeni vitrin randevu hizmet/saat/kapasite kurup müşteri randevu alabiliyor |
| **Faz 4** | Ürün yönetimi tamamlama | Kategori YOK + Ürün görsel YARIM + Galeri YOK + SSS YOK + Pazaryeri YOK | Kategori oluştur/sırala, ürün görseli yükle, galeri/SSS/pazaryeri yönet — vitrinde görünüyor |
| **Faz 5** | Premium ödeme bağlama | Premium YARIM | `PREMIUM_REQUIRED` vitrinde PayTR linkine bağlandı, ödeme sonrası yayın açılıyor |
| **Faz 6** | Keşfet parity + push tercih | Keşfet YARIM + Push YOK | Arama + favori + push tercih web'de çalışıyor, Flutter ile aynı |

Faz sırası etki + bağımlılığa göre kilitlendi. Faz atlama yok, biri yeşil olmadan sonrakine geçilmez.

---

## 3. TEK SÖZLEŞME — Kurallar

- Auth/yetki/işletme seçimi tek sözleşme. İki istemci aynı Supabase `auth.uid()` + RLS + RPC'yi kullanır.
- `VIXREX_RULES.md §9` geçerli: `SECURITY DEFINER` için `search_path` sabitle, `p_user_id` gibi client parametresiyle yetki kararı verme, `anon` için rate-limit + fail-closed captcha.
- Mesajlar tek katalog: `shared/vixrex_mesajlar.json` → Flutter `*.g.dart`, Web `vixrexMesajlari.ts`. Elle cümle yazma.
- Vitrin alanları tek şema: `docs/vitrin-alan-semasi.md` → `data-vixrex-editable` / `data-vixrex-label`.
- SEO: public sayfalar `index`, `/app` ve `/v/:slug` sahip çalışma alanı `noindex`. Vitrin render yalnızca Next.js.
- APK ↔ web geçişi: aynı Supabase hesabı, aynı işletme durumu, aynı dil/menü, geri dönüş adresi korunur.

---

## 4. SIRAYLA EŞİTLE — Uygulama Disiplini

Her faz için:
1. Referans ekranı `lib/` içinde tespit et (dosya: satır).
2. Web karşılığını `public_web/` içinde aynı şemayla uygula.
3. Aynı doğrulamayı aynı API/RPC üzerinden çalıştır.
4. Hata/boş/yükleme durumlarını aynı mesaj kataloğundan göster.
5. Sayfayı pano/vitrin içinden erişilebilir kıl (bağlantısız sayfa yok).

---

## 5. KİLİTLE — Test Zorunluluğu (her faz)

Her faz 2 kilitle kapanır, biri eksikse faz kapanmaz:

**a) Sözleşme testi:** Aynı işlem Flutter ve Web'de aynı Supabase sonucunu üretir.
  - Örn: kategori oluştur → `product_categories` satırı aynı.
  - Konum: `public_web/tests/` + `test/` (varsa).

**b) Browser testi:** Aynı kullanıcı yolu iki platformda aynı adımlarla biter.
  - Playwright: `public_web/e2e/` ve Flutter integration test.
  - Kanıt: canlı URL + commit + ekran görüntüsü.

Ek bekçi: `shared/vixrex_mesajlar.json` tek kaynak testi, `noindex` testi, renk bekçisi (`--owner-*`).

---

## 6. AJAN DİSİPLİNİ — Kabul Kriteri

Her ticket/PR açıklamasında zorunlu:

```
Referans: lib/[dosya]:[satir] (Flutter Web ekranı)
Web: public_web/src/app/[yol]/page.tsx
RPC/RLS: [fonksiyon/tablo]
Kabul: sözleşme testi yeşil + browser testi yeşil + canlı URL kanıtı
Kapsam-Onay: (12 dosya/600 satır aşılırsa gerekçe)
```

Eksikse merge yok. Main'e indirme Claude'da.

---

## 7. BUGÜN BAŞLANGIÇ — Faz 1 ve Faz 2

**Faz 1: Landing → Kayıt akışı DOĞRULAMA (kod düzeltildi, test kilidi eksik)**

Durum: Kod 2026-08-29'da düzeltildi — `HeroSection.tsx:108-113` `onStartAssistant` ile asistana bağlanıyor, `/basla` artık yok. `LandingAsistanSohbeti.tsx:185-186` taslağı `/kayit`'a taşıyor. Yapılacak iş kod değil, **browser testiyle kilitlemek**:
- Playwright: Landing CTA → asistan aç → isim gir → `/kayit` → kayıt → `/app` vitrin oluşturma taslakla dolu mu?
- Kanıt: canlı URL + commit + ekran görüntüsü.

**Faz 2: Şifre sıfırlama + Google giriş (SIRADAKİ GERÇEK İŞ)**

Envantere göre web'de sıfırlama e-postası isteği yok (`/sifre-sifirla` sadece tamamlama), Google girişi yok. Bu faz kod ister:
- `/sifre-sifirla` veya `/giris` içine `resetPasswordForEmail` isteği ekle.
- `AuthService.signInWithGoogle` karşılığı `/kayit` ve `/giris` içine Supabase Google provider ekle.

**Bitiş kanıtı Faz 2:** Web'den sıfırlama e-postası iste → yeni şifreyle giriş; Google ile giriş → `/app` panosuna varış.

**Sonraki:** Faz 3 (randevu yapılandırması), sırayla devam.

---

## İlerleme Takibi

- [ ] Faz 1 — Landing → Kayıt akışı doğrulama (browser testiyle kilitle)
- [ ] Faz 2 — Şifre sıfırlama + Google giriş
- [ ] Faz 3 — Randevu yapılandırması
- [ ] Faz 4 — Ürün yönetimi tamamlama
- [ ] Faz 5 — Premium ödeme bağlama
- [ ] Faz 6 — Keşfet + push tercih

Plan kilitlidir. Değişiklik yalnızca Casper onayıyla ve bu dosyada sürümlenerek yapılır.
