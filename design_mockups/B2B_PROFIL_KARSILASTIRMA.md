# B2B profil / vitrin karşılaştırma araştırması

**Tarih:** 2026-07-25  
**Kapsam:** Müşteriye görünen profil (public `/v/[slug]`) + işletmeye sağlanan profil imkanları.  
**Rakip kümesi:** Google Business Profile · Linktree/Taplink (link-in-bio B2B) · WhatsApp-store / dijital kart (Debutap, VoidBE, WhatsMenu, TapVisit tipi).

---

## 1. Vixrex’te bugün ne var? (kod envanteri)

### Public profilde görünen
| Alan | Durum |
|------|--------|
| Kapak + logo + işletme adı | ✅ |
| Kategori / tip chip | ✅ (kısmen tutarsız: Diğer+Butik) |
| Açık / Kapalı | ✅ |
| Kısa açıklama / bio | ✅ |
| WhatsApp CTA (ön doldurulmuş mesaj) | ✅ |
| Yol tarifi (Maps) | ✅ |
| Instagram | ✅ |
| Web / referans / Google yorum linki | ✅ |
| Ürün kataloğu + kategori filtre | ✅ |
| Ürün detay sayfası | ✅ |
| Randevu akışı (`/randevu`) | ✅ (ayar açıksa) |
| Yazılar | ✅ |
| Galeri + kurumsal hikâye | ✅ |
| QR + paylaş linki + vCard | ✅ |
| Pazaryeri linkleri | ✅ |
| SEO JSON-LD | ✅ |
| Kategoriye özel metin / CTA | ✅ (yeni) |

### Panelden yapılandırılabilen (profile yansıyan)
WhatsApp, Instagram, web, adres/konum, Google Business link, kapak/logo, galeri, ürünler, marketplace, referans, yayın, randevu ayarı, kategori, açıklama/bio, açık-kapalı, çalışma saatleri (DB’de var).

---

## 2. Rakip platformların işletmeye verdiği tipik imkanlar

### A) Google Business Profile (yerel keşif standardı)
Saatler · foto/video · yorumlar & yanıt · Q&A · yayın/teklif · menü/hizmet listesi · arama/harita görünürlüğü · rezervasyon entegrasyonu · performans analitikleri · mesajlaşma.

### B) Linktree / Taplink (tek link + dönüşüm)
Sınırsız link blokları · form / e-posta toplama · analitik (tıklama, cihaz, kaynak) · özel domain · ödeme / dijital ürün (Taplink daha güçlü) · randevu/form · tema/şablon bolluğu · marka kaldırma (ücretli).

### C) WhatsApp-store / dijital kart (Debutap, VoidBE, WhatsMenu, ShopyCard…)
Katalog + **sepet/sipariş → WhatsApp** · ödeme (UPI/Stripe/iyzico tipi) · randevu takvimi · NFC/QR kart · **ziyaretçi analitiği** · çalışma saatleri · testimonial · PWA “ana ekrana ekle” · kupon / stok / varyant (ileri seviye).

---

## 3. Karşılaştırma matrisi (profil deneyimi)

| Özellik | GBP | Linktree/Taplink | WA-store kartlar | **Vixrex** | Not |
|---------|-----|------------------|------------------|------------|-----|
| Tek paylaşılabilir link + QR | △ | ✅ | ✅ | ✅ | Güçlü alan |
| vCard / rehbere ekle | △ | △ | ✅ | ✅ | İyi |
| WhatsApp birincil CTA | △ | ✅ | ✅ | ✅ | İyi |
| Ürün katalog vitrini | △ | △ | ✅ | ✅ | İyi |
| Üründen WhatsApp sipariş bağlamı | — | △ | ✅ | △ | Ürün sayfasında kısmi; sepet yok |
| Sepet / ödeme | — | ✅/△ | ✅ | ❌ | Eksik |
| Randevu | ✅* | △ | ✅ | ✅ | Var; hatırlatma/CRM zayıf |
| Çalışma saatleri (müşteri görünür) | ✅ | ✅ | ✅ | ⚠️ | DB var, UI çoğu zaman boş |
| Yorum / puan / testimonial | ✅ | △ | ✅ | ❌ | Sadece Google linki |
| Yayın / kampanya / teklif | ✅ | ✅ | △ | ❌ | Yok |
| SSS / Q&A | ✅ | △ | △ | ❌ | Yok |
| Video (hero/ürün) | ✅ | ✅ | △ | ❌ | Yok |
| Ziyaretçi analitiği (işletmeye) | ✅ | ✅ | ✅ | ❌ | Kritik B2B eksik |
| Özel domain | — | ✅ | ✅ | ❌ | Eksik |
| Form / lead yakalama | △ | ✅ | ✅ | ❌ | Sadece WA |
| Telefon ara (tel:) | ✅ | ✅ | ✅ | ❌ | WA’ya bağımlı |
| Sticky mobil CTA | — | ✅ | ✅ | ❌ | UX zayıf nokta |
| Menü PDF / QR masa menü | △ | — | ✅ | ❌ | Kafe için |
| NFC fiziksel kart | — | — | ✅ | ❌ | Opsiyonel |
| Çok dil | △ | ✅ | △ | ❌ | — |
| PWA ana ekran | — | △ | ✅ | ❌ | — |

\* = entegrasyonla

---

## 4. Profilde “düzgün değil” (kalite / bug)

1. **Çalışma saatleri görünmüyor** — `working_hours` obje; gösterim sadece string. Rakiplerde saatler güven unsuru.
2. **Kategori chip karmaşası** — panelde `Diğer` + `Butik`; müşteri güveni zedelenir.
3. **Ürün görseli boş** — “görsel bekleniyor” / panelden fatura UI sızıntısı hissi; rakip kataloglar görsel zorunlu hissi verir.
4. **WA mesajı jenerik** — ürün bazlı “X ürünü soruyorum” her yerde tutarlı değil.
5. **Google Business ikonu = pin** — Yol tarifi ile karışır.
6. **Açık/Kapalı manuel** — GBP’de saate göre otomatik; Vixrex’te saat yoksa güven zayıf.
7. **Alt sayfa tipografi tutarsız** — ürün/yazı hâlâ eski display font.
8. **Connect her zaman şişkin** — adres/WA yoksa boş his.
9. **QR harici servis** — `api.qrserver.com` bağımlılığı (yavaş/kırılgan).

---

## 5. Profilde “eksik” (B2B öncelik sırası)

### P0 — müşteri güveni / dönüşüm (hemen sonraki sprint adayları)
1. Çalışma saatlerini doğru göster + (opsiyonel) saate göre Açık/Kapalı  
2. Telefon **Ara** butonu (`tel:`)  
3. Ürün CTA: “WhatsApp’tan bu ürünü sor” (ürün adı gömülü)  
4. Basit **işletme analitikleri** (görüntülenme, WA tıklama, yol tarifi) — B2B satış argümanı

### P1 — rekabet paritesi
5. Yorumlar: Google puan özeti veya manuel testimonial bloğu  
6. Kampanya / “bu hafta” bandı (tek satır teklif)  
7. Sticky mobil WA çubuğu  
8. Lead formu (isim + telefon → panel)

### P2 — kategori derinliği
9. Kafe: menü PDF / “bugünün menüsü”  
10. Hizmet: paket fiyat kartları netliği  
11. Video kapak veya galeri videosu  
12. Özel domain (`firma.com` → vitrin)

### P3 — commerce (bilinçli ürün kararı)
13. Sepet + ödeme (iyzico/Stripe) — WA-store rakiplerle direkt rekabet; büyük kapsam  
14. Stok/varyant/kupon  

---

## 6. Vixrex’in görece güçlü olduğu yerler

- **Kategoriye özel vitrin dili** (giyim ≠ kuaför ≠ kafe) — çoğu link-in-bio jenerik.  
- **Randevu + katalog + yazı** aynı shell’de — Linktree’den daha “işletme sitesi”.  
- **Türkiye odaklı WA-first** — doğru pazar.  
- **SEO JSON-LD + yayınlı slug** — GBP değil ama kendi linki için iyi temel.

---

## 7. Stratejik okuma (tek cümle)

Vixrex bugün “güzel WA vitrin + katalog + randevu” seviyesinde; B2B rakiplerin işletmeye sattığı şey ise **güven (saat/yorum) + ölçüm (analitik) + sipariş yolu (ürün→WA/sepet)**. Eksikler çoğunlukla UI süsü değil, işletmenin “işe yarıyor mu?” sorusuna cevap veren katmanlar.

---

## 8. Önerilen sonraki adım

Kullanıcı onayıyla **P0 paketi** (saatler + Ara + ürün WA metni + basit analitik) ayrı cerrahi plan; commerce’i (sepet) şimdilik ayır.
