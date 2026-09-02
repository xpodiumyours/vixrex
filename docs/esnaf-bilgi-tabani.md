# Esnaf Bilgi Tabanı

Bu doküman, esnaf danışma isteğinde tarif edilen dört adımlı planın
**ikinci adımıdır**: "Vixrex 46 alanı biliyor" (`docs/vitrin-alan-semasi.md`)
bilgisinin üstüne, "esnaf nasıl bir işletme?" bilgisini ekler. Üçüncü adım
(`docs/alan-onem-eslemesi.md`) bu ikisini birleştirir.

## Kapsam kararı: 19 kategori, NACE altılı katmanı değil

Plan, Ticaret Bakanlığı'nın NACE Rev.2.1 altılı (6 haneli) esnaf/sanatkâr
meslek kolları listesini temel almayı öneriyordu. Bu liste **gerçekten var**
ve güncel:

- T.C. Ticaret Bakanlığı, Esnaf ve Sanatkârlar Genel Müdürlüğü — güncel liste sayfası: https://ticaret.gov.tr/esnaf-sanatkarlar/esnaf-ve-sanatkar-meslek-kollari/sektor-meslek-nace-listeleri/guncel-liste
- Aynı listenin duyurusu: https://esnafkoop.ticaret.gov.tr/haberler/esnaf-ve-sanatkarlarca-kullanilacak-sektor-meslek-nace-listesi-guncellendi
- TÜİK "NACE Rev.2.1-Altılı, 2026" sınıflama sunucusunda yayında; en son esnaf/sanatkâr listesi güncellemesi 29.01.2026 tarihli.

**Ama bu oturumda o listenin gerçek içeriğine ulaşamadım.** Bu ortamdaki ağ
politikası `ticaret.gov.tr`, `esnafkoop.ticaret.gov.tr` ve haber sitelerine
(`alomaliye.com` vb.) doğrudan erişimi engelliyor — yalnız arama sonucu
başlıkları görünüyor, sayfa içeriği veya xlsx dosyası çekilemiyor. Bu yüzden
NACE'nin 6 haneli kodlarını burada **uydurmadım** — yüzlerce koddan oluşan bir
listeyi hafızadan/tahminden yazmak, esnafın gerçek meslek koluyla eşleşmeyen
yanlış bir sınıflandırma üretir ve bu, boş bir alan kadar bile güvenilir
olmaz.

**Bu yüzden bu adım, planın kendi ilkesine geri döndü**: "Vixrex'in mevcut 19
kategorisini başlangıç kabul edeceğiz." 19 kategori zaten `shared/business_categories.json`
içinde kodun tek doğru kaynağı — üretken/hayali değil, gerçek. Aşağıdaki
bilgi tabanı bu 19 kategori + "Diğer" üzerine kurulu.

> **NACE katmanı nasıl eklenir (sonraki oturum için):** `isletmeTuru` alanı
> (`business_type` kolonu) zaten her kategorinin altındaki ince ayrımı tutmak
> için var (bkz. `docs/vitrin-alan-semasi.md` — "Kuaför" yerine "Erkek
> kuaförü" örneği). NACE altılı kodları, esnafın xlsx dosyası indirilip repoya
> eklenerek veya bu ortamda `ticaret.gov.tr` erişimi açılarak bu alanın
> serbest metnini kategoriye göre gruplanmış bir öneri listesine
> dönüştürebilir. Veri olmadan bu katman kurulamaz.

## Yöntem: 8 iş-modeli özniteliği

19 kategorinin her birini elle, kategori kategori "bu alan önemli/önemsiz"
diye yargılamak yerine — ki bu hem tutarsız hem denetlenemez olurdu — her
kategoriyi **8 iş-modeli özniteliğiyle** tanımladım. `docs/alan-onem-eslemesi.md`
bu öznitelikleri okuyup 46 alanın önemini kural ile hesaplıyor. Böylece
"neden kuaförde çalışma saatleri temel ama danışmanlıkta değil" sorusunun
her zaman izlenebilir bir cevabı var: rastgele bir seçim değil, "randevu
kritikliği yüksek" özniteliğinin sonucu.

| Öznitelik | Ne sorar | Hangi alanları etkiler |
|---|---|---|
| **A — Fiziksel ziyaret** (`evet`/`kismen`/`hayir`) | Müşteri işletmenin adresine mi geliyor? | adres, il, ilçe, mahalle, harita*, enlem/boylam, yol tarifi, konum metni |
| **B — Randevu kritikliği** (`yuksek`/`orta`/`dusuk`) | Saati kaçırmanın müşteri kaybına maliyeti ne kadar? | çalışma saatleri, telefon |
| **C — Sunum türü** (`urun`/`menu`/`hizmet`/`ders`/`karma`) | Vitrin bir ürün kataloğu mu, hizmet listesi mi? — `otomatikVitrinIcerik.ts`'teki gerçek `urunBolumBaslik` metinleriyle birebir | kısa tanıtım, ürün/kategori bölüm başlığı, e-posta, web sitesi, referans, SSS |
| **D — Güven ağırlığı** (`yuksek`/`orta`/`dusuk`) | "Kime emanet ediyorum" kararı ne kadar ağır? | hakkında metni/başlığı/görseli, referans, puan göster, SSS |
| **E — Görsel kanıt** (`yuksek`/`orta`/`dusuk`) | Önce/sonra veya ürün görünümü satışı ne kadar sürüklüyor? | kapak görseli, galeri (4 alan) |
| **F — Kampanya eğilimi** (`yuksek`/`orta`/`dusuk`) | Fiyat/indirim bandı bu sektörde işe yarar mı, yoksa güven mi kırar? | kampanya bandı (5 alan) |
| **G — Sosyal medya** (`yuksek`/`orta`/`dusuk`) | Instagram/sosyal kanıt kültürü ne kadar güçlü? | Instagram |
| **H — İçerik/SEO** (`yuksek`/`orta`/`dusuk`) | Blog/SSS uzmanlık kanıtı olarak ne kadar iş görür? | blog (2 alan) |

`C` sütunu keyfi değil — kodun kendisinden geliyor: `otomatikVitrinIcerik.ts`
içindeki `KATEGORIYE_OZEL_METIN` her kategori için `urunBolumBaslik`'i zaten
"Ürünlerimiz" / "Menümüz" / "Hizmetlerimiz" / "Derslerimiz" olarak
ayırıyordu; buradaki `C` o ayrımın birebir aynısı. `grup` sütunu da
`shared/business_categories.json`'daki gerçek `templateGroup` alanı.

## 19 kategori + Diğer — öznitelik tablosu

| Kategori | Grup | A · Ziyaret | B · Randevu | C · Sunum | D · Güven | E · Görsel | F · Kampanya | G · Sosyal | H · İçerik |
|---|---|---|---|---|---|---|---|---|---|
| Giyim | perakende | evet | orta | ürün | orta | yüksek | yüksek | yüksek | düşük |
| Butik | perakende | evet | orta | ürün | orta | yüksek | yüksek | yüksek | düşük |
| Gıda | gıda | evet | yüksek | ürün | orta | orta | yüksek | orta | düşük |
| Fırın | gıda | evet | yüksek | ürün | orta | orta | yüksek | orta | düşük |
| Kozmetik | perakende | evet | orta | ürün | orta | yüksek | yüksek | yüksek | orta |
| Dekorasyon | perakende | evet | orta | ürün | orta | yüksek | orta | yüksek | orta |
| Elektronik | perakende | evet | orta | ürün | orta | düşük | yüksek | düşük | orta |
| Kırtasiye | perakende | evet | orta | ürün | düşük | düşük | orta | düşük | düşük |
| Kafe / Lokanta | gıda | evet | yüksek | menü | orta | yüksek | yüksek | yüksek | orta |
| Kuaför | hizmet | evet | yüksek | hizmet | yüksek | yüksek | orta | yüksek | düşük |
| Teknik Servis | hizmet | evet | yüksek | hizmet | yüksek | orta | orta | düşük | orta |
| Danışmanlık | hizmet | kısmen | orta | hizmet | yüksek | düşük | düşük | düşük | yüksek |
| Eğitim | hizmet | kısmen | orta | ders | yüksek | düşük | orta | orta | yüksek |
| Ev Temizlik | hizmet | **hayır** | yüksek | hizmet | yüksek | yüksek | orta | düşük | düşük |
| Spor / Fitness | hizmet | evet | yüksek | hizmet | orta | orta | yüksek | yüksek | orta |
| Pet / Veteriner | perakende | evet | yüksek | karma | yüksek | orta | orta | orta | orta |
| Sağlık / Yaşam | hizmet | evet | yüksek | hizmet | yüksek | düşük | düşük | düşük | yüksek |
| Oto / Araç | hizmet | evet | yüksek | hizmet | yüksek | yüksek | orta | düşük | orta |
| Diğer | diğer | kısmen | orta | (belirsiz) | orta | orta | orta | orta | orta |

Dikkat çeken üç satır:

- **Ev Temizlik tek `A=hayır` kategori.** Hizmet müşterinin evinde/işyerinde
  veriliyor — işletmenin kendi adresi müşteri için önemsiz, ama "kime
  eve gireceğini emanet ediyorum" sorusu (`D=yüksek`) ve randevu saati
  (`B=yüksek`) hâlâ çok kritik.
- **Danışmanlık ve Eğitim `A=kısmen`.** Bazı görüşmeler/dersler uzaktan da
  olabilir — bu iki kategori NACE katmanı eklendiğinde muhtemelen en çok
  alt-ayrıma ihtiyaç duyacak (bir hukuk danışmanlığı ile bir masaj
  terapisti aynı `hizmet_danismanlik` kategorisinde ama çok farklı `A`
  değerine sahip olabilir).
- **Danışmanlık ve Sağlık/Yaşam `F=düşük`.** Bu iki sektörde indirim/kampanya
  bandı güven kırıcı algılanabilir — "%50 indirimli terapi" izlenimi iyi
  değil. Perakende ve gıda grubunda ise tam tersi: kampanya kültürü güçlü.

## Sonraki adım

`docs/alan-onem-eslemesi.md` bu tabloyu okuyup 46 alanın her biri için
19 kategoride ayrı ayrı önem hesaplıyor (temel / değerli / duruma bağlı /
ilgisiz) — planın üçüncü adımı.
