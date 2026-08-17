# VixRex — PayTR ile Premium Abonelik Ödemesi Araştırması

**Tarih:** 17 Ağustos 2026
**Soru:** "Kiralık Vitrin = Premium" modelinde (aylık 299 TL) esnaftan abonelik
tahsilatı PayTR ile nasıl kurulur?
**Karar:** Kullanıcı PayTR'yi seçti (2026-08-17).

> **KAYNAK SINIRLAMASI (dürüst not):** PayTR'nin resmî geliştirici sitesi
> (dev.paytr.com) bu oturumda doğrudan erişilemedi — her istek 500 döndü
> (muhtemelen bot koruması/JS render). Aşağıdaki bilgiler arama motoru
> snippet'leri ve ikincil kaynaklardan derlendi. **Kesin entegrasyon
> parametreleri (hash formülü, callback alanları, komisyon tablosu) PayTR
> üye işyeri hesabı açılıp dev.paytr.com'a erişilince birincil kaynaktan
> doğrulanmadan koda yazılmaz.** Bu notta "kesin" denilen hiçbir şey yok;
> yalnız yön kararı ve doğrulanacak adımlar var.

## PayTR'nin üç entegrasyon yolu (arama snippet'lerinden)

| Yol | Nasıl çalışır | SaaS abonelik için |
|---|---|---|
| **Link API** | Sunucu ödeme linki oluşturur (`Link API Create`), müşteri linke tıklar, PayTR sayfasında öder; `Link API Callback` ödeme durumunu döner. Link silme (`Delete`) ve SMS/e-posta ile gönderme (`SMS&EMAIL`) de var. | ✅ **En uygun.** VixRex kendi kart formu çizmez; checkout PayTR'nin sayfasında olur. Callback ile doğrulama, webhook desenine benzer. |
| **iFrame API** | Kendi sayfamıza PayTR'nin kart formunu gömer (iframe). | Orta. Kart formunu bizim sayfada gösterir; daha çok görsel kontrol ama daha çok sürtünme. |
| **Direkt API** | Tam kontrol: ödeme formu bizde, PayTR'ye veri göndeririz, callback ile doğrularız. | En çok iş. Bizim için gerek yok. |

**Öneri: Link API.** Gerekçe: (a) checkout VixRex'te değil PayTR'de — kart verisi bizim
sunucumuzdan geçmez, PCI yüzeyimiz küçülür; (b) callback imza doğrulamasıyla
güvenli; (c) SaaS abonelik için en düşük eforlu yol.

## Kodda mevcut durum (2026-08-17, doğrulandı)

- Ödeme altyapısı **yok** — hiçbir migration'da `is_premium` / `premium_expires_at`
  / `premium_plan` kolonu tanımlı değil; `profiles` yalnız `id, email,
  created_at, last_sign_in_at`.
- `lib/services/premium_service.dart` iskeleti var (`isPremium`, `purchasePremium`,
  OCR yardımcıları) ama `ocr_usage` tablosu + `check_and_increment_ocr_usage`
  RPC'si DB'de yok ve `purchasePremium`'u çağıran hiçbir ekran yok.
- Yayın kapısı hazır: `POST /api/owner-publish` → `publish_working_draft` RPC
  (tek transaction; yasal onay tetikleyicisi deseni premium kontrolü için model).

## Doğrulanacak adımlar (PayTR hesabı açılınca)

1. **PayTR üye işyeri başvurusu** (`paytr.com/uye-isyeri-olun`) — kullanıcının
   yapması gereken dış hesap işi (kimlik/şirket belgesi gerekebilir).
2. **Entegrasyon bilgileri** (Mağaza Paneli > Destek & Kurulum > Entegrasyon
   Bilgileri): `merchant_id`, `merchant_key`, `merchant_salt` — üçü de
   Vercel env secret'ı olur, koda/README'ye yazılmaz.
3. **Link API Create** parametreleri ve **hash formülü** dev.paytr.com'dan
   birebir doğrulanır. Snippet'te görünen desen (merchant_id + ... +
   payment_amount + payment_type + installment_count + currency + ...)
   doğrulanmadan kullanılmaz.
4. **Callback/önbellek:** callback URL'si `/api/paytr/callback` gibi bir
   Next.js route olur; `merchant_oid` (bizim sipariş kimliğimiz) ile sipariş
   eşleşir. `payment_amount` snippet'e göre "tutar × 100" (34.56 → 3456).
5. **İmza doğrulama fail-closed:** callback imzası doğrulanmazsa istek reddedilir;
   premium'u yalnız doğrulanmış callback yazabilir (istemci kendi kendine
   premium yapamaz — bugün `purchasePremium` bunu yapabiliyor, kapatılacak).
6. **Oran sınırı:** callback'i çağıran dış kaynak olduğu için mevcut
   `consume_assistant_request` deseniyle oran sınırı konur (VIXREX_RULES §9).
7. **Fatura/e-fatura:** PayTR tarafında fatura entegrasyonu varsa ayrıca
   incelenir — yasal uyum kullanıcı kararıdır.

## Bu notun sonucu

- **Yön:** Link API. 
- **Blokaj:** PayTR üye işyeri hesabı (kullanıcı başvurusu) + dev.paytr.com
  erişimi olmadan entegrasyon kodu yazılamaz.
- **Engellenmeyen:** Premium DB şeması, deneme süresi mekanizması, yayın
  kapısı, kiralama bandı fiyatı — bunlar PayTR'den bağımsız; spec ve bu
  parçaların PR'ları önce ilerleyebilir.
