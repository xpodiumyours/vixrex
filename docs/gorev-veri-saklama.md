# Görev — Veri saklama ve temizlik düzeni

Durum: yazıldı, başlanmadı. Tarih: 2026-08-29.

## Neden

`cleanup_expired_trial_clones` bugün doğru çalışıyor (saatte bir, pg_cron
jobid=2, koşumlar başarılı). Ama üç yapısal kusuru var ve ikisi şimdiden
somut zarar üretiyor.

**Ölçülen durum (2026-08-29, canlı):**

- 37 vitrin: 9'u yayında (4 demo + 5 kiralanabilir), 28'i taslak.
- `kiralik-teknik-2901f4b1` — **kalıcı test vitrini**, 28 Ağustos'ta açıldı.
  Klon + yayınlanmamış + premium yok → üç şartı da tutuyor,
  **11 Eylül'de cron silecek.** Korunması gerekiyor.
- `kiralik-gida-42ce4a3a` — `cloned_from_slug` boş doğmuş. Temizlik ilk
  şarta takılıyor, bu satır **yaşı ne olursa olsun hiç silinmeyecek.**
- `test-dukkan-123-mtdsc126`, `test-dukkan-123-mtds9dji` — 29 Ağustos gecesi
  tarayıcı testinin bıraktığı sahipsiz vitrinler. Sebep ayrı bir kırık:
  `create-store` zaten vitrini olan hesapta 500 dönüp arkada satır bırakıyor.

## Yapılacaklar

### 1. Koruma alanı — `retention_hold_until`

Silinmemesi gereken satırlar için amacı adında yazan ayrı kolon. Ödeme
kolonu (`premium_expires_at`) koruma amaçlı **kullanılmayacak** — para
alanını saklama politikası için ödünç almak, altı ay sonra kimsenin
çözemeyeceği bir karışıklık üretir.

Temizlik fonksiyonuna tek şart eklenir:
`and (retention_hold_until is null or retention_hold_until < now())`

Kalıcı test vitrini bu alanla korunur, sebebi de yazılır.

### 2. Önce işaretle, sonra sil

Bugün doğrudan `DELETE` var, geri dönüşü yok. Standart desen:
`deleted_at` damgası konur → kayıt uygulamadan görünmez olur → **30 gün
sonra** gerçekten silinir. Yanlış silinen bir satır bu pencerede geri
alınabilir.

### 3. Tahmin değil, açık etiket

Temizlik şu an `cloned_from_slug is not null` ile "bu bir kopyadır" diye
**tahmin ediyor**. `kiralik-gida-42ce4a3a` tam bu yüzden ölümsüz.
Her vitrin ne olduğunu açıkça taşımalı: demo / kiralık deneme / gerçek
müşteri. Temizlik o etikete baksın.

### 4. İzleme

Her koşumda kaç satır etkilendiği loglanmalı. Beklenmedik sayı (0 ya da
çok yüksek) fark edilebilsin. Bugün sessizce koşuyor.

## Yan fayda — KVKK/ETBİS

Saklama süresi zaten beyan edilmesi gereken bir şey. Bu iş bitince yazılı
politikaya dönüşür: "kiralık deneme kayıtları 14 gün sonra pasifleştirilir,
30 gün sonra silinir."

## Sınırlar

- Migration gerekir; canlı şema değişikliği **açık onay ister**.
- `premium_expires_at` dolu satırlara asla dokunulmaz — para ödemiş
  esnafın verisi silinmez, bu kural aynen kalır.
- Mevcut cron işleri (jobid 2-6) çalışıyor, kapatılmayacak.
