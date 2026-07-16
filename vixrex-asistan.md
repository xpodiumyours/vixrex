# VIXREX ASİSTAN PLANI (TEK KAYNAK)

**Bu dosya bağlayıcı tek plandır.**  
Görsel tarz: `vixrex-asistan-ornek.html` (HTML ile bu plan çelişirse önce Furkan’a sor; tahminle seçme).  
Oturum özeti (ne yapıldı): `vixrex-asistan-OTURUM-YAPILANLAR.md` — planı değiştirmez.

**Üst kurallar (değişmez):** `PROJECT_RULES.md` → `SON_DURUM.md` → `AGENTS.md` → bu dosya.  
Bu plan üst kuralları gevşetemez.  
**Asistan skill (her adımda):** `.cursor/skills/vixrex-asistan-bagla/SKILL.md` —
ürünü bozma, ölü kod bırakma, kabuk işlem yok; çalışan ürün üzerine çalışan asistan.

**Tarih:** 16 Temmuz 2026  
**Kod durumu:** Çalışma ağacında (commit yok). Paralel asistan/yayın/GPS yok — mevcut yapıya bağlanır.

---

## 1. ÜRÜN (ne istiyoruz)

Vixrex maskotu, kullanıcı uygulamada kaldığı sürece yanında olan tek asistandır.

Akış (sırayla):
1. Kısa soru: dijital vitrin oluşturayım mı?
2. Onaydan sonra yalnız: işletme adı, WhatsApp, konum (GPS veya yazı)
3. “Artık dijitalde varsın” + kolay profil + web linki (domain yok mesajı)
4. Kapak şablonu teşviki
5. Sonra sırayla özellik tanıtımı: açıklama → ürün → randevu → paylaşım → hesap…

Üslup: kısa cümle, teşvik, kalabalık tanıtım yok, bir anda her şeyi sorma.

---

## 2. AI ÇALIŞMA KURALLARI (zorunlu)

Her ajan bu plana göre çalışırken:

0. **Her adımda** `.cursor/skills/vixrex-asistan-bagla/SKILL.md` oku ve kapıyı geç.
1. **Yeni plan dosyası açma.** Bu dosyayı güncelle veya Furkan’a sor.
2. **Paralel yol yok.** Yeni kayıt/yayın motoru yok. Kullan: `StoreEditorController`, `StorePublishService`, `link_store_to_user`.
3. **İkinci asistan/FAQ botu yok.** Landing, badge, VixRex sekmesi aynı motor.
4. **Faz atlama yok.** Faz N bitmeden Faz N+1 kodlama.
5. **Küçük iş.** Bir seferde bir faz dilimi; büyük refactor yok.
6. **Dokunulmaz:** canlı önizleme, yerel kayıt, tema, mobil tab, sticky, Keşfet→kart→Düzenle akışı.
7. **Misafir create:** security-definer RPC. Geniş `anon INSERT` politikası yazma.
8. **Furkan teknik değil.** Belirsizse sor. Varsayım varsa açık yaz.
9. **“Tamamlandı”** ancak kontrol sütunundaki davranış gerçekten çalışıyorsa.

---

## 3. FAZLAR (sıra kilitli)

### Faz 0 — Plan kilidi
Durum: **bitti**

- Bu dosya tek kaynak
- HTML tarz örneği var

---

### Faz 1 — Yayın temeli
**Kod:** çalışma ağacında (RPC + publish + token hizası + test).  
**Canlı:** RPC + yasal kolonlar uygulandı. Chrome kabul / commit açık.

Amaç: Üye olmadan vitrin oluşsun; girişte hesaba bağlansın.

| Adım | Yapılacak | Kontrol |
|------|-----------|---------|
| 1.1 | Misafir create RPC | `create_store_with_token` |
| 1.2 | Publish servisi bu RPC’yi kullanır | Paralel insert yok |
| 1.3 | Token key hizası (publish ↔ Auth) | Mirror + Auth okuma |
| 1.4 | Test / canlı kabul | Birim test + Chrome |

---

### Faz 2 — Asistan varlık sohbeti

Amaç: HTML’deki ilk film uygulamada çalışır.  
**Kod:** çalışma ağacında. Konum=`FormLocationInfo`, yasal=`LegalConsentSection`, yayın=`publish()`.  
**Kabul:** Chrome testi + Furkan onayı; commit yok.

| Adım | Yapılacak | Kontrol |
|------|-----------|---------|
| 2.1 | Asistan ekranı + rota | `/onboarding-chat` |
| 2.2 | Landing “Vixrex Oluştur” → asistan | Forma dump yok; ad alanı `initialName` |
| 2.3 | Ad → WhatsApp → konum → kısa yasal → publish | Editör parçaları bağlı |
| 2.4 | “Artık dijitalde varsın” + link mesajı | Kopyala / canlı aç (PublicSiteConfig) |
| 2.5 | “Hesabımı güvenceye al” (yumuşak) | Auth |

Bu fazda **yapılmayacak:** kapak şablonu, ürün, randevu.

---

### Faz 3 — Tek kapı

| Adım | Yapılacak | Kontrol |
|------|-----------|---------|
| 3.1 | Badge → aynı asistan | Landing rozet → onboarding; uygulama içi rozet → VixRex sekmesi (overlay FAQ kapalı). Kısmen yapıldı, Chrome onayı yok. |
| 3.2 | VixRex sekmesi → aynı asistan | Mevcut `VixRexScreen` + `VixRexGuidanceService` korunur; ikinci rehber yok |
| 3.3 | Mod: kurulum / sıradaki özellik | Kurulum=onboarding; özellik=mevcut guidance/sekme |

---

### Faz 4 — Görünüm

- Kapak şablonu teşviki  
- Galeri teşviki  
- Kısa açıklama  
- Kalite göstergesi (mevcut guidance reuse)

---

### Faz 5 — Ürün

- Sohbetle ürün/hizmet ekleme  
- OCR / Excel’i konuşarak tanıtma (mevcut ekranı tetikle)

---

### Faz 6 — Randevu, duyuru, paylaşım

- Randevu tanıtımı  
- Kampanya/yazı tanıtımı  
- Link / QR / WhatsApp paylaşım

---

### Faz 7 — Hesap, büyüme, sürekli koç

- Hesap güvence  
- Instagram / Keşfet / SEO mesajları  
- Kalıcı “sıradaki özellik” döngüsü

---

### Faz 8 — Serbest metin anlama (LLM destekli sohbetten kayıt)

**Durum:** Furkan isteğiyle askıda. OpenAI kodu ve Supabase Function korunuyor;
uygulama çağrı yapmıyor, Function da OpenAI isteği göndermeden 503 döndürüyor.

**Amaç:** Kullanıcı sohbette serbest yazınca (örn. "adresim Kadıköy"), Vixrex
anlayıp kısaca özetler, onay ister; onaylanınca mevcut `StoreEditorController`
üzerinden kaydeder. İkinci yazma yolu açılmaz.

**Kapsam:** İşletme adı, WhatsApp, adres, açıklama, kategori.
**Kapsam dışı (bilerek):** Yasal onaylar (`LegalConsentSection`). Onay
checkbox'ları serbest metinle verilmez — uyumluluk riski nedeniyle mevcut
buton akışı aynen kalır.

| Adım | Yapılacak | Kontrol |
|------|-----------|---------|
| 8.1 | Serbest metin → alan önerisi → onay kartı → `StoreEditorController` setter akışı | Kod/test doğrulandı; mock üretim kodunda bırakılmadı |
| 8.2 | Supabase Edge Function iskeleti (`vixrex-assistant-nlu`) + cihaz/IP bazlı rate limit | Canlı: 6 istek/dakika |
| 8.3 | Furkan, OpenAI hesabında aylık sert harcama limitini kurar | Doğrulandı: $5 kredi, otomatik şarj kapalı |
| 8.4 | Edge Function gerçek OpenAI API'sine bağlanır | Askıda: kod korunuyor, OpenAI çağrısı kapalı |
| 8.5 | Furkan onayı → commit | Bozulma yok |

**Yasak (ek):** Harcama limiti kurulmadan gerçek API'ye bağlanmak;
`StoreEditorController` dışında ikinci bir yazma yolu açmak; onay alınmadan
alan kaydetmek.

---

### Sonra (şimdi yok)

TTL, offline, puan/rozet, analytics, AutoVitrinBuilder.

---

## 4. TEKNİK SINIRLAR

**Kullan:**
- `StoreEditorController`, `StorePublishService`
- `AuthService.linkAnonymousStore` → RPC `link_store_to_user`
- `LocationService` (GPS)
- `StorePublishValidator`
- HTML tonu / mevcut bubble-quick reply parçaları (uygunsa)

**Yazma:**
- Yeni `StoreData` yolu
- Yeni publish API
- `link_anonymous_store` adlı yeni RPC
- Geniş anon INSERT policy
- İkinci chatbot/asistan

---

## 5. GÜVENLİ İLERLEME YOLU (kilitli)

**Hedef:** Asistan uygulamada hakim olsun; kullanıcıyla sohbet etsin.  
**Yöntem:** Yeni motor yok. Editör, publish, guidance, OCR, paylaşım **asistana bağlanır**.

### Bağlama haritası (tek doğru)

| Kullanıcı kapısı | Gider | Motor |
|------------------|--------|--------|
| Landing oluştur / rozet | `/onboarding-chat` | Kurulum sohbeti → `StoreEditorController` |
| App rozet | VixRex sekmesi | `VixRexGuidanceService` + sohbet dili → `VixRexAction` |
| VixRex “sıradaki adım” | Aynı sekme | Quick reply → mevcut HomeShell handler |
| Kapak / galeri / ürün / OCR / paylaş | Mevcut ekranlar | `openCoverTemplatePicker`, `scrollTo*`, `openOcrScanner`, … |

### Sıra (atlamadan)

| Adım | Ne | Güvenli kontrol | Durum |
|------|----|-----------------|--------|
| **G0** | Chrome: misafir yayın + link | Yayın gerçekten oluşur | Test sonra (Furkan) |
| **G1** | VixRex sıradaki adım sohbet dili | Guidance → bot + quick reply | Yapıldı |
| **G2** | Companion sürekliliği | Mevcut `ChatbotService` VixRex sekmesinde; kurulum → “Rehberde devam” | Yapıldı |
| **G3** | Görünüm / ürün / randevu / paylaş | Sohbet intent → mevcut `VixRexAction` | Yapıldı |
| **G4** | Hesap güvence | Sohbet → mevcut Auth (`openAuth` / `link_store_to_user`) | Yapıldı |
| **G5** | Furkan onayı → **tek commit** | Bozulma yok | Commit yok |

### Yasak (her adımda)

- İkinci chatbot, ikinci publish, ikinci GPS, ikinci router shell  
- Vitrinim / canlı önizleme / Keşfet→Düzenle akışını kırmak  
- Kart + sohbet için **iki ayrı öneri motoru** (tek kaynak: `VixRexGuidanceService`)

---

## 6. CURSOR / DİĞER AI İÇİN KISA EMİR

```
1) PROJECT_RULES + AGENTS + bu dosyayı oku
2) Şu anki güvenli adım = G0 Chrome test (Furkan) veya Keşfet/Instagram büyüme mesajları; G1–G4 bağlandı
3) Yeni md plan dosyası yaratma
4) Paralel yol açma — mevcut StoreEditor / Guidance / VixRexAction bağla
5) Küçük değişiklik → analyze/test → Türkçe kısa rapor
6) Commit yalnız Furkan “commit” deyince
```

---

## 7. FURKAN İÇİN TEK CÜMLE

Yayın şema hatası giderildi. Test sonra. Şimdi: asistan VixRex’te mevcut `ChatbotService` ile sohbet eder; aksiyonlar mevcut `VixRexAction` — ikinci sistem yok.
