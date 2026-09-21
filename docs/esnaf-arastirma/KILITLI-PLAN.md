# Vixrex — Türk Esnafı Kilitli Araştırma Planı

> Durum: KİLİTLİ ARAŞTIRMA DALI
>
> Dal: `research/esnaf-vixrex-kilitli-plan`
>
> Başlangıç ana dal SHA: `cf72979217d1e50139153d227e279780a1518183`
>
> Kural: Bu dal canlı ürünü değiştirmez. Kod, migration, deploy, PR veya merge amacı taşımaz.

## 1. Amaç

Vixrex'i "web sitesi yapan ürün" varsayımıyla değil, Türk esnafının gerçek müşteri bulma ve işletmesini dijitalde gösterme ihtiyacına göre geliştirmek.

Her karar şu üç soruya kanıtla cevap vermelidir:

1. Esnaf bugün müşteriyi nerede buluyor veya kaybediyor?
2. Müşteri esnafı nerede ve hangi bilgiyle arıyor?
3. Vixrex bu boşluğu bugün ne kadar karşılıyor, neyi karşılamıyor?

Tahmin, kişisel yorum ve tekil örnek plan kararı sayılmaz.

## 2. Değişmez sınırlar

- Bu dalda canlı ürün kodu değiştirilmez.
- Supabase şema/veri/migration değişikliği yapılmaz.
- Flutter veya Next.js davranışı değiştirilmez.
- Vercel deployment tetiklenmez.
- PR açılmaz.
- `main` ile merge edilmez.
- Araştırma sonucu doğrudan özellik talebine çevrilmez.
- Önce veri → tekrar eden ihtiyaç → Vixrex karşılaştırması → ayrı uygulama kararı sırası korunur.
- Mevcut çalışan özellik "araştırma sonucu" gerekçesiyle bu dalda yeniden tasarlanmaz.

## 3. Ana araştırma sorusu

**Türk yerel esnafının müşteriye ulaşmak için gerçekten hangi dijital bilgilere ve işlemlere ihtiyacı var; Vixrex bunların hangilerini tek yerde çözebiliyor?**

Alt sorular:

- Bağımsız web sitesi var mı?
- Google Maps/Google İşletme Profili ne kadar dolu?
- Instagram var mı ve işletme bilgisi ne kadar tamam?
- WhatsApp/telefon müşteri dönüşümünde nasıl kullanılıyor?
- Müşteri en sık hangi bilgiyi arıyor?
- Esnaf fiyat, ürün, hizmet, saat, konum, randevu/sipariş gibi bilgileri nerede tutuyor?
- Birden fazla kanaldaki bilgi birbiriyle tutarlı mı?
- Esnafın mevcut düzende tekrar tekrar yaptığı iş nedir?
- Vixrex'in 46 alanı bu gerçek ihtiyaçları karşılıyor mu?
- 46 alan, esnafın anlayacağı 10–12 işletme kavramına doğru bağlanıyor mu?

## 4. İlk saha: İstanbul / 100 gerçek işletme

İlk örneklem:

- 20 kuaför / berber / güzellik
- 20 restoran / kafe / yiyecek-içecek
- 20 butik / perakende
- 20 yerel hizmet işletmesi
- 20 ürün ağırlıklı esnaf

Kategori dağılımı araştırma sırasında değiştirilmez; ancak açıkça hatalı olduğu kanıtlanırsa değişiklik gerekçesi bu dosyaya yazılır.

## 5. Her işletmede aynı kayıt

Her işletme için en az şu alanlar incelenir:

| Alan | Ölçüm |
|---|---|
| Meslek/kategori | İşletme ne yapıyor? |
| İlçe/mahalle | Yerel bağlam |
| Google Maps | Var / yok |
| Web sitesi | Yok / zayıf / yeterli |
| Instagram | Var / yok / güncel değil |
| WhatsApp/telefon | Ana temas yolu var mı? |
| Çalışma saatleri | Bulunuyor ve tutarlı mı? |
| Adres/konum | Bulunuyor ve anlaşılır mı? |
| Ürün/hizmet | Müşteri ne satın alacağını anlayabiliyor mu? |
| Fiyat | Açık / kısmi / yok |
| Fotoğraf | Güncel ve karar vermeye yeterli mi? |
| Sipariş/randevu | Müşteri ne yapacağını biliyor mu? |
| Yorumlar | Tekrarlanan müşteri sorunu/ihtiyacı |
| Bilgi parçalanması | Maps / Instagram / web / WhatsApp arasında fark var mı? |
| Vixrex karşılığı | Bugün çözüyor / kısmen / çözemiyor |
| 46 alan karşılığı | Hangi mevcut alan veya alan grubu? |
| Yeni ihtiyaç | Gerçekten mevcut yapıda yok mu? |

## 6. Araştırma sırası

### A. Resmi gerçeklik
Önce resmi kaynaklar:
- TESK
- TÜİK
- Ticaret Bakanlığı
- ilgili meslek odaları / birlikleri
- Google'ın resmi İşletme Profili dokümanları

### B. Gerçek dijital ayak izi
Sonra işletme bazında:
1. Google Maps / Google İşletme Profili
2. İşletmenin kendi web sitesi
3. Instagram
4. Görünür WhatsApp / telefon / sipariş / randevu yolu
5. Müşteri yorumlarında tekrar eden sorular

### C. Gerçek esnaf dili
Saha görüşmelerinde teknik kelime kullanılmaz.

Sorulacak temel sorular:
- Müşteri seni en çok nereden buluyor?
- Müşteri sana en çok ne soruyor?
- İnternette değiştirmek istediğinde en zor gelen bilgi ne?
- Yeni müşteri seni bulamadığında nerede kayboluyor?
- WhatsApp'ta tekrar tekrar ne yazıyorsun?
- Google/Instagram/web sitesindeki bilgilerin aynı mı?
- Bugün bunun için para ödediğin bir hizmet var mı?

## 7. İlk kanal hipotezleri

Bunlar sonuç değil; araştırılacak hipotezlerdir.

1. **Google Maps:** Vixrex'e ihtiyacı olan esnafı bulmak için ilk araştırma yüzeyi.
2. **Instagram:** Görsel karar verilen sektörlerde önemli keşif kanalı.
3. **WhatsApp:** Reklam kanalı değil; müşterinin esnafa ulaştığı ana kapanış yollarından biri.
4. **Fiziksel esnaf bölgeleri:** Dijital açık doğrulandıktan sonra saha araştırması.
5. **Esnaf odaları / muhasebeciler / tedarikçiler / POS çevresi:** Değer kanıtlandıktan sonra dağıtım kanalı olarak test edilecek.

Bu maddeler veriyle desteklenmeden "Vixrex satış stratejisi" ilan edilmez.

## 8. Vixrex'e çeviri kuralı

Araştırma doğrudan yeni özellik üretmez.

Her ihtiyaç şu süzgeçten geçer:

`Gerçek işletme ihtiyacı → kaç işletmede tekrarlandı → mevcut 46 alanda karşılığı → başka Vixrex sisteminde karşılığı → gerçekten eksik mi → değer/fayda → ancak sonra geliştirme kararı`

Özellikle 46 alan için hedef:

**46 teknik alanı azaltmak değil; onları esnafın anlayacağı 10–12 işletme kavramı altında birbirine bağlamak.**

Alan silmek, birleştirmek veya veri kaybetmek bu araştırma dalının görevi değildir.

## 9. Ölçüm eşikleri

Araştırma dört kontrol noktasında değerlendirilir:

- 25 işletme: ilk tekrar eden ihtiyaçlar
- 50 işletme: kategori farkları
- 75 işletme: yanlış hipotezlerin ayıklanması
- 100 işletme: ilk karar raporu

100 işletme bitmeden tekil gözlem "genel Türk esnafı davranışı" olarak yazılmaz.

## 10. Ana dalı uzaktan takip protokolü

Bu dalın amacı eski bir plana dönüşmek değil, Vixrex ile birlikte güncel kalmaktır.

Her araştırma oturumunda:

1. `main` son commit/SHA okunur.
2. Araştırmayı etkileyen Vixrex değişiklikleri salt-okuma kontrol edilir.
3. 46 alan, vitrin görünümü, Vixrex Asistan, Maps/Keşfet, ürün/hizmet, iletişim ve sahiplik akışını etkileyen değişiklikler not edilir.
4. "Araştırmadaki açık artık çözüldü mü?" kontrol edilir.
5. Plan değişecekse eski karar silinmez; tarih + kanıt + neden ile karar günlüğüne eklenir.
6. Canlı ürün bu daldan değiştirilmez.

## 11. Karar günlüğü

| Tarih | main SHA | Kanıt | Öğrendiğimiz | Vixrex etkisi | Plan değişti mi? |
|---|---|---|---|---|---|
| 2026-09-22 | cf72979 | Plan başlangıcı | Türk esnafı araştırması ayrı, canlıdan izole bir hatta tutulacak | Kod etkisi yok | İlk kayıt |

## 12. Başlangıçta korunacak hedef

Vixrex'i esnafa yalnızca "web sitesi" olarak sunmak yerine şu sonucu sağlayıp sağlamadığını ölçmek:

**Müşteri işletmeyi bulsun → ne sunduğunu anlasın → güven duysun → konum/saat/fiyat/hizmet bilgisini görsün → WhatsApp/telefon/randevu/sipariş yoluyla işletmeye ulaşsın.**

Bu ifade araştırma sonucunda doğrulanacak veya değiştirilecektir; varsayım olarak kilitlenmez.

## 13. Başlangıç kaynakları

- TESK: https://www.tesk.org.tr/
- TÜİK Veri Portalı: https://veriportali.tuik.gov.tr/
- Ticaret Bakanlığı: https://www.ticaret.gov.tr/
- Google Business Profile Yardım: https://support.google.com/business/

Kaynak tarihi, örneklem kapsamı ve hangi nüfusu temsil ettiği her bulguda ayrıca kaydedilir.

## 14. Bu dalın başarı ölçütü

Bu dal başarılı sayılırsa elimizde şunlar bulunmalıdır:

- 100 gerçek işletmeden karşılaştırılabilir veri
- kategori bazında tekrar eden ihtiyaçlar
- müşterinin işletmeyi bulma ve iletişim yolu
- Vixrex'in bugün çözdüğü / kısmen çözdüğü / çözemediği ihtiyaçlar
- 46 alanın 10–12 anlaşılır işletme kavramına kanıtlı eşlemesi
- hangi kanalda hangi esnafa nasıl ulaşılması gerektiğine dair kanıt
- ürün geliştirme kararlarına girdi olacak fakat canlı ürünü kendi başına değiştirmeyecek araştırma raporu

---

**Kilit:** Bu dosya Vixrex'in ürün kodundan bağımsız araştırma omurgasıdır. Araştırma ilerledikçe kanıt eklenir; kapsam sessizce değiştirilmez.
