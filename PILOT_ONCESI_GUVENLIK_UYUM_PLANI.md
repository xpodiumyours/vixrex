# Pilot Öncesi Güvenlik ve Uyum Kapısı

## Pilot kararı
- Şu an pilot başlatma: hayır.
- Neden: yayınlanmış vitrinlerin `edit_token` değeri anonim erişime açık; bu, başka bir kullanıcının vitrinini değiştirme veya silme riski doğuruyor.
- Hukuki metinlerde de tekil ve doğru veri sorumlusu/işleyici bilgisi henüz net değil. Bu teknik değil, şahıs şirketi bilgileriniz ve hukuk danışmanı onayı gerektiren bir karar.

## 1. Engelleyici yetki açıklarını kapat
- `stores.edit_token` değerini anon/authenticated SELECT yüzeyinden kaldır; token yalnız token doğrulayan `SECURITY DEFINER` RPC içinde kullanılabilsin.
- `update_store_with_token`, `delete_store_with_token` ve consent-withdraw RPC’leri için sahiplik/token doğrulamasını yeniden test et.
- `appointments` UPDATE ve `booking_settings` yazma politikalarını `true/true` yerine gerçek vitrin sahipliğiyle sınırla.
- Yayınla/güncelle/sil RPC’lerine orantılı rate limit ekle.
- Yeni sözleşme testleri: anonim istek token okuyamaz; başka vitrini güncelleyemez/silemez; randevu ve ayarları değiştiremez.

## 2. Misafir kullanıcı sahipliğini güvenceye al
- Yayın sonrası “hesabını güvenceye al” akışını görünür ve tamamlanabilir yap; `link_store_to_user` mevcut yol olarak kullanılacak.
- Yerel token silinmesi/cihaz değişimi için kullanıcıyı token arayan zayıf fallback yerine hesap bağlantısına yönlendir.
- Vitrin silindiğinde ilişkili `shelf-images` dosyalarını da temizle veya açıkça planlı arka plan temizliğine bağla.

## 3. Yasal metinleri tek kaynağa bağla
- Şahıs şirketinin kesin unvanı, adresi, vergi/MERSİS bilgisi, KVKK iletişim e-postası ve saklama süresini hazırla.
- Hukuk danışmanıyla hangi metnin resmi olduğuna karar ver: uygulamanın DB tabanlı sürümlü belgesi ile `public_web/src/app/privacy/page.tsx` aynı içeriği anlatmalı.
- Aktif aydınlatma metnine veri işleyenleri/aktarımları (Supabase, Vercel, Maps, Meta/Instagram varsa) ve KVKK başvuru haklarını gerçek davranışla uyumlu biçimde ekle.
- Kullanım koşullarına içerik kaldırma/moderasyon hakkı ekle; public `/terms`, `/consent` ve veri silme bağlantılarının gerçek rotalarını doğrula.
- Bu aşama hukuk görüşü gerektirir; kod, avukatın onayladığı metni uygulamaya taşır ama hukuk görüşünün yerini tutmaz.

## 4. Public vitrin sorumluluğu ve operasyon
- Core vitrin içeriği için raporla/kaldırma akışını tasarla; blog moderasyonundan ikinci bir motor üretmeden mevcut moderasyon sahipliğini genişletme seçeneğini değerlendir.
- Sızdırılmış parola korumasını Supabase Auth’ta etkinleştir; public storage bucket listeleme yetkilerini gereksizse kapat.
- Silme, onay çekme, public link ve Explore görünürlüğü için canlı kabul senaryolarını hazırla.

## 5. 5–20 işletmelik kapalı pilot
- Önce gerçek cihazda: onboarding → yayın → public link → düzenleme → hesabı bağlama → consent withdrawal → silme zincirini test et.
- İlk kullanıcılar tanıdık işletmeler olur; açıkça pilot olduğunu, destek kanalını ve geri bildirim yolunu belirt.
- Başarı ölçütü: işletme kendi başına vitrini yayımlayıp linkini paylaşabiliyor; sonraki gün hesabıyla geri dönüp düzenleyebiliyor; hatada destek talebi açabiliyor.
- Pilot ancak 1–4 tamamlanıp doğrulama kanıtı oluşunca başlar.
