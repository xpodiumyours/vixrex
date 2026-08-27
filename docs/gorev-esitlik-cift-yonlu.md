# Görev — eşitlik testini çift yönlü yap

**Yazan:** Claude (27 Ağustos 2026) · **Yürüten:** Freebuff · **Doğrulayan:** Claude

Bu, `docs/gorev-web-uygulama-farklari.md` içindeki Görev 2'den **geriye kalan
tek parça**. Diğer maddeler 26 Ağustos'ta bitti, koddan doğrulandı:

- Görev 1 (arka plan parıltısı) — bitti
- Görev 2 metin kısmı — bitti, maskot balonu iki tarafta birebir aynı
- Görev 2 tarama kapsamı — bitti, `chatbot_badge.dart` artık taranıyor
  (`landingMetinleri.ts:64`)
- Görev 3 (hero form öneki) — bitti, `getSiteUrl()` üzerinden, dar ekranda
  `/v/` varyantı dahil
- Görev 4 (telefon mockup) — bitti, 19 istisna silindi

**Bu görev bitince o tarif kapanır.**

---

## Bugünkü eksik (koddan doğrulandı, 27 Ağustos)

`public_web/tests/landing-esitlik-contract.test.ts` dört iddia taşıyor ve
**dördü de tek yönlü**: Flutter'ı asıl kabul ediyor.

| Bugün yakalanan | Bugün KAÇAN |
|---|---|
| Flutter'a metin eklenip web'e eklenmezse | Web'e metin eklenip Flutter'a eklenmezse |

Casper'ın 26 Ağustos'taki isteği tam da kaçan yön: *"ileride APK geride
kalırsa testlerimizle eşitleriz"*. Bugünkü test bunu yakalamıyor.

## Yapılacak

**1.** Web landing bileşenlerinden kullanıcı metinlerini çıkaran bir tarayıcı
yaz. Kaynak: `public_web/src/components/landing/*.tsx`. Mevcut
`landingMetinleri.ts` içindeki Flutter çıkarıcısını örnek al — aynı dosyada,
aynı üslupta dursun.

**2.** Yeni iddia: web'de olup Flutter'da bulunmayan her metin ya Flutter'a
eklenmeli ya da **ayrı bir istisna listesine** gerekçesiyle yazılmalı.

**Liste ayrı olacak:** `landingEsitlikIstisnalariWeb.ts`. Mevcut
`landingEsitlikIstisnalari.ts` "Flutter'da var, web'de yok" listesidir;
ikisini karıştırırsan hangi yönün gerekçesi olduğu kaybolur.

**3.** Bayatlık kontrolü ters yön için de olsun: web istisna listesinde olup
web'de artık bulunmayan metin varsa test kırılsın.

## DUR VE SOR

Ters yönü ilk çalıştırdığında **çok sayıda metin dökülecek** — web'de Keşfet
dizini, kategori sayfaları, altbilgi gibi yalnız web'de olan yüzeyler var.
Bunların çoğu meşru istisna.

**Ama hepsini toptan istisnaya yazma.** Dökülen listeyi Casper'a ve bana
göster, birlikte bakalım. Toplu gerekçe ("web'e özel") kabul değil — aralarında
gerçek bir ayrışma gizlenmiş olabilir. **Bu noktada dur.**

## Kapsam dışı

- Landing'deki asistan sohbeti bir makettir, motora bağlanmaz.
  Kural: `VIXREX_RULES.md` §1.
- Keşfet sayfasının uygulamayla eşitliği ayrı bir iş, bu görevde yok.

## Doğrulama

```
cd public_web && npm run lint && npm test && npm run build
```

Çıktıyı göster; "testler geçti" demen yetmez.

## Çalışma kuralları

1. **Klasörde tek ajan.** OpenCode/Kilo aynı anda açık kalmasın — 26 Ağustos'ta
   iki ajan birbirinin dosyasını ezdi.
2. **main şu an YEŞİL** (`e3473ce`). Kırmızı görürsen kendi değişikliğindendir.
3. PR sınırı 12 dosya / 600 satır; bu iş çok altında kalmalı.
4. Geçici betikleri commit etme.
