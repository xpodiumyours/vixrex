# Canlı test bulguları — 2026-08-06

13 fazlık plan yayına alındıktan sonra Casper'ın uygulamayı baştan sona
gerçek akışla denemesinden çıkan liste. **Henüz araştırılmadı** — tek tek
ele alınacak.

Genel değerlendirme (kullanıcının kendi sözü): *"temel olarak iyi gidiyoruz,
hatta mükemmel."* Aşağıdakiler ince işçilik ve mimari ayrım sorunları.

---

## A. Giriş ve kurulum akışı

### A1 — Giriş ya çalışmıyor ya çok yavaş
Login ekranı ya hiç açılmıyor ya da kabul edilemez sürede açılıyor.
Kullanıcının ilk karşılaştığı ekran bu; burada takılan geri gelmez.

### A2 — GPS konumu yanlış tespit ediliyor
İlk üç zorunlu bilgiden biri konum. Otomatik tespit edilen konum yanlış
çıkıyor. Esnaf yanlış konumla vitrin açarsa müşteri onu bulamaz — ürünün
"yakınındaki esnaf" hedefiyle doğrudan çelişiyor.

---

## B. Vitrin oluşturma

Üç zorunlu bilgiyle (işletme adı, WhatsApp, konum) vitrin oluşturuldu,
link üretildi, **link çalışıyor**. Buraya kadar sorun yok.

### B1 — İstenmeyen otomatik kapak fotoğrafı
Butik mağazası için vitrin açılınca kapak fotoğrafı kendiliğinden gelmiş.
Kullanıcı seçmedi, sistem koydu. Beklenen davranış netleştirilmeli:
otomatik mi gelsin, boş mu kalsın, yoksa sorulsun mu?

---

## C. Mimari ayrım — hangi Vixrex nerede

Bu bölüm tek bir kök soruna bakıyor: **iki ayrı Vixrex asistanı var ve
sınırları belirsiz.**

| | Nerede | İşi |
|---|---|---|
| **Kurulum asistanı** | Flutter karşılama ekranı | Karşılar, ilk bilgileri alır, yayına aldırır |
| **Vixrex Asistan** | Next.js sahip sayfası | Yayındaki vitrini düzenler, özelleştirir |

### C1 — "Hazır şablon seç" yanlış yerde açılıyor
4. adımda "hazır şablon seç" denince kategorilere özel ücretsiz kapak
görselleri kütüphanesi açılıyor — ama **Flutter manuel üyelik panelinde**
açılıyor. Next.js sahip sayfasında açması gerekiyordu.

### C2 — TEK ASİSTAN (karar verildi, 2026-08-06)

Bu madde ilk yazıldığında "sınırı netleştirelim" diyordu. **Yanlıştı.**
Kullanıcının kararı: sınır olmayacak.

> *"Sert devri bitirip ikiz olacak, tek yüz Vixrex. Hem uygulamada hem
> tarayıcıda tek asistan seviyesinde bir kalite."*

**Ne DEĞİL:** Flutter'ı sökmek, kurulumu web'e taşımak, mimariyi
yeniden kurmak. Kullanıcı bunu açıkça reddetti — çalışan ürünü demoya
çevirecek bir işlem yapılmayacak.

**Ne EVET:** İki yerdeki asistan aynı varlık gibi davranacak. Kod
yerinde kalır; kullanıcı sınırı hissetmez.

Araştırma sonucu — ikisi çakışmıyor, sırayla çalışıyorlar:

| | Dosya | İş |
|---|---|---|
| Kurulum sohbeti | `lib/screens/vixrex_onboarding_chat_screen.dart` (894 satır) | 7 adım: karşılama → ad → WhatsApp → konum → yasal onay → yayınla → link. **0'dan yayınlanmış vitrine.** |
| Vixrex Asistan | `public_web/.../OwnerAssistantPanel.tsx` (529 satır) | Doluluk raporu, 41 alanda tıkla-düzenle, görsel yükleme, yayınla/vazgeç. **Vitrinden kaliteye.** |

Asıl sorun ayrı yerde olmaları değil, **devrin sert olması**: kurulum
bitince kullanıcı başka bir uygulamaya düşüyor, görünüm ve dil devam
etmiyor.

Yapılacaklar (hepsi düşük riskli, mevcut yapıyı bozmaz):
1. Aynı isim, maskot, ton ve mesaj dili — iki tarafta birebir
2. Kesintisiz devir: kurulum biter bitmez "vitrinini açtım, şimdi
   birlikte güzelleştirelim" deyip sahip panelini açsın; link verip
   bırakmasın
3. Sohbet panelinin görsel dili iki tarafta aynı olsun
4. C1 ve C3 bu başlığın parçası — şablon kütüphanesi doğru tarafta
   açılsın, canlı düzenleme Flutter'a yansısın

### C3 — Canlıda yapılan düzenleme Flutter paneline yansımıyor
Vixrex Asistan ile canlıda düzenleme yapıldı, **Flutter manuel üyelik
paneli güncellenmedi**. İki kapı aynı veriye bakmalı; biri değişince
diğeri eski veriyi göstermemeli.

---

## D. Kalite hedefi

### D1 — Vixrex Asistan "web sitesi kalitesinde" düzenleme yapamıyor
Şu an alan alan düzenleme çalışıyor. Hedef daha yukarısı: asistanın
vitrini bir web sitesi gibi özelleştirebilmesi — düzen, görsel, bölüm
sırası, tema. Referans: `sablonlar/hedef-vitrin.html`.

### D2 — Arayüz ince işçiliği
Genel UI kalitesi hedefin altında. Ayrıntılar tek tek çıkarılacak.

---

## Sıra

Önce araştırma, sonra düzeltme. Öncelik sırası kullanıcıyla belirlenecek;
ilk bakışta **A1 ve A2** en kritik görünüyor (kullanıcı daha vitrine
ulaşamadan kaybediliyor), sonra **C1/C3** (mimari sızıntı), sonra **D**.
