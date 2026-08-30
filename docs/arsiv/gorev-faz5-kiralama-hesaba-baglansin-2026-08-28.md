# Görev — Faz 5: web'den kiralama hesaba bağlansın

**Yazan:** Claude (28 Ağustos 2026) · **Yürüten:** Codex · **Doğrulayan:** Claude
**Kaynak plan:** `~/.claude/plans/proud-tinkering-dragonfly.md` (Casper onayladı)
**Taban:** `main` — dalı **uzak** main'den aç, bkz. §Çalışma kuralları

---

## Neden bu iş öncelikli

Casper'ın iş modeli: 100 hazır kiralık vitrin, insanlar Keşfet'ten kiralasın.
Web 26 Ağustos'ta ana kapı oldu. Ama **web'den kiralanan vitrin hesaba
bağlanmıyor** — sahipsiz doğuyor ve 30 saatte siliniyor, kullanıcı giriş
yapmış olsa bile.

Uygulamada bu doğru çalışıyor (`lib/services/demo_rental_service.dart`,
`lib/config/app_router.dart:386`): kalıcı hesapla giriş yapılmışsa
`rent_demo_for_account` çağrılıyor, klon **sahipli** doğuyor, token bir
yıllık oluyor. Web ise (`public_web/src/app/api/rent-demo/route.ts:131`)
her koşulda `start_demo_trial` çağırıyor.

Yani para kazandıracak akışın son halkası web'de kopuk.

## Veritabanı tarafı HAZIR — yeni migration yazma

`rent_demo_for_account(p_source_slug text)` canlıda mevcut ve gereken her
şeyi kendisi yapıyor (gövdesi canlıdan okundu):

- anonim/oturumsuz çağrıyı reddeder (`is_permanent_user()`)
- hesap başına tek vitrin kuralını uygular
- saatte 5 kiralama sınırı koyar (`consume_assistant_request`)
- kaynağın gerçekten yayında bir demo olduğunu doğrular
- klonlar, `user_id` yazar, `edit_token_expires_at`'i **1 yıl** yapar

Dönüş: `{ ok, reason, slug?, edit_token?, retry_after? }`

| `reason` | Anlamı |
|---|---|
| `RENTED` | başarılı — `slug` ve `edit_token` döner |
| `ALREADY_OWNS_STORE` | zaten vitrini var — mevcut `slug` de döner |
| `ANONYMOUS_SESSION` | kalıcı hesap yok |
| `RATE_LIMITED` | `retry_after` saniye |
| `SOURCE_NOT_FOUND` | şablon artık kiralık değil |
| `SLUG_GENERATION_FAILED` | ad üretilemedi |

**RPC yetkiyi `auth.uid()` üzerinden kuruyor — yönetici anahtarıyla
çağrılamaz.** Bu projede aynı hata dört kez çıktı; beşincisi olmasın.

---

## Yapılacak

### 1. Yeni rota: `POST /api/rent-demo/hesap`

**Örnek alınacak dosya:** `public_web/src/app/api/owner-session/self/route.ts`
— aynı deseni birebir izle (Bearer oku → anon anahtarla kullanıcı istemcisi
kur → RPC çağır). Yeni bir kimlik yöntemi icat etme.

Gövde: `{ slug: string }` (kiralanacak demo şablonun slug'ı).

`reason` → HTTP eşlemesi:

| `reason` | HTTP | Yanıt |
|---|---|---|
| `RENTED` | 200 | `{ tamam: true, slug }` |
| `ALREADY_OWNS_STORE` | 409 | `{ tamam: false, sebep: "ALREADY_OWNS_STORE", slug }` |
| `ANONYMOUS_SESSION` | 401 | `{ hata: "..." }` |
| `RATE_LIMITED` | 429 | `{ hata: "...", retryAfter }` |
| `SOURCE_NOT_FOUND` | 404 | `{ hata: "Bu şablon artık kiralık değil." }` |
| `SLUG_GENERATION_FAILED` | 500 | `{ hata: "Şu anda kiralanamıyor." }` |

**`edit_token` yanıta KONULMAYACAK.** Çerez `/api/owner-session/self`
üzerinden kurulacak; token'ı tarayıcıya taşımak bugüne kadar korunan bir
sınırı deler.

### 2. `public_web/src/app/rent-demo/page.tsx` çatallanır

Bugün tek yol var: reCAPTCHA al → `POST /api/rent-demo`.

Yeni davranış:

1. `supabase.auth.getSession()` ile **kalıcı hesap** var mı bak:
   `user != null && !user.isAnonymous`. Ölçüt `demo_rental_service.dart`
   içindeki `kaliciHesapVar` ile aynı olmalı.
2. **Varsa (hesaplı yol):**
   - `POST /api/rent-demo/hesap`
   - 200 ise → `POST /api/owner-session/self` (mevcut rota; kullanıcının
     artık vitrini var) → dönen `yonlendir` adresine git. Çerez kurulur,
     kullanıcı `/v/<yeni-slug>` sahip modunda açılır.
   - 409 (`ALREADY_OWNS_STORE`) ise → kiralama yapılmaz. "Zaten bir
     vitrinin var" mesajı ve **mevcut vitrine bağlantı** göster
     (`/v/<slug>`). Casper'ın kararı: ikinci vitrin açılmaz, şablon
     değiştirme önerilmez.
   - 429/404/500 → kullanıcıya anlaşılır mesaj, misafir yoluna düşme.
3. **Yoksa (misafir yolu):** bugünkü akış **hiç değişmeden** çalışır —
   reCAPTCHA, `POST /api/rent-demo`, 303 zinciri.

**Misafir yolunu bozma.** Eski Flutter APK'ları `/api/rent-demo` GET'ine
gidip buraya yönleniyor; o zincir kırılırsa yüklü uygulamalarda kiralama
ölür.

### 3. Keşfet kartında beklenti yönetimi

`public_web/src/components/kesfet/VitrinKarti.tsx:80` — "Kirala" düğmesi
aynı adrese gitmeye devam eder. Giriş yapmamış kullanıcıya vitrinin
**geçici** olacağı söylensin (kartta küçük bir alt satır ya da düğme altı
not). Bugün hiç söylenmiyor; kullanıcı 30 saat sonra vitrinini
kaybettiğinde sebebini bilmiyor.

Metin eklerken dikkat: landing/Keşfet metinleri **çift yönlü eşitlik
bekçisine** bağlı. Web'e cümle eklersen ya Flutter'a da ekle ya da
`landingEsitlikIstisnalariWeb.ts` içine gerekçesiyle yaz.

### 4. Bekçi testi: `public_web/tests/rent-demo-hesap-contract.test.ts`

- Hesap rotası **yönetici istemcisi kullanamaz**: kaynak taraması —
  `getSupabaseAdmin` ile `rent_demo_for_account` aynı dosyada geçemez
- Jeton yokken **401** döner ve RPC'ye hiç gidilmez
- Başarılı yanıtın gövdesinde **`edit_token` bulunmaz**

Örnek alınacak testler: `tests/api/yazi-randevu-auth.test.ts` (mock deseni),
`tests/owner-dashboard-store-access-contract.test.ts` (kaynak taraması deseni).

---

## Bitiş şartı

Tek cümle: **giriş yapmış bir kullanıcı Keşfet'ten şablon kiralayınca
vitrin kalıcı olarak hesabına bağlanır.**

Kanıt (Claude canlıda doğrulayacak):
- Yeni hesapla giriş → Keşfet → "Kirala" → vitrin sahip modunda açılır
- Veritabanında: `select slug, user_id is not null, edit_token_expires_at
  from stores where slug = '<yeni-slug>'` → sahipli, bitiş bir yıl sonrası
- Çıkıp tekrar girince vitrin panoda duruyor
- Giriş yapmamış tarayıcıda misafir yolu **hâlâ çalışıyor**

---

## Kapsam dışı — dokunma

- Misafir akışının kendisi (reCAPTCHA, `start_demo_trial`, 303 zinciri)
- Yeni migration — veritabanı tarafı hazır
- Şablon değiştirme / ikinci vitrin
- Faz 6-8 (sayaç, bildirimler, yardım sayfası)

---

## Çalışma kuralları

1. **Klasörde tek ajan.** 26 Ağustos'ta iki ajan birbirinin dosyasını ezdi.
2. **Dalı UZAK main'den aç:**
   ```
   git fetch origin
   git checkout -B faz5/kiralama-hesaba-baglansin origin/main
   git log --oneline origin/main..HEAD   # boş olmalı
   ```
   Yerel `main` başka bir ajanın commit'ini taşıyor olabilir — 27 Ağustos'ta
   iki kez denetlenmemiş kod PR'a bindi.
3. **Kapsamı taşırma.** Faz dışında bir eksik görürsen not düş, yapma.
   27 Ağustos'ta bu yüzden PR'a girmemesi gereken bir dosya derlemeyi kırdı.
4. **Kendi işini kendine denetletme** — `code-review` skill'ini çalıştırma.
   O skill iki alt ajan başlatıp tüm değişikliği baştan okuyor ve kotanı
   yakıyor. Denetim Claude'da, üstelik canlıda gerçek hesapla yapılıyor.
5. **Uzun rapor yazma.** Bitince dal adını söyle, yeter.
6. **Sahip sayfalarında elle renk yazma** — `owner-shell` + `--owner-*`
   tanımları; bekçi testi kırar.
7. Doğrulama:
   ```
   cd public_web && npm run lint && npm test && npm run build
   ```
   GitHub test kotası 1 Eylül'e kadar dolu, hepsi yerelde koşulacak.
8. PR sınırı 12 dosya / 600 satır. Bu iş çok altında kalmalı.
9. **Main'e indirme Claude'da.** PR açma, merge etme — dalı hazırla, haber ver.
