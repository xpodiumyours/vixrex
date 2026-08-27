# Görev — blog ve randevu yönetim yüzeylerini gerçekten çalışır hâle getir

**Yazan:** Claude (27 Ağustos 2026, 18:30) · **Yürüten:** Freebuff · **Doğrulayan:** Claude

Bugün 18:06–18:22 arasında dört dosya yazıldı, hiçbiri commit edilmedi:

| Dosya | Durum |
|---|---|
| `public_web/src/app/api/articles/route.ts` | yeni (daldaki sürüm + `GET`) |
| `public_web/src/app/v/[slug]/blog-yonetim/page.tsx` | yeni |
| `public_web/src/app/api/appointments/route.ts` | yeni (daldaki sürümün **bozulmuş** kopyası) |
| `public_web/src/app/v/[slug]/randevu-yonetim/page.tsx` | yeni |

İş fikir olarak doğru. Ama **hiçbiri kullanıcının eline ulaşmıyor** ve
randevu tarafı çalışmıyor. Aşağıdaki maddeler koddan doğrulandı, tahmin yok.

---

## 0. ÖNCE BUNU YAP — dalla çakışıyorsun

`origin/feat/web-yazi-randevu-api` dalında **aynı üç dosya zaten var**
(`api/articles`, `api/appointments`, `tests/api/yazi-randevu-auth.test.ts`).
O dal 20 Ağustos'ta denetlendi, randevu rotasındaki ölümcül hata orada
düzeltildi. Sen dalın üstüne değil, **yanına** yazdın — düzeltme kayboldu
(bkz. madde 1).

Yapılacak:

1. `origin/feat/web-yazi-randevu-api` dalını güncel `main`'e taşı
   (`main`'den yalnız **4 commit** geride, dokunduğu dosya 3 tane —
   çakışma çıkmamalı).
2. Yerelde yazdığın dört dosyayı o dalın üstüne taşı. Sadece **gerçekten
   yeni olanı** kat: `articles` içindeki `GET` ve iki sayfa.
3. `appointments/route.ts` için **kendi sürümünü at, daldakini kullan.**

Yeni bir dal açma, yeni bir PR açma — bu dal zaten var.

---

## 1. Randevu onaylama HİÇ çalışmıyor (en ağır madde)

Senin yazdığın sürüm `respond_to_appointment` RPC'sini **yönetici
istemcisiyle** çağırıyor:

```ts
const admin = getSupabaseAdmin();
await admin.rpc("respond_to_appointment", { ... });
```

O RPC sahipliği şöyle kontrol ediyor
(`20260818070000_deploy_appointment_booking_system.sql:577`):

```sql
WHERE slug = v_appt.store_slug AND user_id = auth.uid()
```

Yönetici istemcisiyle çağrıldığında `auth.uid()` **boştur** → sahip
bulunamaz → her onay/ret/erteleme hata döner. Ekran açılır, liste gelir,
düğmeye basınca hiçbir şey olmaz.

Daldaki sürüm bunu zaten çözmüş, üstünde açıklaması da var:

> `// RPC auth.uid() istiyor — yönetici istemcisiyle çağrılamaz.`

ve kullanıcının kendi oturum anahtarıyla istemci kuruyor.

**Kural:** bir RPC'yi yönetici istemcisiyle çağırmadan önce gövdesini aç ve
`auth.uid()` geçiyor mu bak. Geçiyorsa yönetici istemcisi kullanılamaz.
Bu hata bu projede bugüne kadar **dört ayrı yerde** çıktı.

*Not: listeleme (`GET`) tarafında yönetici istemcisi doğru — orada RPC yok,
doğrudan tablo okunuyor ve `store_slug` süzgeci sahip çerezinden geliyor.
Aynısı ürün API'si için de geçerli, oraya dokunma.*

---

## 2. İki sayfa da açıldığında boş gelir — sahip çerezi kurulmuyor

Her iki API de `vixrex_owner_session` çerezine bakıyor. Ama o çerezi kuran
**tek yer** `/app` panosu (`app/page.tsx:70` civarı, `sahipOturumuAc`).
Çerez 30 dakikalık ve kayan.

Sonuç: kullanıcı `/v/<vitrin>/blog-yonetim` adresine panodan geçmeden
girerse ya da yarım saat sonra dönerse **401** alır. Ekran "Yazılar
yüklenemedi" der ve orada kalır — kendini toparlayamaz, girişe de atmaz.

Yapılacak: iki sayfa da ilk açılışta çerezi kendisi kursun. `app/page.tsx`
içindeki `sahipOturumuAc` fonksiyonu bunun tarifi — onu kopyalama, **ortak
bir yardımcıya taşı** ve üç yer de aynı yardımcıyı çağırsın.

401 dönerse: çerezi bir kez yenile, tekrar dene; yine olmazsa kullanıcıya
"Panodan gir" diyen gerçek bir çıkış yolu göster.

---

## 3. Sayfalara hiçbir yerden gidilemiyor

`blog-yonetim` ve `randevu-yonetim` adreslerine bağlantı veren tek bir
satır yok. Kullanıcı adresi elle yazmadan bu ekranları asla göremez.

Yapılacak: sahip panosuna (`/app`) her vitrin için iki giriş ekle.
Ürün yönetimi oradan nasıl açılıyorsa aynı yerde, aynı biçimde dursun.

---

## 4. Blog sayfasında Türkçe karakter yok

`blog-yonetim/page.tsx` kullanıcıya "Yazi Yonetimi", "Yeni Yazi Olustur",
"Vitrine Don", "Baglanti kurulamadi", "Henuz yaziniz yok" diyor.

Randevu sayfasını doğru yazmışsın ("Randevuları Yönet", "yüklenemedi") —
blog sayfası o seviyeye gelsin. Sitedeki her yüzey düzgün Türkçe.

---

## 5. Ölü `Authorization` başlığı

İki sayfa da isteklerde `Authorization: Bearer ...` gönderiyor, ama API'ler
o başlığı **hiç okumuyor** — yalnız çereze bakıyorlar. Sonraki okuyan
"demek ki oturum başlıkla taşınıyor" sanır.

Madde 1'i uygularken randevu `POST`'u bu başlığı gerçekten kullanacak.
Geri kalan yerlerde başlığı **sil**.

---

## 6. Test

Daldaki `public_web/tests/api/yazi-randevu-auth.test.ts` korunacak. Üstüne
şunlar eklenecek:

- Çerez yokken `GET /api/articles` **401** döner.
- Başka bir vitrinin adıyla çerez sunulursa **401** döner.
- Randevu `POST`'u yönetici istemcisiyle çağrılmaz — bunu bir sözleşme
  testiyle kilitle (kaynakta `getSupabaseAdmin().rpc("respond_to_appointment"`
  geçerse test kırılsın). Madde 1 üçüncü kez tekrarlanmasın.

---

## DUR VE SOR

Çerez yardımcısını üç yerde ortaklaştırırken (madde 2) ürün yönetimi
akışına da dokunuyorsun. **O akış şu an çalışıyor ve canlıda.** Ortak
yardımcıyı yazdıktan sonra ürün ekleme/silmeyi elle bir kez dene, sonucu
göster. Bozarsan sessizce bozulur — testler bunu yakalamıyor.

## Kapsam dışı

- Blog "güvenilir yazar / moderatör incelemesi" kuralı **hiçbir yerde
  uygulanmıyor** — uygulamada da yok, `is_blog_trusted` alanı okunmuyor.
  Eski ve ayrı bir eksik, bu görevde yok. Dokunma.
- Toplu ürün yükleme, profil/ayarlar sayfası — ayrı işler.

## Doğrulama

```
cd public_web && npm run lint && npm test && npm run build
```

Çıktıyı göster; "testler geçti" demen yetmez. GitHub'daki test kotası
1 Eylül'e kadar dolu, doğrulama yerelde yapılıyor.

## Çalışma kuralları

1. **Klasörde tek ajan.** 26 Ağustos'ta iki ajan birbirinin dosyasını ezdi.
2. `main` şu an **yeşil** (`de22f0b`). Kırmızı görürsen kendi değişikliğindendir.
3. PR sınırı 12 dosya / 600 satır. Bu iş sınırı aşarsa açıklamaya
   `Kapsam-Onay:` satırı gerekir — önce bana sor.
4. Geçici betikleri commit etme.
5. PR'ı `main`'e indirme işi Claude'da. Sen dalı hazırla, haber ver.
