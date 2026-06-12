# VitrinX Google Play Hazirlik Notu

Son guncelleme: 12 Haziran 2026

## Android Kimligi

- Uygulama adi: VitrinX
- Urun sahibi: Xpodiumyours
- Paket adi: `com.xpodiumyours.vitrinx`
- Privacy Policy URL: `https://vitrinx.app/privacy`
- Terms URL: `https://vitrinx.app/terms`
- Data Deletion URL: `https://vitrinx.app/data-deletion`
- Iletisim: `privacy@vitrinx.app`

## Data Safety Taslagi

VitrinX su veri turlerini isleyebilir:

- Hesap bilgisi: e-posta, Supabase kullanici kimligi.
- Isletme/vitrin bilgisi: isletme adi, kategori, aciklama, adres, calisma saatleri, WhatsApp, Instagram, web sitesi.
- Kullanici icerigi: logo, urun gorselleri, galeri gorselleri, urun adi, fiyat, aciklama ve pazaryeri linkleri.
- Konum: kullanici izin verirse enlem, boylam, dogruluk bilgisi ve izin zamani.
- Teknik/yerel veri: edit token, yerel taslak ve kayitli vitrin/duzenleme verisi.

Data Safety cevaplari icin onerilen beyan:

- Veri toplaniyor: Evet.
- Veri paylasimi: Supabase hizmet saglayici olarak kullaniliyor. Diger dis baglantilar kullanici aksiyonu ile aciliyor.
- Veri sifreleme: Supabase ve HTTPS uzerinden aktarim kullaniliyor.
- Kullanici veri silme talebi: Evet, `/data-deletion` sayfasi ve `privacy@vitrinx.app` uzerinden.
- Reklam: Mevcut paketlerde reklam SDK'si yok.
- Odeme: Mevcut paketlerde uygulama ici odeme SDK'si yok.

## Hesap ve Veri Silme

Google Play icin uygulamada hesap olusturma oldugundan iki yol korunmali:

- Uygulama ici erisim: Landing, auth ve editor hukuki linkleri.
- Web erisimi: `https://vitrinx.app/data-deletion`

Silme talebinde istenecek bilgiler:

- Kayitli e-posta adresi.
- Vitrin veya magaza linki.
- Silinmesi istenen veri turu.
- Iletisim adresi.

## Yayin Oncesi Kontrol

Calistirilacak komutlar:

```bash
dart analyze
flutter test
flutter build appbundle --debug
```

Son release oncesi ayrica yapilacaklar:

- Gercek release keystore olustur.
- `release` signing config'i debug key yerine gercek upload key ile ayarla.
- `flutter build appbundle --release` calistir.
- Play Console Data Safety formunu bu not ve gizlilik politikasi ile ayni olacak sekilde doldur.
- Final AAB yuklemeden once merged manifest izinlerini tekrar kontrol et.
