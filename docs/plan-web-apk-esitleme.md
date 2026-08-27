# Plan — web ile uygulamayı eşitleme

**Yazan:** Claude (27 Ağustos 2026) · **Yürüten:** Codex · **Doğrulayan:** Claude
**Kaynak:** `main` @ `f377756` — iki taraf da güncel koddan tarandı, tahmin yok.

Casper'ın kararı (27 Ağustos): **küçük adım yok, büyük ve somut adım.**
Her fazın tek cümlelik bir bitiş şartı var; şart gerçek tarayıcıda, gerçek
hesapla, canlı adreste kanıtlanmadan faz kapanmaz. "Testler yeşil" kabul
değil.

---

## 1. Bugünkü durum — ölçüm

### Ön yüz: uygulamada olan ekranlar

| Uygulama ekranı | Web'de | Not |
|---|---|---|
| Giriş / kayıt | ✅ var | `/giris`, `/kayit` — aynı kimlik |
| Keşfet | ✅ var | `/kesfet` + 19 kategori sayfası (web'de daha zengin) |
| Vitrin görüntüleme | ✅ var | `/v/<slug>` |
| Ürün sayfası | ✅ var | `/v/<slug>/urun/<urun>` |
| Vitrin düzenleme | ⚠️ farklı | Uygulamada form, web'de asistan. **Bilinçli**, bkz. §2 |
| Ürün yönetimi | ✅ var | `/app` içinde, kategori yönetimi dahil |
| Yayınlama + yasal onay | ✅ var | `PublishBar`, `owner-publish` |
| Randevu alma (müşteri) | ✅ var | `/v/<slug>/randevu` + takip bağlantısı |
| Randevu yönetimi (sahip) | ✅ var | 27 Ağustos'ta geldi |
| Blog yazı listesi | 🟡 yarım | Liste + oluştur + sil var; **yazı yazılamıyor** |
| **Blog editörü** | ❌ yok | Uygulamada içerik, kapak, SEO paneli var |
| Blog moderasyonu | ⛔ yapılmayacak | Casper 27 Ağustos: moderatör yok, iması kaldırılıyor |
| **Toplu ürün yükleme** | ❌ yok | Excel + XML + fatura okuma |
| **Profil** | ❌ yok | |
| **Ayarlar** | ❌ yok | |
| **Bildirimler** | ❌ yok | |
| **Yardım / destek** | ❌ yok | |

Web'de olup uygulamada olmayan (ve olması gerekmeyen): kategori dizini
sayfaları, site haritası, robots, paylaşım görselleri, blog okuma sayfaları.

### Arka uç: veritabanı yetenekleri

Uygulamanın çağırıp **web'in hiç çağırmadığı** işlevler:

| İşlev | Ne işe yarıyor |
|---|---|
| `batch_create_products` | toplu ürün ekleme |
| `check_and_increment_ocr_usage` | fatura okuma kotası |
| `reorder_store_products` | ürün sıralaması |
| `delete_store_with_token` | **vitrin silme** |
| `delete_user_account` | **hesap silme** |
| `withdraw_store_publication_consent` | yayın onayını geri çekme |
| `get_store_premium_status` | premium durumu |
| `get_today_vitrin_view_count` | günlük görüntülenme |
| `get_feature_flags` | özellik bayrakları |
| `rent_demo_for_account` | hesapla kiralama |

Web'in çağırıp uygulamanın çağırmadıkları (web'e özel, sorun değil):
oturum köprüsü (`consume/extend_owner_session`), asistan taslak motoru
(`*_working_draft*`), yasal onay, PayTR ödeme akışı.

**Önemli:** eşitsizliğin çoğu arka uçta **yetenek eksikliği değil**, web'in
o yeteneği hiç kullanmaması. İşlevler canlıda hazır duruyor.

---

## 2. Kapatılmayacak farklar — bunlara dokunma

1. **Vitrin alanları web'de forma dönmez.** Web'de düzenleme asistanla
   yapılır (`VIXREX_RULES.md` §1, "üçüncü kapı açılmaz"). Ürün yönetiminin
   form olması bu kuralın dışında — kural vitrin alanları için yazıldı.
2. **Landing ile uygulama açılışı** zaten eşitlendi (26–27 Ağustos), çift
   yönlü bekçisi var. Yeniden ele alma.
3. **Keşfet farkları** 27 Ağustos'ta incelendi; kalanlar bilinçli ve
   sözleşme testiyle kilitli.

---

## 3. Fazlar

### Faz 1 — Blog yazısı gerçekten yazılabilsin

Bugün web'de bir yazı **oluşturulabiliyor ama içine tek kelime
yazılamıyor**. Yani özellik yarım duruyor: başlık üret, sil, o kadar.
Uygulamada içerik alanı, kapak görseli ve SEO paneli var.

Yapılacak: `/v/<slug>/blog-yonetim/<yazi>` düzenleme sayfası — içerik,
özet, kapak görseli, hedef konu/şehir, taslak↔yayına gönder. Var olan
`PATCH /api/articles` bunların hepsini zaten kabul ediyor; yeni uç
gerekmiyor. Kapak yükleme için `owner-upload` kullanılıyor.

**Casper'ın kararı (27 Ağustos): moderasyon yok, o mesaj kaldırılacak.**

Uygulamada yayına gönderince "güvenilir yazar değilsen moderatör inceler"
yazıyor, ama bu kural **hiçbir yerde uygulanmıyor** — `is_blog_trusted`
alanı hiç okunmuyor. Yani kullanıcıya var olmayan bir süreç anlatılıyor.

Gerekçe: moderatör bulacak durumda değiliz. İleride Başak gerçekten çalışır
ve Vixrex'e bağlanırsa bu işi o üstlenir; o zamana kadar sahte bir güvenlik
katmanı taşınmayacak.

Bu fazda yapılacak:
- Web'de yayınlama doğrudan olsun, moderasyon iması içeren metin yazma.
- Uygulamadaki yanıltıcı mesajı da düzelt (`blog_editor_screen.dart:58`) —
  "Yazı yayına gönderildi! (Güvenilir yazar değilseniz önce moderatör
  incelemesine alınır)" yerine ne olduğunu söyleyen düz bir cümle.
  İki yüzeyde de aynı cümle, `shared/vixrex_mesajlar.json` üzerinden.
- Uygulamadaki moderasyon ekranına **dokunma** — silinmiyor, adminler için
  duruyor, ileride Başak'a bağlanacak.

**Bitiş şartı:** Gerçek hesapla web'den bir yazı yazılıp yayına gönderiliyor
ve `/v/<slug>/yazilar` sayfasında görünüyor.

### Faz 2 — Hesap ve vitrin silme (KVKK)

Web'de kullanıcı **hesabını da vitrinini de silemiyor**. İkisinin de
veritabanı işlevi hazır (`delete_user_account`, `delete_store_with_token`),
uygulamada çalışıyor. Bu bir özellik değil, yasal zorunluluk — ve uygulama
mağazası şartı.

Yapılacak: `/app/hesap` altında iki yıkıcı işlem, ikisi de yazarak onay
istesin ("SİL" yazdır), silmeden önce ne kaybedileceğini sayfada göster.
`withdraw_store_publication_consent` ile "yayından kaldır" da aynı yere
girsin — silmeden vazgeçen kullanıcı için ara adım.

**Bitiş şartı:** Test hesabıyla önce vitrin yayından kaldırılıyor, sonra
vitrin siliniyor, sonra hesap siliniyor; veritabanında satır kalmıyor.

### Faz 3 — Toplu ürün yükleme

Casper'ın kendi listesinde birinci sıradaydı: "beni kişisel olarak
yavaşlatıyor". Uygulamada Excel, XML ve fatura okuma var; web'de hiçbiri
yok. Ürünler tek tek elle giriliyor.

Yapılacak: `/app` içinde dosya yükleme → sütun eşleme ekranı → önizleme →
`batch_create_products` ile toplu ekleme. **Fatura okuma (OCR) bu fazın
dışında**, ayrı ve daha pahalı iş.

Sıralama (`reorder_store_products`) da bu fazda gelsin — toplu yüklemeden
sonra sıralama ihtiyacı hemen doğuyor.

**Bitiş şartı:** 20 satırlık gerçek bir Excel dosyası web'den yükleniyor,
ürünler vitrinde doğru sırayla görünüyor.

### Faz 4 — Profil, ayarlar, bildirimler

Uygulamadaki üç ekranın web karşılığı. En küçük iş, en sona bırakıldı
çünkü hiçbiri esnafın vitrin kurmasını engellemiyor.

- Profil: e-posta, şifre değiştirme, vitrin bağlantısını kopyalama
- Ayarlar: bildirim tercihleri
- Bildirimler: `notification_inbox` okuma, "tümünü okundu"

**Bitiş şartı:** Web'den şifre değiştirilip yeni şifreyle giriş yapılıyor;
bildirim listesi uygulamayla aynı kayıtları gösteriyor.

### Faz 5 — (ERTELENDİ) Blog moderasyonu

**Casper'ın kararı, 27 Ağustos: bu faz yapılmayacak.** Moderatör bulacak
durumda değiliz; moderasyon iması metinlerden kaldırılıyor (bkz. Faz 1).

Freebuff'ın 27 Ağustos'ta yazdığı sürüm zaten PR'a alınmamıştı:
yetkilendirmesi "geçerli sahip çerezi yeterli" diyordu, yani herhangi bir
vitrin sahibi tüm vitrinlerin yazılarını yayınlayıp reddedebiliyordu.

İleride Başak gerçekten çalışır ve Vixrex'e bağlanırsa bu iş yeniden açılır
ve **sorumlusu o olur**. O gün geldiğinde yetki `admins` tablosundan
gelmeli; eski dosyalar örnek alınmamalı.

## 4. Her fazda geçerli kurallar

1. **Klasörde tek ajan.** 26 Ağustos'ta iki ajan birbirinin dosyasını ezdi.
2. **Kapsamı taşırma.** Faz dışında bir ekran görüp "bunu da yapayım"
   deme — 27 Ağustos'ta tam bu yüzden PR'a girmemesi gereken bir dosya
   çıktı ve derlemeyi kırdı.
3. **Bir RPC'yi yönetici anahtarıyla çağırmadan önce gövdesini oku.**
   `auth.uid()` geçiyorsa yönetici anahtarı kullanılamaz — bu hata bu
   projede dört kez çıktı.
4. **Sahip yönetim sayfalarında elle renk yazma.** `--owner-*` tanımları ve
   `owner-shell` kabuğu kullanılır; bekçi testi kırar.
5. **Yeni sayfa panodan erişilebilir olmalı.** Bağlantısı olmayan sayfa
   yok sayılır.
6. Doğrulama: `npm run lint && npm test && npm run build`. GitHub test
   kotası 1 Eylül'e kadar dolu, hepsi yerelde koşulacak.
7. PR sınırı 12 dosya / 600 satır; aşarsa açıklamaya `Kapsam-Onay:` satırı
   ve gerekçe.
8. **Main'e indirme işi Claude'da.** Dalı hazırla, haber ver.

## 5. Doğrulama hesabı

Canlıda hazır bir test hesabı var:
`vixrex.deneme.1787845811686@gmail.com` / `Deneme!1787845811686`,
vitrin `deneme-kuafor-salonu-mtbp9tip` (taslak, Keşfet'te görünmez).
Canlı adres: `https://vixrex-public.vercel.app`.

Yerelde sunucu tarafı API'ler denenemiyor — `.env.local`'deki yönetici
anahtarı canlı projeyle eşleşmiyor ("Invalid API key"). Sunucu tarafını
ilgilendiren doğrulama merge sonrası canlıda yapılır.
