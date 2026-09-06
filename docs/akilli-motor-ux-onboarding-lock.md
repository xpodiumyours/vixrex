# Vixrex Akıllı Motor — UX Lifecycle + Onboarding LOCK

> Kapsam: sahiplik sayfasındaki Vixrex Asistan balonu/sheet davranışı, motor durumlarının esnafa doğru yansıması ve mevcut onboarding/handoff. Yeni görsel konsept üretmez; BUILD yapmaz.

## Amaç

Motor teknik olarak doğru çalışsa bile esnaf:
- ne olduğunu anlayamıyorsa,
- kayıt olmadan başarı görüyorsa,
- hata gizleniyorsa,
- vitrini düzenleme sırasında göremiyorsa,
- geri alma ile neyin geri döneceğini bilmiyorsa

Akıllı Motor tamamlanmış sayılmaz.

W3C/WAI yaklaşımıyla uyumlu UX ilkesi: işlem sonucu açık bildirilir; hata hangi alanın neden reddedildiğini ve nasıl düzeltileceğini söyler; kullanıcı mümkün olduğunda düzeltme/undo yapabilir.

---

## 1. Mevcut sahiplik UX kanıtı

PR #413'te mobil sahiplik yüzeyinde mevcut davranış iskeleti var:

- `FieldInputArea.gonderVeVitriniGoster()`
- mobilde Gönder'e basınca açık asistan canonical `Vixrex Asistan` düğmesi üzerinden kapanıyor,
- `body.vixrex-asistan-isliyor` sınıfı ekleniyor,
- canonical düğme spinner + `Düzenleniyor…` görünümüne dönüşüyor,
- `await gonder()` bitince sınıf kalkıyor,
- masaüstü davranışına dokunulmuyor.

Bu yaklaşım kullanıcının daha önce belirlediği hedefle uyumludur:

```text
Gönder
→ asistan küçülür
→ sağdaki Vixrex ikonu işlem/loading gösterir
→ vitrin görünür kalır
```

### Kanıtlanan eksik

Bugünkü görsel loading, `gonder()` promise yaşamına bağlıdır; yeni LOCK edilen gerçek action lifecycle (`validated/executing/queued/succeeded/failed`) ile henüz ortak state değildir.

CSS pseudo-element spinner'ın görünmesi tek başına programatik/accessibility status bildirimi değildir.

---

## 2. Sahiplik balonu / sheet durum makinesi — LOCKED

Motor UX'i aşağıdaki görünür durumlara sahiptir:

```text
closed_idle
open_idle
needs_input
executing
queued_offline
succeeded
failed
partial_result
```

Bunlar DB state'i değildir; authoritative `ExecutionResult` ve conversation decision'dan türetilen UI durumlarıdır.

### `closed_idle`
- Vitrin tam görünür.
- Sağda canonical Vixrex düğmesi/ikon.
- İkinci ayrı asistan açma düğmesi oluşturulmaz.

### `open_idle`
- Asistan sheet/panel açık.
- Kullanıcı mesaj yazabilir veya mevcut özel akış kontrolünü kullanabilir.

### `needs_input`
- Netleştirme / kategori / il-ilçe / görsel / çalışma saati gibi kullanıcı girdisi gerekiyor.
- Panel açık kalır veya otomatik yeniden açılır.
- Kullanıcının önceki doğru girdileri silinmez.

### `executing`
- Mesaj gönderildi ve authoritative action yürütülüyor.
- Mobil: sheet kapanır; vitrin görünür kalır; canonical ikon loading gösterir.
- Masaüstü: mevcut kompozisyon korunabilir; vitrin görünürlüğü engellenmez.
- Aynı action'ın ikinci kez gönderilmesi engellenir.

### `queued_offline`
- `Kaydedildi` denmez.
- Açık metin: değişiklik cihazda sıraya alındı fakat buluta henüz kaydedilmedi.
- Bu state cross-device görünürlük vaat etmez.

### `succeeded`
- Yalnız server/persistence başarı sonucundan sonra.
- Mobilde sheet zorla geri açılmaz; kullanıcı önce vitrindeki sonucu görebilir.
- Değişen alan mevcut highlight/refresh mekanizmasıyla görünür kılınır.
- Sohbet geçmişinde gerçek başarı kartı bulunur.
- Uygun mutation'da `Geri al` action'ı sunulur.

### `failed`
- Loading biter.
- Kullanıcı aksiyonu gerekiyorsa sheet yeniden açılır.
- Hata alanı + sebebi + düzeltme yolu gösterilir.
- Başarı ikonu/mesajı yoktur.

### `partial_result`
- Çok alanlı komutta bazı action'lar succeeded, bazıları failed ise panel açılır.
- `Kaydedilenler` ve `Kaydedilemeyenler` ayrılır.
- Undo yalnız succeeded action'ları kapsar.

---

## 3. Başarı semantiği — LOCKED

Yasak:

```text
NLU handled → "Kaydettim"
```

Doğru:

```text
validated_action
→ executing
→ server ExecutionResult.succeeded
→ "Telefon güncellendi"
```

Bu kural Flutter ve Next için aynıdır.

`validated`, `queued_offline`, `failed`, `conflict` durumları success görseli kullanamaz.

---

## 4. Loading davranışı — LOCKED

Mevcut PR #413 canonical loading deseni korunur; ikinci loader sistemi açılmaz.

BUILD'de:
- `vixrex-asistan-isliyor` yalnız gerçek `executing` state'inden türetilir,
- promise tamamlandı diye otomatik success varsayılmaz,
- action sonucu gelmeden loading kalksa bile success gösterilmez,
- canonical butonun erişilebilir adı/durumu da değişir (`aria-busy`, status/live-region veya eşdeğer erişilebilir bildirim),
- yalnız `pointer-events: none` güvenlik/etkileşim kilidi sayılmaz; processing state click/keyboard tekrarını gerçek component state'iyle engeller.

Animasyon kullanıcı tercihine saygılı olmalıdır (`prefers-reduced-motion` durumunda zorunlu sürekli spin gerekmez).

---

## 5. Hata / netleştirme — LOCKED

Hata mesajı teknik kodu esnafa çıplak göstermez.

Mesaj üç bilgi taşır:
1. hangi alan,
2. ne yanlış,
3. ne yazması/seçmesi gerekiyor.

Örnek:

```text
WhatsApp numarası geçerli değil.
05xx xxx xx xx biçiminde yazabilirsin.
```

Belirsiz intent:

```text
Telefonu mu, WhatsApp numaranı mı değiştirmek istiyorsun?
```

Motor tahmin edip mutation yapmaz.

Server error code log/audit'te kalabilir; UX mesajı ortak hata eşleme sözleşmesinden gelir.

---

## 6. Undo görünümü — LOCKED

Assistant başarı kartındaki `Geri al`, action-level undo'dur.

- `Canlı hâline döndür` owner editör fonksiyonuyla aynı şey değildir.
- Undo başarılıysa `Geri alındı` gösterilir ve vitrin tekrar refresh/highlight olur.
- `UNDO_CONFLICT` varsa daha yeni değişiklik ezilmez; kullanıcıya `Bu alan daha sonra yeniden değiştirildi; otomatik geri alamıyorum.` denir.

---

## 7. Çoklu alan sonucu — LOCKED

Esnaf teknik transaction terimi görmez.

Örnek:

```text
Güncellendi:
✓ Telefon
✓ Çalışma başlığı

Düzeltilmesi gerekiyor:
• Instagram kullanıcı adı geçerli değil.
```

Kısmi başarının gizlenmesi veya tüm alanlar kaydedilmiş gibi tek `✅` gösterilmesi yasaktır.

---

## 8. Onboarding mevcut yapısı — KORUNACAK

Flutter `VixRexOnboardingController` zaten gerçek bir adım makinesi:

```text
welcome
→ templateNiyet (opsiyonel)
→ name
→ category
→ whatsapp
→ location
→ legal
→ publishing
→ done
```

Controller:
- widget bağımsız,
- busy/error state taşıyor,
- alan doğruluyor,
- mevcut `StoreEditorController` ile kurulum taslağını kaydediyor,
- kayıtlı vitrin varsa kaldığı adımdan devam ediyor.

Bu yapı yeniden yazılmaz.

---

## 9. Asistan tanıma / onboarding davranışı — LOCKED

Yeni ayrı eğitim uygulaması veya uzun tutorial kurulmaz.

### İlk tanıma

Mevcut onboarding welcome yüzeyi kısa biçimde şu üç gerçeği anlatmalıdır:

1. `Vixrex Asistan vitrini kurmana ve düzenlemene yardımcı olur.`
2. `Bilmediği bilgiyi uydurmaz; gerektiğinde sana sorar.`
3. `Yayın sonrası telefon, adres, başlıklar ve diğer vitrin bilgilerini konuşarak değiştirebilirsin.`

`Yapay zekâ` iddiası yapılmaz; ürün davranışı neyse o anlatılır.

### Kurulum sırasında

- Kullanıcı yalnız o an gerekli soruyu görür.
- 46 alanı liste halinde öğrenmek zorunda değildir.
- Teknik `field/JSON/state/RPC` dili yoktur.
- Özel akışlarda seçim/yükleme/GPS mevcut UI ile yapılır.

### Kurulum → owner-edit handoff

Yayın tamamlanınca mevcut handoff/companion akışı korunur.

İlk owner-edit tanıtımı kısa örneklerle yeteneği öğretir:

```text
"WhatsApp numaramı değiştir"
"Çalışma saatlerimi düzenle"
"Kapak fotoğrafımı değiştir"
```

Bu örnekler yeni motor yeteneği açmaz; yalnız zaten LOCK edilmiş 46-alan davranışını tanıtır.

---

## 10. Mobil / masaüstü sınırı — LOCKED

Mobil kullanım ana kritik yüzeydir fakat masaüstü kırılmaz.

### Mobil
- Gönder sonrası executing → sheet kapanır.
- Vitrin görünür kalır.
- Sağ canonical Vixrex control işlem durumunu taşır.
- needs_input/failed/partial_result → panel yeniden görünür.

### Masaüstü
- PR #413'ün `masaüstü davranışına dokunma` sınırı korunur.
- Asistanın açık kalması kabul edilebilir ancak vitrin görünürlüğünü bozamaz.
- Action state semantiği mobil ile aynıdır.

---

## 11. Erişilebilirlik LOCK

- Loading/success/error yalnız renk veya spinner ile anlatılmaz.
- Değişen status ekran okuyucu tarafından fark edilebilir olmalıdır.
- Error alanla ilişkilendirilir ve düzeltme önerisi verilir.
- Keyboard ile aynı action processing sırasında tekrar tetiklenemez.
- Kapat/aç kontrolünün `aria-expanded` benzeri mevcut anlamı korunur.
- Input error'da kullanıcının doğru yazdığı diğer değerler korunur.

---

## 12. Kapsam sınırı

YAPILACAK:
- mevcut sahiplik balon/sheet state'lerini action lifecycle'a bağlamak,
- gerçek loading/success/error/queued/partial sonucu,
- mobile collapse davranışını gerçek execution state'e bağlamak,
- accessible status,
- onboarding kısa tanıma/handoff metni ve davranış doğrulaması.

YAPILMAYACAK:
- yeni 3-mod tasarım icat etmek,
- alt navigasyon yeniden tasarımı,
- yeni icon library,
- owner sayfasını yeniden çizmek,
- Blog/Dijital Çarşı UX'i,
- onboarding adımlarını baştan kurmak,
- mevcut public storefront görünümünü değiştirmek.

## LOCK sonucu

**UX Lifecycle + Onboarding davranışı: LOCKED.**

Kalan Architecture LOCK kapıları: domain router/runtime kill-switch sınırı, test/CI gate ve tüm LOCK belgelerinin tek final architecture doğrulaması. BUILD hâlâ kapalıdır.
