# Görev — kalıcı hesap sahipliğini iki "cihazda" doğrula

**Yazan:** Claude (27 Ağustos 2026) · **Yürüten:** ücretsiz model (OpenCode)
**Tür:** TEST — kod değişikliği YOK, commit YOK, PR YOK. Çıktı bir rapor.

## Neden

26 Ağustos'ta VIXREX CORE canlıya çıktı: vitrin artık kalıcı hesaba bağlanıyor,
hesap başına tek vitrin kuralı var, yeni cihazda açılış `bootstrap_owner_state`
ile yapılıyor. **Bu akış hiç uçtan uca denenmedi.** Migration canlıda, kod
main'de, ama "gerçekten çalışıyor mu" sorusunun cevabı yok.

Ölçülen tarihsel durum: canlıda 29 vitrin vardı, `user_id` dolu olan **0**.
Sahiplenme bugüne kadar hiç çalışmamıştı. Onarım yapıldı; kanıt eksik.

## İki "cihaz" nasıl kurulur

Gerçek telefon gerekmiyor. Uygulamanın web sürümü yayında ve iki **izole
tarayıcı bağlamı** iki ayrı cihaz sayılır — çerez ve yerel depolama
paylaşılmaz.

- Uygulama: `https://vixrex-app.vercel.app`
- Vitrin/Keşfet: `https://vixrex-public.vercel.app`

Playwright ile:

```js
const tarayici = await chromium.launch();
const cihazA = await tarayici.newContext();   // ayrı depolama
const cihazB = await tarayici.newContext();   // ayrı depolama
```

**İki `newContext()` şart.** Aynı bağlamda iki sekme açmak testi geçersiz
kılar — depolama paylaşılır, "yeni cihaz" davranışı hiç sınanmaz.

## Senaryo

**Hazırlık.** Atılabilir bir e-posta ile YENİ bir hesap aç. Var olan hesabını
kullanma: hesap başına tek vitrin kuralı yüzünden zaten vitrini olan bir
hesapla kiralama `ALREADY_OWNS_STORE` döner ve test yanlış yerden düşer.

**Cihaz A**
1. Uygulamayı aç, yeni hesapla giriş yap.
2. Keşfet'e git, kiralanabilir bir demo vitrin seç, **Kirala**.
3. Kaydet ve raporla: dönen `slug`, ekranda görünen mesaj, ekran görüntüsü.

**Cihaz B — asıl sınav**
4. Tamamen ayrı bağlamda uygulamayı aç.
5. **Aynı hesapla** giriş yap.
6. Uygulama, A'da kiralanan vitrini **kendiliğinden göstermeli.**

Doğrulanacak: vitrinin adı ve slug'ı A'dakiyle aynı mı? Kullanıcıdan hiçbir
kod/link istenmeden geldi mi?

**Negatif sınav (aynı derecede önemli)**
7. Cihaz B'de, aynı hesapla ikinci bir demo vitrin kiralamayı dene.
8. Beklenen: **`ALREADY_OWNS_STORE`** — "Bu hesabın zaten bir vitrini var."
   Bu bir hata değil, kuralın çalıştığının kanıtı. Uygulamanın bunu bir hata
   ekranı gibi değil, anlaşılır bir mesajla göstermesi gerekiyor; nasıl
   gösterdiğini ekran görüntüsüyle raporla.

**Anonim sınavı**
9. Üçüncü, giriş YAPILMAMIŞ bir bağlamda kiralamayı dene.
10. Beklenen: `ANONYMOUS_SESSION` ya da misafir yoluna düşme — hesaplı yol
    çalışmamalı.

## Raporlanacaklar

Her adım için: ne yaptın, ne gördün, ekran görüntüsü. Ayrıca:

- A'da dönen slug, B'de görünen slug — **aynı mı?**
- B'de vitrin gelene kadar kaç saniye geçti?
- Herhangi bir adımda hata mesajı, boş ekran ya da sonsuz yükleme oldu mu?
- Tarayıcı konsolunda hata var mı?

**Beklenen sonuç kodları:** `RENTED` (başarılı kiralama),
`ALREADY_OWNS_STORE`, `ANONYMOUS_SESSION`. Bunların dışında bir kod
görürsen (`RATE_LIMITED`, `SOURCE_NOT_FOUND`, `SLUG_GENERATION_FAILED`,
`ERROR`) olduğu gibi raporla, yorumlama.

## Sınırlar — bunlara uy

1. **Kod değiştirme, commit etme, PR açma.** Bu bir ölçüm görevi.
2. **Canlı veritabanına yazıyorsun.** Test hesabı atılabilir olsun, gerçek
   müşteri vitrinlerine dokunma. Kiralanan demo kopyalar 30 saatte kendini
   siliyor, ayrıca temizlik yapma.
3. Bir şey **çalışmıyorsa düzeltmeye kalkma** — raporla, dur.
4. "Testler geçti" gibi özet yazma; **ne gördüğünü** yaz ve görüntüyü ekle.

## Bilinmesi gereken kısıt

Bu test uygulamanın **web** sürümünde koşuyor. APK'da anahtarlar
`flutter_secure_storage`'da tutuluyor, tarayıcıda başka yerde. Yani bu test
akışın mantığını kanıtlar, APK'daki depolama davranışını kanıtlamaz. Raporun
sonuna bu cümleyi aynen ekle ki sonuç fazla okunmasın.
