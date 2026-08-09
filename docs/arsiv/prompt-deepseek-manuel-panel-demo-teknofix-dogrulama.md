# DeepSeek için görev — manuel panel demo-teknofix içeriğini gerçekten üretebiliyor mu

## Bağlam

`https://vixrex-public.vercel.app/v/demo-teknofix` artık hedef kalite
referansı — Casper ve Claude birlikte doğruladı, içerik dolu ve zengin
(`docs/prompt-demo-teknofix-fixtech-icerik.md`'deki içerik canlıda).

**Sıradaki soru:** Bu içeriğin **her parçası**, sıfırdan bir esnaf
tarafından **yalnız Flutter manuel üyelik panelinden** (my_vitrin ekranı
+ açtığı alt ekranlar) girilip kaydedilip yayınlanabilir mi?

**Sayılmayan yollar:** Next.js "Vixrex Asistan" paneli, doğrudan
Supabase/SQL migration. Yalnız Flutter manuel panel sayılır — çünkü
sıradaki iş bunun üstüne kurulacak (Vixrex Asistan ile kişiselleştirme
aşaması), önce bu temel doğrulanmalı.

## Yöntem

**Kod değişikliği yapma. Yalnız araştır ve rapor et.** Her madde için:

1. Panelde gerçek bir giriş alanı var mı — dosya:satır kanıtıyla göster.
2. O alan kaydedilip Supabase'e gerçekten yazılıyor mu (model → DTO →
   publish payload zinciri).
3. Yoksa/eksikse/şüpheliyse, nedenini net yaz.

**Tahmin ya da "büyük ölçüde çalışıyor" gibi ifadeler kabul değil** —
her madde ✅ / ⚠️ / ❌ ile kesin işaretlenecek. Bu üçüncü kez sorulan bir
soru (önceki iki turda `docs/prompt-deepseek-manuel-panel-eksik-alanlar.md`
ve PR #70 kısmi/belirsiz cevap bırakmıştı) — bu sefer kesinlik isteniyor.

## Kontrol listesi (hepsi tek tek, hiçbiri atlanmadan)

1. **Hero:** işletme adı, hero rozeti, kısa açıklama, konum metni,
   telefon/whatsapp/e-posta, çalışma saatleri, kapak/hero görseli.
2. **4 kategori:** isim + **görsel** — kategori görseli panelden
   yüklenebiliyor mu? (Daha önce "hayır, yalnız isim" bulundu —
   kesin doğrula, hâlâ öyle mi.)
3. **8 ürün/hizmet:** isim, fiyat, eski fiyat/indirim, süre, garanti,
   açıklama, kategori ataması, ürün görseli.
4. **Kampanya bandı:** etiket, başlık, açıklama, fiyat metni, görsel.
5. **Hakkımızda:** üst başlık, başlık, paragraf metni, görsel + alt
   yazı, 3 değer kartı (başlık + açıklama her biri).
6. **Galeri:** üst başlık, başlık, buton metni + buton linki, 5 görsel
   + her birinin etiketi.
7. **Blog:** üst başlık, bölüm başlığı, yazı ekleme (başlık, özet,
   tam içerik, kapak görseli) — kaç yazı eklenebiliyor, sınır var mı.
8. **SSS:** üst başlık, başlık, açıklama, soru-cevap ekleme (kaç adet).
9. **İletişim:** açık adres, harita kartı etiketi, Google İşletme/Harita
   Bağlantısı, **Referanslar Bağlantısı** (daha önce hiç UI bulunamadı —
   kesin doğrula, var mı yok mu), yol tarifi butonu aç/kapa, puan bandı
   aç/kapa.
10. **İşletme Türü** alanı — elle girilebiliyor mu, yoksa yalnız
    kategori seçiminden mi otomatik kopyalanıyor? Kesin doğrula.
11. **Bölüm görünürlüğü** (section_visibility, 7 anahtar) — panelden
    değiştirilip Next.js'te gerçekten yansıyor mu.

## Rapor formatı

Her madde: `✅ / ⚠️ / ❌ — kanıt (dosya:satır) — kısa not`.

Sonunda tek cümle özet: **"Panel bu içeriğin X/Y parçasını gerçekten
üretebiliyor."** Eksik çıkan her madde ayrı ayrı listelenecek — kırpma,
öne çıkanları değil TÜMÜNÜ yaz (bkz. proje kuralı: liste kırpılmaz).
