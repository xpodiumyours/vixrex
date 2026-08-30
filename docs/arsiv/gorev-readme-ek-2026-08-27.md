# VIXREX'E ÖZEL EKLER — README güncelleme görevine

Bu blok, README görev tanımının **sonuna** eklenir. Genel kuralları tekrar
etmez; yalnız bu depoya özel, koddan doğrulanmış gerçekleri ve tuzakları
sayar. Hepsi 27 Ağustos 2026'da doğrulandı.

---

## A. README 21 Ağustos'tan beri güncellenmedi — o tarihten sonra ne değişti

Aşağıdakiler main'de ve canlıda. README hiçbirini anlatmıyor. Kodda
doğrulayıp README'ye ekle.

**1. Next.js artık platformun ana kapısı (#344/#345/#346, PR #351).**
- Kök artık gerçek bir sayfa. Eskiden `/` uygulamaya yönlendiriyordu; hem
  `src/app/page.tsx` hem `next.config.ts` içindeki iki yönlendirme de silindi.
- `src/app/(site)/` route grubu: ana sayfa, ortak başlık/altbilgi.
  Kök layout'a KONMADI — o layout `/v/[slug]` vitrinlerini de sarıyor.
- `/kesfet` dizini + 19 kanonik kategori sayfası
  (`/kesfet/[kategori]`, adresler tireli: `kafe-lokanta`).
- Site haritası demo vitrinleri hariç tutuyor; demo vitrinler `noindex`.
- `src/app/opengraph-image.tsx`, Organization/WebSite JSON-LD.
- Flutter yüzeyi (`vixrex-app`) artık `X-Robots-Tag: noindex` ile aramadan çıktı.

**2. Kalıcı hesap sahipliği — VIXREX CORE (PR #352).**
- Migration `20260826000000_vixrex_core_kalici_hesap_sahipligi.sql`, **canlıda**.
- `stores_tek_vitrin_per_user` kısmi unique index: **hesap başına tek vitrin**.
- `bootstrap_owner_state()` yeni cihazda açılışın tek kaynağı.
- `rent_demo_for_account()` demo vitrini kalıcı hesaba kiralar; klon sahipli
  doğar, token bir yıllık.
- Yeni katman: `lib/repositories/vitrin_sahiplik_repository.dart`.
- **Ölçüm:** bu iş öncesinde canlıda 29 vitrin vardı, `user_id` dolu olan 0.

**3. Ana sayfa uygulamanın açılış ekranıyla eşitlendi (PR #353).**
- Hero arka plan parıltısı, dolu telefon mockup'ı, uçuşan etiketler,
  maskot sohbet maketi, ayrık form öneki.
- Flutter ↔ web metin eşitliği bir testle bekçilenmiş durumda:
  `public_web/tests/landing-esitlik-contract.test.ts`. **Bugün tek yönlü** —
  Flutter asıl, web ondan eşitleniyor.

---

## B. Bu depoda PR'ı gerçekten durduran kapılar

Yeni ajan mimariyi bilmediği için değil, **bunları bilmediği için** duvara
tosluyor. README'nin "Tests & Quality Gates" bölümünde açıkça yazılmalı.

| Kapı | Ne yapar | Nerede |
|---|---|---|
| Kapsam kontrolü | 12 dosya / 600 satırı aşan PR, açıklamada `Kapsam-Onay:` satırı yoksa CI'yı kırar | `.github/scripts/verify_pr_scope.py` |
| Supabase erişim bekçisi | `lib/repositories/` dışında `Supabase.instance` kullanan dosya sayısını dondurur (şu an 22) | `.github/scripts/verify_supabase_erisim_ratchet.py` |
| Biçim kapısı | `dart format --output=none --set-exit-if-changed lib test` | `ci.yml` |
| Şema üretim hattı | `shared/*.json` → üretici → `.g.dart` tazeliğini `git diff --exit-code` ile kanıtlar | `ci.yml` |
| E2E | **Yalnız main'e push'ta koşar**, PR'da atlanır | `ci.yml` |

**Görsel regresyon temelleri işletim sistemine bağlı:**
`*-chromium-linux.png` ve `*-chromium-win32.png` ayrı tutuluyor. CI Linux'ta
koşuyor; Windows'ta üretilen temel CI'yı yeşile çevirmez. Linux temeli
Docker'daki Playwright kabıyla üretilir. Testler canlı siteye bakar
(`E2E_PUBLIC_BASE_URL` yoksa `vixrex-public.vercel.app`), yani temel
üretmeden önce Vercel dağıtımı bitmeli.

---

## C. Kuralları KOPYALAMA — yönlendir

README şu an `VIXREX_RULES.md`'deki iki değişmez kuralı kendi içinde tekrar
ediyor. **Üçüncü kopyayı üretme.** Kural metinlerini README'ye taşımak yerine
tek satırla özetle ve kaynağa yönlendir.

Kaynak dosyalar ve görevleri:

- `VIXREX_RULES.md` — değişmez mimari kurallar, kanıt seviyeleri (§5),
  yetki sınırları, kontrol kapıları. **Kural kaynağı budur.**
- `AGENTS.md` — ajan çalışma akışı.
- `CONTEXT.md` — ürün hedefi ve güncel durum notları.
- `README.md` — mimari rehber ve kurulum. Kural üretmez, kurala yönlendirir.

**Dün eklenen kural** (`VIXREX_RULES.md` §1), README'de bir satırla anılmalı:
landing'deki asistan sohbeti bir **makettir**, motora bağlanmaz; web'de gerçek
asistan yalnız sahip panelindedir (`/v/:slug` → `OwnerAssistantPanel`).
Gerekçesi ölçüm: iki yüzeyde toplam **9 ayrı "Vixrex Asistan" parçası** var
(Flutter'da 6, web'de 3).

---

## D. Mimari borç bölümüne yazılabilecek, ölçülmüş gerçekler

Yalnız bunları yaz; issue listesine çevirme.

- **Fiyat tek kaynakta değil:** "299 TL" on ayrı dosyada elle yazılı
  (Flutter'da 2, web'de 6, ödeme kodunda kuruş sabiti). Değiştirmek gerekirse
  hepsini tek tek bulmak gerekiyor.
- **Renkler elle kopyalanmış:** Flutter `lib/theme/app_colors.dart` 38 renk
  tanımlıyor; `public_web/src/app/globals.css` bunların 14'ünü `--color-lp-*`
  adıyla elle taşımış. Değerler bugün tutuyor ama hiçbir test bağlamıyor.
- **Eşitlik testi tek yönlü:** web geride kalırsa yakalıyor, APK geride
  kalırsa yakalamıyor.
- **Keşfet sayfasının uygulamayla eşitliğine hiç bakılmadı.**

Karşılaştırma için: kategoriler bu sorunu **çözmüş** durumda —
`shared/business_categories.json` tek kaynak, Flutter kodu ondan üretiliyor,
CI tazeliği kanıtlıyor. README'de bu desen örnek olarak gösterilmeli.

---

## E. Doğrulama kısayolları

Bir iddiayı README'ye yazmadan önce hızlı kontrol:

```
grep -rn "299" --include=*.dart --include=*.tsx --include=*.ts lib/ public_web/src/
python .github/scripts/verify_supabase_erisim_ratchet.py
cd public_web && npm run lint && npm test && npm run build
flutter analyze lib/ && flutter test
```

Kurulum komutlarını `public_web/package.json` ve `pubspec.yaml` içinden al,
README'deki eski hâlinden değil.
