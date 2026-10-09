# Fatura fotoğrafından ürün kartı — 7 Ekim 2026

**2026-10-09 Casper kararı:** Üretici ürün havuzu yok. `public_web/data/katalog` geri getirilmez. Ürün firmanın kendi sitesinden bulunur. Gerçek fatura en sonda bakılır.

Bu dosya 7 Ekim planıdır. 30 Eylül belgesi (`docs/FATURADAN-VITRINE-MASTER-PLAN.md`) tarihsel kayıttır; iş listesi değildir. Aşağıdaki dilim/dal satırları 7 Ekim'dir; havuz kararı onları geçersiz kılar.

Dilim 1–4 bu dalda yazıldı. Dilim 5 önceden koddaydı: stok onayı olmadan, faturadaki adet varsa satır yayınlanır. Açık dal `fatura/kart-kaynagi`. Ana dal `origin/main`. Canlıya alınmadı. Birleştirme ve canlı ayrı karardır.

## Mümkün mü

Üreticinin kendi sitesinde o ürünün açık sayfası ve fotoğrafı varsa, kartın görseli oradan gelir. Çizim yok.

Sayfa veya fotoğraf yoksa o satırın kartı faturadaki gerçek bilgilerle kurulur, görselsiz kalır. Başka siteden, pazaryerinden veya modelin uydurduğu adresten fotoğraf konmaz. Bu eksik, akışı durdurmaz; diğer satırlar yürür.

## Hedef

VixRex, üretici ile küçük esnaf arasında köprü, küçük esnaf ile tüketici arasında vitrindir.

Esnaf fatura fotoğrafını yükler. Karttaki ad, kod, barkod, marka, renk, beden, adet ve alış fiyatı faturada yazan değerdir. Karttaki fotoğraf ve site açıklaması, yalnız o firmanın kendi sitesindeki eşleşen sayfadan gelir. Esnaf satış fiyatını yazar ve onaylar. Satış fiyatını model doldurmaz.

## Ölçülen bugün

Ana dalda okuyucu OpenRouter sohbet ucuna gider (`openai/gpt-5.6-luna`). Ürün fotoğrafı ve site açıklaması istemez.

Bu dalda okuyucu doğrudan OpenAI cevap ucuna gider. Model `gpt-5.6-luna`. Tek istekte hem faturayı okur hem açık web’de arar (`public_web/src/lib/faturaGoru.ts` 261–290).

Hedefe uymayan yerler:

- Fotoğraf, isteğe girmeden uzun kenarı 2048 piksele indirilir ve `detail: "high"` gider (`faturaGoru.ts` 30, 186–203, 286). Resmi görüntü rehberi, fatura okuma gibi ince yazı için `detail: "original"` der. Luna’da `original` boyutu korur. `high` 2048 kutu ve 2.500 yamadır. Kaynak: https://developers.openai.com/api/docs/guides/images-vision
- Arama, firmanın sitesine kilitli değil. Esnafın yazdığı site, Luna çağrısına girmez; kayda yazılır (`fatura-oku/route.ts` 77, 201).
- Modelin kendi yazdığı fotoğraf adresi kabul edilir. Arama resmi boş satıra liste sırasıyla yapışır (`faturaGoru.ts` 221–250). Ürün adıyla eşleşme yoktur.
- İndirilemeyen adres okuma anında elenir (`faturaGorsel.ts` 168–177). `erisilemedi` red listesinde değildir.
- Üç metin doluysa satır kanıtlı sayılır (`faturaEslestir.ts` 90–110). Sayfanın kendisi okunup açıklama oradan alınmaz.
- Akıl yürütme `none` iken web araması açıktır (`faturaGoru.ts` 270–271). Resmi tablo aramayı `low` satırına yazar. Kaynak: https://developers.openai.com/api/docs/guides/reasoning
- Maliyet hesabı yalnız jetonu sayar (`faturaGoru.ts` 181–184). Resmi fiyat: web arama ve görüntü araması, 1.000 çağrıda 10 dolar, artı jeton. Kaynak: https://developers.openai.com/api/docs/pricing
- Günlük tavan vitrin başına 1 dolardır (`faturaMaliyet.ts` 4). Arama ücreti bu tavana yazılmaz.
- Firma sitesini bulan kod duruyor (`firmaArama.ts`, `firmaSitesiniAra`) ama bu daldaki fatura okuma ucu onu çağırmaz.
- Tek ürün fotoğrafı kapısı (`fotografUrunCikar.ts`) fatura yolu değildir. OpenRouter’a gider. Bu plana dahil değildir.

Resmi ve kodda örtüşen parçalar: model `gpt-5.6-luna`, katı JSON şema, `web_search`, `search_content_types` içinde `image` ve `text`, `include: web_search_call.results`, `image_result` alanları `image_url` ve `source_website_url`, jeton fiyatı girdi 0,20 / önbellekli girdi 0,02 / çıktı 1,20 dolar (kısa bağlam). Site kilidi için resmi alan `filters.allowed_domains` (en fazla 100 alan, alt alan adları dahil). Kaynak: https://developers.openai.com/api/docs/guides/tools-web-search ve https://developers.openai.com/api/docs/models/gpt-5.6-luna

Aynı çağrıda metin ve görüntü aramasının tek ücret mi iki ücret mi yazdığı cümle bulunamadı. Tavan hesabı, bulunana kadar çağrı başına iki ücret ayırır.

## Olması gereken akış

1. **Faturayı oku.** Tek Luna çağrısı. Araç yok. Akıl yürütme `none`. Görüntü `original`. Şemada yalnız belgede yazan alanlar: tedarikçi, vergi no, adres, sitede yazıyorsa site, belge, satır (ham satır, model, ad, barkod, renk, beden, marka, adet, birim fiyat, tutar, toplamlar). Site açıklaması ve fotoğraf adresi bu çağrıda yoktur. Satır toplamı belgeden 5 kuruştan fazla saparsa okuma durur. Bu kapı duruyor (`faturaSatirAyikla.ts` 295).
2. **Firmanın sitesini kilitle.** Sıra: faturada yazan site, esnafın yazdığı site, yoksa mevcut `firmaSitesiniAra`. Adres firmanın kendi sitesi değilse (pazaryeri, sosyal ağ) elenir; bu eleme `firmaArama.ts` içinde duruyor. Site doğrulanamazsa görsel araması yapılmaz.
3. **Her satır için o sitede ara.** Ayrı Luna çağrısı. Akıl yürütme `low`. Araç: `web_search`, türler `text` ve `image`, `filters.allowed_domains` yalnız o firmanın alan adı, `include: web_search_call.results`. Sorgu o satırın kodu, adı ve barkodudur. Sonuç, başka satıra kaydırılmaz.
4. **Sayfayı doğrula.** Kabul: `source_website_url` o firmanın alan adında (alt alan adı sayılır). Fotoğraf adresi teslimat ağı olabilir; sayfa firmanın sitesindeyse bu yeter. Adres indirilir. Kısa kenar 1200 pikselin altı, logo, boş görüntü ve aşırı en-boy reddedilir. İndirilemeyen adres de reddedilir. Açıklama, indirilen sayfanın metninden alınır; modelin cümlesi açıklama olmaz. Sayfa o satırın kodunu veya adını taşımıyorsa görsel ve açıklama boş kalır.
5. **Kart taslağı.** Ad, kod, barkod, marka, renk, beden, adet ve alış fiyatı faturadan. Fotoğraf ve açıklama yalnız 4. adım geçtiyse. Satış fiyatı boş. Esnaf fiyatı yazar ve onaylar. Adet faturadaki adettir; stoğu ayrıca sordurmaz. Mevcut yayın kapısı stok onayını da soruyor (`products/batch/route.ts` 326–335). Bu kapı hedefe göre kalkar.
6. **Yayın.** Onay ve satış fiyatı varken kart mevcut ürün kaydına yazılır. Görsel depoya kopyalanır (`kaynakGorselleriniHazirla`). Kaynak sayfanın linki esnaf ekranında tıklanır kalır. Tüketici vitrinine teknik kanıt alanı eklenmez. Görsel izi mevcut izin kaydında durur.

## Dokunulacaklar

- `public_web/src/lib/faturaGoru.ts` — okuma isteği ile site arama isteği ayrılır. Sıralı görsel yapıştırma kalkar.
- `public_web/src/app/api/fatura-oku/route.ts` — site kilidi ve satır araması buradan yürür. Esnafın site ipucu aramaya girer.
- `public_web/src/lib/faturaEslestir.ts` — `siteKartiniUygula` yalnız doğrulanmış sayfa ve görselle kanıtlar.
- `public_web/src/lib/faturaGorsel.ts` — indirilemeyen adres boş döner.
- `public_web/src/lib/faturaMaliyet.ts` — arama çağrısı tavan hesabına girer. 1 dolar dolunca yeni arama yapılmaz; okunan fatura görselsiz satırlarla kalır.
- `public_web/src/app/api/products/batch/route.ts` — fatura satırında stok sorusu kalkar; adet belgeden gelir.
- Bu dosyaların testleri, yeni isteğin gövdesini ölçer.

## Dokunulmayacaklar

- Çizim, görüntü üretim aracı, Images API.
- `fotografUrunCikar.ts` ve `/api/fotograf-urun-cikar`.
- Ana dal, canlı, veritabanı şeması. Yeni tablo yok.
- Üretici havuzunu ikinci bir fotoğraf kaynağı yapmak. Havuzdaki adres de 4. adımdan geçmeden karta girmez.
- Esnafa açıklama veya görsel aratmak.

## Sıra

Kod, bu listenin başından ve yalnız onaylanan dilimle değişir. Dilim bitmeden sonrakine geçilmez.

1. Okuma çağrısını aramadan ayır. `original`. Fatura şemasından site fotoğrafı ve açıklama alanlarını çıkar.
2. Site kilidini bağla. Site yoksa arama yok.
3. Satır başına kilitli arama. Yanlış satıra görsel yapışmaz. Modelin yazdığı adres kabul edilmez.
4. Sayfa metninden açıklama. İndirilemeyen adresi ele. Arama ücretini 1 dolar tavana yaz.
5. Yayın kapısından stok sorusunu kaldır. Satış fiyatı ve onay kalsın.

Her dilimden sonra test. Canlı veri ile önizleme, ana dala alma kararı ayrıca verilir.
