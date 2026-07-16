# Vixrex Asistan — Temiz İlerleme Planı

**Tarih:** 16 Temmuz 2026  
**Tek kaynak plan:** Bu dosya. Diğer `vixrex-asistan-*.md` / komple plan = arşiv/kaynak; çelişirse **bu dosya + HTML** kazanır.  
**UX tarzı (bağlayıcı):** [`vixrex-asistan-ornek.html`](vixrex-asistan-ornek.html)  
**Durum:** Plan hazır. Kod yok. Furkan “Dalga 1’e başla” demeden Flutter yazılmaz.

---

## 1. Ne istiyorsun? (kısa)

HTML’deki gibi konuşan Vixrex; detaya boğmadan.

- Kısa tanışma → onay  
- Ad + WhatsApp + konum (GPS veya yazı)  
- “Artık dijitalde varsın” + kolay profil + link (domain yok)  
- Hemen kapak şablonu teşviki  
- Sonra kullanıcı uygulamada kaldığı sürece yanında: ürün, randevu, paylaşım… **sıradaki özelliği konuşarak tanıtır**

**Tek asistan.** Ayrı yardım botu yok. Landing / badge / VixRex sekmesi aynı motorun kapılarıdır.

---

## 2. Kurallara uyum (sıkı)

| Kural | Bu planda |
|---|---|
| Paralel kayıt yolu yok | Yalnız `StoreEditorController` + `StorePublishService` |
| Hesap bağlama | Mevcut `link_store_to_user` (yeni RPC adı yok) |
| Misafir create | Geniş anon INSERT değil → security-definer RPC |
| Token | Publish ↔ Auth key hizası zorunlu |
| Dokunulmaz | Canlı önizleme, yerel kayıt, tema, tab, Keşfet akışı bozulmaz |
| Küçük iş | Dalga dalga; tek PR’da 40 özellik yok |
| Yeni defter yok | Bu dosya tek plan; `*_BORCU.md` açılmaz |

---

## 3. Kullanıcı filmi (HTML = doğru his)

```
Landing "Vixrex Oluştur"
  → Kısa: "Dijital vitrin oluşturmamı ister misin?"
  → Evet
  → Ad → WhatsApp → Konum (GPS)
  → Kısa yasal onay
  → "Artık dijitalde varsın" + profil + link
  → "Kapak şablonu seç" (zorlama yok)
  → (sürekli) sıradaki özellik tanıtımı…
```

Üslup: kısa cümle, teşvik, bir anda her şeyi sorma, esnaf temposu.

---

## 4. Özellik yolu (detaya boğulmadan)

Her adım aynı kalıp: **kısa tanıt → onay → yaptır → sonuç göster → sıradakini öner**

| Sıra | Ne | Mevcut ürün (yeniden yazma) |
|---|---|---|
| A | Varlık: ad, WA, konum, yayın, link | publish + edit_token |
| B | Kapak şablonu → galeri | kapak / gallery |
| C | Kısa açıklama | description |
| D | Ürün / hizmet → OCR / Excel tanıt | ürün + OCR + bulk |
| E | Randevu | booking |
| F | Duyuru / yazı | blog |
| G | Paylaşım: link, QR, WhatsApp | share |
| H | Hesabı güvenceye al | link_store_to_user |
| I | Büyüme: Instagram, Keşfet, SEO | mevcut özellikler |

SEO’nun 10 alt satırı planı şişirmez: I dalgasında “ürün/vitrin Google’da görünsün” diye konuşulur; teknik SSR zaten `public_web`.

---

## 5. Dalgalar (ilerleme)

Bir dalga bitmeden sonrakine geçilmez.  
Her dalga: HTML’de his (gerekirse) → Furkan onay → küçük kod → test → commit.

### Dalga 0 — Plan + HTML tarzı
- [x] HTML tarzı onaylandı (istediğin his bu)
- [x] Bu temiz plan
- [ ] Furkan: “Dalga 1 başla”

### Dalga 1 — Temel + Varlık (A)
1. Misafir create RPC + token key hizası  
2. Asistan ekranı / rota; Landing “Vixrex Oluştur” buraya  
3. Ad → WhatsApp → konum (GPS reuse) → kısa yasal → publish  
4. “Artık varsın” + link + domain yok  
5. Badge / sekme aynı asistana bağlanır (ayrı FAQ kalmaz)

**Kapı:** Misafir yayın + link görünür + girişte vitrin bağlanır.

### Dalga 2 — Görünüm (B) + anlatım (C)
Kapak şablonu, galeri teşviki, kısa açıklama, kalite çubuğu (mevcut guidance reuse).

### Dalga 3 — Katalog (D) = “sıradaki özellik”
Sohbetle ilk ürün; sonra OCR/Excel’i konuşarak tanıt (mevcut ekranı tetikle).

### Dalga 4 — Randevu + duyuru + paylaşım (E–G)

### Dalga 5 — Hesap + büyüme (H–I) + sürekli koç
Eksik olana göre “sıradaki özelliğin…” döngüsü kalıcı olur.

### Bilerek sonra
TTL, offline, puan/rozet, analytics, AutoVitrinBuilder (paralel StoreData yok).

---

## 6. Teknik iskelet (kısa)

**Dokunulacak (Dalga 1):**  
create RPC, `store_publish_service`, local token, `auth_screen`, asistan screen/service, `app_router`, `landing_screen`, badge/sekme bağlama.

**Reuse:**  
`LocationService`, `StorePublishValidator`, `VixRexGuidanceService` sırası, bubble/quick-reply UI parçaları, HTML tonu.

**Yasak:**  
Yeni publish API, yeni StoreData yolu, ikinci asistan/FAQ, geniş anon INSERT.

---

## 7. Doğrulama (Furkan gözü)

| # | Ne yaparsın | Ne görmelisin |
|---|---|---|
| 1 | Vixrex Oluştur | Kısa soru; form dump yok |
| 2 | 3 bilgi + GPS | Artık varsın + link |
| 3 | Kapak | Teşvik; atlanabilir |
| 4 | Sonra | “Ürün ekleyelim mi?” gibi sıradaki özellik |
| 5 | Badge / VixRex sekmesi | Aynı asistan |

Kod kapısı (Dalga 1): ilgili flutter test + analyze; adım adım test yönergesi görev bitince verilir.

---

## 8. Şimdi ne?

**Seçimin (1):** Dalga 1 — gerçek uygulama temeli (misafir create + varlık sohbeti).

Hazır olduğunda tek cümle yaz: **“Dalga 1 başla”**.  
O zamana kadar kod yok; HTML tarzı ve bu plan kilit.
