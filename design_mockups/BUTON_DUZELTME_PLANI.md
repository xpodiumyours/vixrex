# Hero aksiyon butonları düzeltme planı

**Ekran:** `localhost:3000/v/sdene` — yeşil **Bilgi al**, **Yol tarifi**, küçük **IG**  
**Kapsam:** Sadece public Next hero aksiyonları (`VitrinProfileView`). Panel / Flutter yok.  
**Amaç:** Müşteri 1 saniyede neyin WhatsApp / Instagram / harita olduğunu anlasın.

---

## 1. Şu anki sorun (ekrandan)

| Buton | Şu an | Sorun |
|--------|--------|--------|
| WhatsApp | Yeşil metin: `Bilgi al` | WhatsApp markası / ikon yok; yeşil = WA bilinmiyor. `sdene` kategorisi **Diğer** → `whatsappButton: "Bilgi al"` (Butik etiketi `business_type`, profile girmiyor) |
| Instagram | Yuvarlak `IG` harfleri | Okunaksız, amatör; “Instagram” değil kısaltma |
| Yol tarifi | Metin-only pill | İşlev OK; ikon yok; hero’da `Yol tarifi` / altta `Yol tarifi al` tutarsız |

Bağlantılar (URL) büyük ihtimalle çalışıyor — sorun **görünür kimlik + etiket**.

---

## 2. Hedef görünüm (tek satır)

```
[🟢 WhatsApp ikonu  Ürün sor]   [◎ Yol tarifi]   …ikincil…
[◎ Instagram]  [Web] …
```

- Birincil satır: en fazla 3 aksiyon (profil `primaryActions`)
- İkincil satır: gerçek SVG ikonlar (metin kısaltma yok)

---

## 3. Kararlar (onaylı varsayılanlar)

### 3.1 WhatsApp
- **Etiket formatı:** `WhatsApp · {whatsappButton}`  
  Örnek: `WhatsApp · Ürün sor`, Diğer için `WhatsApp · Bilgi al`
- Solunda resmi WA glyph (basit SVG, harici paket yok)
- `target="_blank"` + `rel="noopener noreferrer"` (dış link)
- `aria-label`: tam metin

### 3.2 Instagram
- `IG` metni kalkar → Instagram glyph (SVG)
- `aria-label="Instagram"` / `title="Instagram"`
- İsteğe bağlı: ikon yanında hiç yazı yok (sadece ikon); erişilebilirlik aria ile

### 3.3 Yol tarifi
- Hero etiketi sabit: **Yol tarifi** (kısa)
- Connect bloğu da aynı: **Yol tarifi** (`… al` kaldırılır — tutarlılık)
- Solunda pin / yön SVG
- Harita dış link: `target="_blank"` + `rel="noopener noreferrer"`

### 3.4 Kategori yan etkisi (sdene)
`kategori=Diğer` + `business_type=Butik` → yanlış WA metni.  
Ayrı küçük fix (aynı PR veya hemen sonra):

- `resolveVitrinProfile`: `kategori` boş/`diger` ise `business_type` ile yeniden dene  
- Böylece Butik → `Ürün sor` / “Özel Tasarımlar”

---

## 4. Uygulama fazları

### Faz A–D — Uygulandı
- [x] `vitrinBrandIcons.tsx` (WA / IG / pin / globe)
- [x] `ActionButton` + `SocialIconLink` (dış link yeni sekme)
- [x] WhatsApp: ikon + `WhatsApp · {eylem}`
- [x] Instagram: marka ikonu (`IG` metni yok)
- [x] Yol tarifi: pin + tek etiket
- [x] `resolveVitrinProfile(kategori, businessType)` — Diğer+Butik → butik

### Faz E — Doğrulama (manuel)
1. `http://localhost:3000/v/sdene` — yeşilde WA ikonu + **WhatsApp · Ürün sor**  
2. Instagram ikonu tanınır  
3. Yol tarifi pin + Maps yeni sekme  
4. `tsc --noEmit` OK

---

## 5. Bilinçli dokunulmayanlar

- Connect altındaki metin linki “Instagram” (footer tarzı) — kalabilir  
- Google `G` / Yazı / Ref ikonları — aynı PR’da SVG’ye çekmek opsiyonel (kapsam şişmesin)  
- WhatsApp mesaj şablonu gövdesi (`page.tsx` `?text=`) — ayrı iş  

---

## 6. Onay (tek soru)

WhatsApp yazısı hangisi?
- **A)** `WhatsApp · {eylem}` — önerilen (marka + kategori eylemi)
- **B)** Sadece `WhatsApp` (eylem metni yok)
- **C)** Sadece `{eylem}` + ikon (şimdiki gibi metin, ama ikon ekle)
