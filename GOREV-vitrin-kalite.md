# GOREV: Kategori daraltma + urun karti kalitesi

Casper'in karari (2026-09-17). Uc adim, sirayla. Her adim ayri PR.

## MUTLAK YASAKLAR
- Hicbir kategori SILINMEZ. Hicbir vitrin YAYINDAN KALDIRILMAZ. Hicbir kayit silinmez.
- Elle sahte urun icerigi yazilmaz (beden/renk uydurmak yasak). Veri, esnaf formundan gecerek girilir.
- `lib/` altindaki Flutter paneli ELLE duzenlenmez. Uretilen dosya gerekiyorsa
  `dart run tool/business_categories_uret.dart` ile uretilir.
- Merge kapisi Casper'da. Taslak/WIP commit ana dala inmez.

## ZATEN OLCULDU — TEKRAR OLCME
- Kanonik kategori listesi: `shared/business_categories.json`, 19 kayit.
  Sozlesme: `order` alani satir sirasina esit olmak zorunda (validateBusinessCategoryContract).
- Listeyi okuyan yerler: kesfet/[kategori]/page.tsx (generateStaticParams + notFound),
  sitemap.xml/route.ts, components/kesfet/KategoriSeridi.tsx,
  components/landing/TemplateCatalog.tsx, lib/categoryTemplates.ts, lib/explore.ts.
- CI kapisi: .github/workflows/ci.yml:352 — JSON ile lib/config/business_categories.g.dart
  sapmasini reddeder.
- Flutter landing basliginda SABIT sayi var: lib/widgets/landing/landing_template_catalog.dart:364
  "12 farkli kategoride" — ve public_web/tests/landing-katalog-parite.test.ts bu sayiyi kilitliyor.
- Canli veri (2026-09-18): 9 kiralik vitrin, 6 kategoride (Butik, Giyim, Gida, Kafe/Lokanta, Kuafor, Teknik Servis).
  Adlandirma: kullaniciya gorunen ad **kiralik vitrin**; veritabani teknik isareti `is_demo`.
  Toplam 38 urun. 38'inin de TAM 1 fotografi var. Hepsinde metadata.attributes = [] (bos).
  Kullanilan kart sablonu sadece 3: fashion (butik), food (gida, kafe), service (kuafor, teknik, teknofix).
  Bos vitrinler (0 urun): demo-aymira-giyim, demo-lezzet-duragi, demo-nova-kuafor.
- Urun karti zinciri kodda BAGLI: OwnerProductManager.tsx -> OwnerRichProductFields ->
  api/products/route.ts -> productCardPresentation.ts -> urun/[productSlug]/page.tsx ->
  productStructuredData.ts. Flutter tarafi: widgets/product/product_rich_fields_editor.dart.
  DIKKAT: "bagli" olcumu import zinciri okunarak yapildi, EKRAN ACILIP DENENMEDI.

## ADIM 1 — Kategoriyi 6'ya indir (gizleyerek)
`shared/business_categories.json` icindeki 19 kaydin HEPSI kalir. Her kayda `aktif` alani eklenir.
- aktif = true: giyim, butik, gida, kafe_lokanta, kuafor, teknik_servis
- aktif = false: diger 13 kayit (diger dahil)

Kurallar:
- `order` numaralari DEGISMEZ (1-19 kesintisiz kalir) — mevcut testler boylece kirilmaz.
- Kullaniciya gorunen yuzeyler yalniz aktif olanlari listeler: Kesfet kategori seridi,
  landing sablon katalogu (kategoriSayisi de aktif sayisindan hesaplanir).
- Gorunmeyen ama CALISMAYA DEVAM EDEN yuzeyler: /kesfet/<kategori> adresleri (404 verilmeyecek),
  site haritasi, resolveBusinessCategory (asistan hala "eczaneyim" cumlesini cozebilmeli).
  Pasif kategori adresleri SEO icin ayakta kalir.
- Flutter g.dart ciktisi degismiyorsa dokunma; degisiyorsa yalniz ureticiyi calistir.
- Flutter'daki sabit "12 farkli kategoride" metni "6 farkli kategoride" olur; parite testi birlikte guncellenir.
- Yeni test: gorunur yuzeylerin yalniz aktif kategorileri listeledigini kanitla.

## ADIM 2 — Tekli urun ekleme formundaki eksigi kapat
Casper'in tarifi: esnafa kategoriye ozel bir LISTE sunulur, esnaf bilgiyi o listeye girer,
girilen bilgi urun kartina donusur.

Once OLC, sonra yaz:
1. Tekli urun ekleme akisini gercek ekranda ac (esnaf paneli, `/app/urunler` ve vitrin sahibi paneli).
2. Kategoriye ozel alanlar (OwnerRichProductFields) bu akista GERCEKTEN geliyor mu, yoksa yalniz
   duzenleme ekraninda mi var? Hangi halka kopuk, dosya ve satir vererek yaz.
3. Kopuk halkayi onar. Alan listesinin kaynagi `shared/product_attribute_schema.json` olacak,
   ikinci bir liste yazilmayacak.
4. Fotograf alani: kural 3-10 istiyor, bugun her uronde 1 foto var. Kurali YAYIN KAPISINDA uygula,
   tetikleyici/migration ile mevcut veriyi bloke etme.
5. Bittiginde TEK bir urunu bastan sona kendin gir ve ciktinin ekran goruntusunu rapora koy.

## ADIM 3 — Urun kartini profesyonellestir + 9 vitrini kiralanabilir kaliteye cikar
9 vitrin de YAYINDA KALIR. Kalite farki kapatilir.

Bilinen kirikliklar (Casper'in listesi):
- Rozetlerde kategori adi tasiyor: "BILGISAYAR & LA...", "ORGANIK SEBZE ..."
- Hizmet vitrinlerinde "6 Urun Listeleniyor" yaziyor; "hizmet" demeli.
- Her urunde tek fotograf var — **KAPANDI ama icerik bos cikti (2026-09-25 canli olcumu)**.
  DiKKAT: "182/182 urunde 3+ fotograf" sayisi dogru, icerik degil — her vitrinde 6 urunun
  TAMAMI ayni 3'lu gorsel dizisini paylasir (vitrin basina yalniz 3 farkli URL,
  `farkli_foto_seti = 1`). Uc vitrinde gorseller `category-templates/diger/` genel havuzundan;
  yani giyim vitrininde market reyonu fotografi gorunur. Kiralanabilir kalite icin ACIK IS.
- Urun kartlarinda ozellik satiri — **KAPANDI (2026-09-25 canliya uygulandi)**: 182/182 dolu.
  Oncesi 164 dolu / 18 bos'tu; bos olanlar uc vitrindeydi (demo-aymira-giyim, demo-lezzet-duragi,
  demo-nova-kuafor) ve sebebi o vitrinlerin 9 urun kategorisinin `product_template_key='generic'`
  olmasiydi. Uygulanan: supabase/migrations/20260925100000_kiralik_vitrin_urun_ozniteliklerini_tamamla.sql.
- Bos uc vitrin — **artik bos degil ve kart satiri canlida gorunuyor (2026-09-25)**:
  her birinde 6 urun, logo, telefon, il, SSS ve galeri var.
- Puan tekrari: **2026-09-25 canli olcumu 26 vitrinin 4.9 / 128 tasidigini gosterdi**
  (demo-* dortlu dahil); yalniz 4 vitrin tekil: kiralik-kuafor 4.9/187, kiralik-kafe 4.8/214,
  kiralik-gida 4.8/156, kiralik-teknik 4.7/93. Ayrica puan bandi 30 vitrinin hicbirinde acik degil
  (`show_storefront_rating = false`). **KAPANDI (2026-09-25 canliya uygulandi)**: 30 vitrinin
  30'u tekil puan cifti tasiyor, bant **30/30 acik**, `kiralik-butik` 4.9/128 olarak korundu.
  Uygulanan: supabase/migrations/20260925110000_kiralik_vitrin_puanlari.sql.
- Icerik, ADIM 2'de calisir hale gelen esnaf formundan GECIRILEREK girilir; dogrudan SQL ile degil.

## KAPILAR
Her PR oncesi yerelde `kapilar` (testler, tip kontrolu, lint, uretim derlemesi).
Merge sonrasi ana dali ve canliyi dogrula; test adresini raporda yaz.
