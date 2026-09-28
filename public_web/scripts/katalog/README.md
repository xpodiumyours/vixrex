# Ürün Havuzu Toplayıcısı

Firma havuzundaki (Excel) firmaların **ürünlerini** kendi sitelerinden toplar ve
tek standart biçimde `public_web/data/katalog/` altına yazar.

Amaç: faturadaki ürün kodu, gerçek ürün adına ve fotoğrafına bağlanabilsin.

**Maliyet sıfırdır ve OpenAI anahtarı gerekmez.** Yalnız herkese açık ürün
verisi okunur.

---

## Komutlar

```bash
# 1) Excel'deki firmaları listeye çevir (bir kez, ya da Excel değişince)
node scripts/katalog/firmalar-uret.mjs

# 2) Tüm firmaları tara (otomatik okuyucular)
node scripts/katalog/tara.mjs --paralel=5

# Yalnız belirli firmalar
node scripts/katalog/tara.mjs --firma=seher-mensucat,kinzi-toptan

# Yavaş okuyucuyu yalnız elle çalıştır (site haritası + sayfa içi veri)
node scripts/katalog/tara.mjs --platform=jsonld --paralel=6 --firma=voltaj,saphori

# Deneme: dosya YAZMAZ
node scripts/katalog/tara.mjs --sinir-urun=20 --firma=voltaj

# Kurallar değişince eldeki katalogları ağa çıkmadan yeniden yaz
node scripts/katalog/sikistir.mjs
```

| Seçenek | Ne yapar |
|---|---|
| `--platform=X` | Yalnız X okuyucusunu dener (platform tespiti atlanır) |
| `--firma=a,b` | Yalnız bu firmalar (anahtarlar `firmalar.json`'dan) |
| `--sinir-urun=N` | Firma başına en çok N sayfa okur. **Örnek çalıştırmadır: dosya yazmaz** |
| `--paralel=N` | Aynı anda N firma. Nezaket kuralı site başına olduğu için güvenli |
| `--kuru` | Hiç dosya yazmaz |
| `--sinir=N` | Listeden yalnız ilk N firmayı alır |

Sonuç: `scripts/katalog/rapor.json` (ölçülen sayılar) ve ekrana tablo.

---

## Dosya düzeni

```
scripts/katalog/
  _ortak.mjs          indirme, nezaket, robots, normalleştirme, yazma, rapor
  firmalar-uret.mjs   Excel → firmalar.json
  firmalar.json       firma listesi + tespit edilen platform + izin
  tara.mjs            ana komut
  sikistir.mjs        eldeki katalogları yeniden yazar (ağa çıkmaz)
  rapor.json          son taramanın ölçüm raporu
  platformlar/
    woocommerce.mjs   standart ürün adresi olan platform
    shopify.mjs       standart ürün adresi olan platform
    jsonld.mjs        site haritası + JSON-LD/microdata (elle çalışır)
```

Yeni okuyucu eklemek = `platformlar/` altına bir dosya koymak. `tara.mjs`
klasörü kendisi okur.

---

## Okuyucular ve ölçülen kapsam

| Okuyucu | Nasıl okur | Ölçülen durum |
|---|---|---|
| `woocommerce` | `/wp-json/wc/store/v1/products` | 16 firma; 9'u açık, 7'si uç noktayı kapatmış |
| `shopify` | `/products.json` | 3 firma; 2'si açık |
| `jsonld` | `sitemap.xml` → ürün sayfası → JSON-LD `Product`, yoksa microdata | İkas, Ticimax, T-Soft, İdeasoft'ta çalıştı |

`jsonld` **otomatik denenmez**: her ürün için ayrı sayfa okur, yani diğerlerinden
çok yavaştır. Yalnız `--platform=jsonld` ile çalışır.

---

## Değişmeyen kurallar

1. **Kod yoksa ürün alınmaz.** Kodsuz ürün faturayla eşleşemez; sayısı raporda
   `kodsuz` sütununda açıkça gösterilir.
2. **Tahmin yok.** Barkod yalnız 8-14 haneli sayıysa barkod sayılır. `46003L`
   gibi model kodları barkod yerine geçmez.
3. **Sessiz atlama yok.** Ulaşılamayan site, engelli site, kodu olmayan ürün,
   sınıra takılan katalog — hepsi raporda ayrı görünür.
4. **Nezaket.** Site başına istekler aralıklı gönderilir, `robots.txt` okunur,
   engelleyen site zorlanmaz.
5. **Örnek çalıştırma yazmaz.** `--sinir-urun` verildiğinde hiçbir dosya
   yazılmaz; yarım veri havuza girmez.

---

## Sık yapılan hata

**Dosya adı ile firma anahtarı tutmalıdır.** `data/katalog/uretici-katalog-<anahtar>.json`
dosyasındaki `<anahtar>`, `src/lib/ureticiKatalog.ts` içindeki firma satırının
`anahtar` alanıyla **birebir aynı** olmalıdır. Tutmazsa koca bir katalog sessizce
eşleştirme dışı kalır (bir kez yaşandı: `seher` ↔ `seher-mensucat`).

Bu yüzden modül, karşılığı olmayan dosyayı yüklerken konsola açık uyarı yazar ve
`tests/api/uretici-katalog.test.ts` bu hizalamayı ayrıca denetler.
